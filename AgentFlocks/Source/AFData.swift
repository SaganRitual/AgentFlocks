//
// Created by Rob Bishop on 2/6/18
//
// Copyright © 2018 Rob Bishop
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//

import Foundation

class NodeWriterDeferrer {
    var nodeWriter: NodeWriter!
}

class NodeWriter {
    private let bigData: AFData
    private var key: JSONSubscriptType?
    private let pathToParent: [JSONSubscriptType]
    private var notificationsSet = [[JSONSubscriptType]]()
    private var writeMode = Foundation.Notification.Name.CoreNodeUpdate
    private var suppressNotifications_: Bool?

    init(_ pathToParent: [JSONSubscriptType], core: AFCore) {
        self.bigData = core.bigData
        self.pathToParent = pathToParent
    }
    
    deinit {
        guard suppressNotifications_ == nil else { return }
        
        if let key = key {    // That is, if we actually wrote something
            let path = pathToParent + [key]
            let p: AFNotificationPacket = (writeMode == .CoreNodeAdd) ? .CoreNodeAdd(path) : .CoreNodeUpdate(path)
            let q = AFNotificationPacket.pack(p)
            let n = Foundation.Notification(name: writeMode, object: nil, userInfo: q)
            bigData.notifier.post(n)
        }
    }
}

// MARK: Public interface

extension NodeWriter {
    // Making it really stand out when we need to suppress notifications, so I don't
    // overlook it while chasing down bugs.
    func suppressNotifications() -> NodeWriter {
        guard suppressNotifications_ == nil else { fatalError("Reentering suppressNotifications") }
        suppressNotifications_ = true
        return self
    }
    
    func write(this value: JSON, to key: JSONSubscriptType) {
        if !bigData.data[pathToParent][key].exists() { self.writeMode = .CoreNodeAdd }
        
        self.key = key  // Remember that we wrote something so we'll announce to listeners
        bigData.data[pathToParent][key] = value
    }
    
    // Non-functional ugliness. I'm ashamed to have written it. But
    // it makes the JSON more readable.
    func write(this value: JSON, to key: JSONSubscriptType, under: JSONSubscriptType) {
        bigData.data[pathToParent][key][under] = value
    }
}

class AFData {
    var core: AFCore!
    var data: JSON = [ "agents": [:], "paths": [:] ]

    var notifier = Foundation.NotificationCenter()
    
    init() {  }

    func dump() -> String {
        if let rs = data.rawString(.utf8, options: .sortedKeys) { return rs }
        else { return "no string?" }
    }
    
    func getChildCount(for nodeName: String) -> Int {
        if let path = core.getPathTo(nodeName) { return data[path].count }
        else { fatalError() }
    }
    
    func getChildren(of nodeName: String) -> [JSON]? {
        if let path = core.getPathTo(nodeName) { return data[path].arrayObject as? [JSON] }
        else { return nil }
    }
    
    // Here, nodeName will be "behaviors" or "goals". We need to figure
    // out the full path to those containers. Will have to come back to this
    // to get goals working. Right now just trying to get past the smoke test.
    func getChildren(of nodeName: String, under agent: String) -> [JSON]? {
        if let path = core.getPathTo(nodeName, pathSoFar: ["agents", agent]) {
            return data[path][nodeName].arrayObject as? [JSON]
        }
        
        return nil
    }
    
    func getNodeWriter(_ pathToParent: [JSONSubscriptType]) -> NodeWriter {
        return NodeWriter(pathToParent, core: core)
    }
}

extension Foundation.Notification.Name {
    static let CoreNodeAdd = Foundation.Notification.Name("CoreNodeAdd")
    static let CoreNodeDelete = Foundation.Notification.Name("CoreNodeDelete")
    static let CoreNodeUpdate = Foundation.Notification.Name("CoreNodeUpdate")
    static let ScenoidDeselected = Foundation.Notification.Name("ScenoidDeselected")
    static let GoalsControlPanelActivate = Foundation.Notification.Name("GoalsControlPanelActivate")
    static let GoalsControlPanelApply = Foundation.Notification.Name("GoalsControlPanelApply")
    static let GoalsControlPanelCancel = Foundation.Notification.Name("GoalsControlPanelCancel")
    static let GoalsControlPanelDeactivate = Foundation.Notification.Name("GoalsControlPanelDeactivate")
    static let ScenoidSelected = Foundation.Notification.Name("ScenoidSelected")
}

enum AFNotificationPacket {
    case CoreNodeAdd([JSONSubscriptType])
    case CoreNodeDelete([JSONSubscriptType])
    case CoreNodeUpdate([JSONSubscriptType])
    case ScenoidSelected(String, Bool)
    case GoalsControlPanelActivate(ItemEditorController)
    case GoalsControlPanelApply(ItemEditorController)
    case GoalsControlPanelCancel(ItemEditorController)
    case GoalsControlPanelDeactivate(ItemEditorController)
    case ScenoidDeselected(String)
    
    private static let packetName = "NotificationPacket"
    
    static func unpack(_ bigNotification: Foundation.Notification) -> AFNotificationPacket {
        return bigNotification.userInfo![packetName]! as! AFNotificationPacket
    }
    
    static func pack(_ afNotification: AFNotificationPacket) -> [String: Any] {
        return [packetName: afNotification]
    }
}

extension AFData {
    // Some helpers for fishing around notification paths
    private static let agentDepth = 1
    private static let behaviorDepth = 3
    private static let goalDepth = 5
    
    static func getAgent(_ path: [JSONSubscriptType]) -> JSONSubscriptType { return path[AFData.agentDepth] }
    static func getBehavior(_ path: [JSONSubscriptType]) -> JSONSubscriptType { return path[AFData.behaviorDepth] }
    static func getGoal(_ path: [JSONSubscriptType]) -> JSONSubscriptType { return path[AFData.goalDepth] }

    static func getPathToParent(_ pathToHere: [JSONSubscriptType]) -> [JSONSubscriptType] {
        let ixHere = pathToHere.count - 1
        return Array(pathToHere.prefix(ixHere))
    }
    
    static func getPathToContainingBehavior(_ pathToGoal: [JSONSubscriptType]) -> [JSONSubscriptType] {
        var theBehavior: JSONSubscriptType?
        var shrinkingPath = pathToGoal
        
        while shrinkingPath.count > 0 {
            let temp: JSONSubscriptType = shrinkingPath.last!
            if JSON(temp) == JSON("behaviors") { break }
            
            shrinkingPath = Array(shrinkingPath.prefix(shrinkingPath.count - 1))
            
            theBehavior = temp
        }
        
        return shrinkingPath + [theBehavior!]
    }
    
    static func getContainingBehaviorName(pathToGoal: [JSONSubscriptType]) -> JSONSubscriptType {
        let pathToBehavior = getPathToContainingBehavior(pathToGoal)
        return pathToBehavior.last!
    }

    static func isAgent(_ path: [JSONSubscriptType]) -> Bool { return path.count == agentDepth + 1 }
    static func isBehavior(_ path: [JSONSubscriptType]) -> Bool { return path.count == behaviorDepth + 1 }
    static func isGoal(_ path: [JSONSubscriptType]) -> Bool { return path.count == goalDepth + 1 }
    static func isMotivator(_ path: [JSONSubscriptType]) -> Bool { return isBehavior(path) || isGoal(path) }
}

