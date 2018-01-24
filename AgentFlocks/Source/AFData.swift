//
// Created by Rob Bishop on 1/16/18
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

import AppKit

protocol AFDataModelDelegate {
    func newAgent(_ name: String)
    func newBehavior(_ name: String, for agent: String)
    func newGoal(_ name: String, parentBehavior: String, for agent: String)
    func setAttribute(_ attribute: Int, to value: Float, for agent: String)
}

class AFDataModel {
    let notifications: NotificationCenter
    
    private var agents = [String : AFAgentData]()
    private var delegate: AFDataModelDelegate?
    private var paths = [String : AFPathData]()
    
    enum NotificationType: String { case CoreReady = "CoreReady", DeletedAgent = "DeletedAgent",
        DeletedBehavior = "DeletedBehavior", DeletedGoal = "DeletedGoal",
        DeletedGraphNode = "DeletedGraphNode", DeletedPath = "DeletedPath", GameSceneReady = "GameSceneReady",
        NewAgent = "NewAgent", NewBehavior = "NewBehavior", NewGoal = "NewGoal",
        NewGraphNode = "NewGraphNode", NewPath = "NewPath", SetAttribute = "SetAttribute" }
    
    init() {
        notifications = NotificationCenter()
    }

    func cloneAgent(_ name: String) {
        let copyFrom = agents[name]!
        let agent = AFAgentData(copyFrom: copyFrom)
        announceNewAgent(agent.name)
    }
    
    func deleteItem(_ name: String) {
        if agents.removeValue(forKey: name) != nil {
            announceDeletedAgent(name)
            return
        }
        
        if paths.removeValue(forKey: name) != nil {
            announceDeletedPath(name)
            return
        }
        
        // Check all the behaviors and goals in every agent
        for (agentName, pair) in agents {
            let composite = pair.compositeBehaviorData
            if composite.behaviors.removeValue(forKey: name) != nil {
                announceDeletedBehavior(name, agent: agentName)
                return
            } else {
                for (_, pair) in composite.behaviors {
                    let behavior = pair.behaviorData
                    if behavior.goals.removeValue(forKey: name) != nil {
                        announceDeletedGoal(name, parentBehavior: behavior.name, agent: agentName)
                        return
                    }
                }
            }
        }
        
        // Check all the graph nodes in every path
        for (pathName, pair) in paths {
            if pair.graphNodes.remove(name) != nil {
                announceDeletedGraphNode(name, path: pathName)
                return
            }
        }
        
        fatalError("Trying to delete unknown item \(name)")
    }
    
    func getAgent(_ name: String) -> AFAgentData { return agents[name]! }
    
    func getBehavior(_ name: String, from agent: String) -> (AFBehaviorData, Float) {
        let agentData = agents[agent]!
        return agentData.compositeBehaviorData.behaviors[name]!
    }
    
    func getChildCount(for name: String) -> Int {
        if agents[name] != nil { return 0 }
        if paths[name] != nil { return 0 }
        
        // Check all the behaviors and goals in every agent
        for (_, pair) in agents {
            let composite = pair.compositeBehaviorData
            if let behavior = composite.behaviors[name] {
                return behavior.behaviorData.goals.count
            } else {
                for (_, pair) in composite.behaviors {
                    let behavior = pair.behaviorData
                    if behavior.goals[name] != nil {
                        return 0    // Goals don't have children
                    }
                }
            }
        }
        
        // Check all the graph nodes in every path
        for (_, pair) in paths { if pair.graphNodes[name] != nil { return 0 } }
        
        fatalError("Trying to query unknown item \(name)")
    }
    
    func getChildrenOf(_ name: String) -> [String]? {
        if let agent = agents[name] { return Array(agent.compositeBehaviorData.behaviors.keys) }
        if let path = paths[name] { return Array(path.graphNodes.keys) }
        
        // Check all the behaviors and goals in every agent
        for (_, pair) in agents {
            let composite = pair.compositeBehaviorData
            if let behavior = composite.behaviors[name] {
                return Array(behavior.behaviorData.goals.keys)
            } else {
                for (_, pair) in composite.behaviors {
                    let behavior = pair.behaviorData
                    if behavior.goals[name] != nil {
                        return nil    // Goals don't have children
                    }
                }
            }
        }
        
        // Check all the graph nodes in every path
        for (_, pair) in paths { if pair.graphNodes[name] != nil { return nil } }
        
        fatalError("Trying to query unknown item \(name)")
    }
    
    func getGoal(_ name: String, parentBehavior: String, agent agentName: String) -> (AFGoalData, Float) {
        let agent = agents[agentName]!
        let composite = agent.compositeBehaviorData
        let (behavior, _) = composite.behaviors[parentBehavior]!
        return behavior.goals[name]!
    }
    
    func getGraphNode(_ name: String, parentPath: String) -> AFGraphNodeData {
        let pathData = paths[parentPath]!
        return pathData.graphNodes[name]!
    }
    
    func getIsItemEnabled(_ name: String) -> Bool {
        // Check all the behaviors and goals in every agent
        for (_, pair) in agents {
            let composite = pair.compositeBehaviorData
            if let behavior = composite.behaviors[name] {
                return behavior.behaviorData.isEnabled
            } else {
                for (_, pair) in composite.behaviors {
                    let behavior = pair.behaviorData
                    if let goal = behavior.goals[name] {
                        return goal.goalData.isEnabled
                    }
                }
            }
        }
        
        fatalError("Trying to get weight of unknown item \(name)")
    }

    func getItemWeight(_ name: String) -> Float {
        // Check all the behaviors and goals in every agent
        for (_, pair) in agents {
            let composite = pair.compositeBehaviorData
            if let behavior = composite.behaviors[name] {
                return behavior.weight
            } else {
                for (_, pair) in composite.behaviors {
                    let behavior = pair.behaviorData
                    if let goal = behavior.goals[name] {
                        return goal.weight
                    }
                }
            }
        }
        
        fatalError("Trying to get weight of unknown item \(name)")
    }
    
    func getPath(_ name: String) -> AFPathData {
        return paths[name]!
    }
    
    func newAgent() {
        let agent = AFAgentData();
        agents[agent.name] = agent

        announceNewAgent(agent.name)
    }
    
    private func newBehavior_(for agent: String, weight: Float) -> String {
        let agentData = agents[agent]!
        let composite = agentData.compositeBehaviorData
        let name = composite.newBehavior(weight: weight)
        return name
    }
    
    func newBehavior(for agent: String, weight: Float) {
        let name = newBehavior_(for: agent, weight: weight)
        announceNewBehavior(name, agent: agent)
    }
    
    func newGoal(_ type: AFGoalType, for agent: String, time: TimeInterval, weight: Float,
                 angle: Float, distance: Float, speed: Float, forward: Bool) {
        newGoal(type, for: agent, parentBehavior: nil, weight: weight, targets: nil, angle: angle,
                distance: distance, speed: speed, time: time, forward: forward)
    }

    func newGoal(_ type: AFGoalType, for agent: String, parentBehavior: String?, weight: Float,
                 targets: [String]? = nil, angle: Float? = nil, distance: Float? = nil,
                 speed: Float? = nil, time: TimeInterval? = nil, forward: Bool? = nil) {
        
        var parentName = String()
        if let p = parentBehavior { parentName = p }
        else { parentName = newBehavior_(for: agent, weight: weight); announceNewBehavior(parentName, agent: agent) }
        
        let behavior = getBehavior(parentBehavior!, from: agent).0
        let newGoalName = behavior.newGoal(type, for: agent, parentBehavior: parentName, weight: weight,
                                           targets: targets, angle: angle, distance: distance, speed: speed,
                                           time: time, forward: forward)
        
        announceNewGoal(newGoalName, parentBehavior: parentName, agent: agent)
    }
    
    func newGoal(_ type: AFGoalType, for agents: [String], parentBehavior: String? = nil, weight: Float,
                 targets: [String]? = nil, angle: Float? = nil, distance: Float? = nil,
                 speed: Float? = nil, time: TimeInterval? = nil, forward: Bool? = nil) {
        
        agents.forEach {
            newGoal(type, for: $0, parentBehavior: parentBehavior, weight: weight, targets: targets,
                    angle: angle, distance: distance, speed: speed, time: time, forward: forward)
        }
    }
    
    func newGraphNode(for path: String) {
        let pathData = paths[path]!
        let node = AFGraphNodeData(familyName: path)
        pathData.graphNodes.append(key: node.name, value: node)
        
        announceNewGraphNode(node.name, path: path)
    }
    
    func newPath() {
        let path = AFPathData()
        paths[path.name] = path

        announceNewPath(path.name)
    }
    
    func setAttribute(_ attribute: AFAgentAttribute, to value: Float, for agent: String) {
        agents[agent]!.attributes[attribute] = value
        
        let n = Notification.Name(rawValue: NotificationType.SetAttribute.rawValue)
        let nn = Notification(name: n, object: (attribute, value, agent), userInfo: nil)
        notifications.post(nn)
    }
}

// MARK - Announcement functions

extension AFDataModel {
    
    func announceCoreReady() {
        let u: [String : Any] = [
            "AFDataModel" : self, "UINotifications" : AFCore.sceneUI.notificationsSender,
            "DataNotifications" : notifications
        ]
        
        let n = Notification.Name(rawValue: NotificationType.CoreReady.rawValue)
        let nn = Notification(name: n, object: self, userInfo: u)

        // Note that we post the core ready message to the default notification
        // center, not our app-specific one.
        NotificationCenter.default.post(nn)
    }
    
    func announceDeletedAgent(_ agent: String) {
        let n = Notification.Name(rawValue: NotificationType.DeletedAgent.rawValue)
        let nn = Notification(name: n, object: agent, userInfo: nil)
        notifications.post(nn)
    }
    
    func announceDeletedBehavior(_ behavior: String, agent: String) {
        let n = Notification.Name(rawValue: NotificationType.DeletedBehavior.rawValue)
        let p = (behavior: behavior, agent: agent)
        let nn = Notification(name: n, object: p, userInfo: nil)
        notifications.post(nn)
    }
    
    func announceDeletedGoal(_ goal: String, parentBehavior: String, agent: String) {
        let n = Notification.Name(rawValue: NotificationType.DeletedGoal.rawValue)
        let nn = Notification(name: n, object: (goal, parentBehavior, agent), userInfo: nil)
        notifications.post(nn)
    }
    
    func announceDeletedGraphNode(_ nodeName: String, path: String) {
        let n = Notification.Name(rawValue: NotificationType.DeletedGraphNode.rawValue)
        let nn = Notification(name: n, object: (nodeName, path), userInfo: nil)
        notifications.post(nn)
    }
    
    func announceDeletedPath(_ path: String) {
        let n = Notification.Name(rawValue: NotificationType.DeletedPath.rawValue)
        let nn = Notification(name: n, object: path, userInfo: nil)
        notifications.post(nn)
    }
    
    func announceNewAgent(_ agent: String) {
        let n = Notification.Name(rawValue: NotificationType.NewAgent.rawValue)
        let nn = Notification(name: n, object: agent, userInfo: nil)
        notifications.post(nn)
    }
    
    func announceNewBehavior(_ behavior: String, agent: String) {
        let n = Notification.Name(rawValue: NotificationType.NewBehavior.rawValue)
        let p = (behavior: behavior, agent: agent)
        let nn = Notification(name: n, object: p, userInfo: nil)
        notifications.post(nn)
    }
    
    func announceNewGoal(_ goal: String, parentBehavior: String, agent: String) {
        let n = Notification.Name(rawValue: NotificationType.NewGoal.rawValue)
        let nn = Notification(name: n, object: (goal, parentBehavior, agent), userInfo: nil)
        notifications.post(nn)
    }
    
    func announceNewGraphNode(_ nodeName: String, path: String) {
        let n = Notification.Name(rawValue: NotificationType.NewGraphNode.rawValue)
        let nn = Notification(name: n, object: (nodeName, path), userInfo: nil)
        notifications.post(nn)
    }
    
    func announceNewPath(_ path: String) {
        let n = Notification.Name(rawValue: NotificationType.NewPath.rawValue)
        let nn = Notification(name: n, object: path, userInfo: nil)
        notifications.post(nn)
    }
}

class AFAgentData {
    var attributes = [AFAgentAttribute : Float]()
    let compositeBehaviorData: AFCompositeBehaviorData
    let name: String
    let scale: Float
    
    init() {
        self.name = NSUUID().uuidString
        self.compositeBehaviorData = AFCompositeBehaviorData(familyName: self.name)
        self.scale = 1
    }
    
    init(copyFrom: AFAgentData) {
        self.name = NSUUID().uuidString // Always, a unique name, even when copying
        self.compositeBehaviorData = AFCompositeBehaviorData(copyFrom: copyFrom.compositeBehaviorData)
        self.scale = copyFrom.scale
    }
}

class AFBehaviorData {
    let familyName: String
    var goals = [String : (goalData: AFGoalData, weight: Float)]()
    var isEnabled = true
    let name: String
    
    init(familyName: String) {
        self.name = NSUUID().uuidString
        self.familyName = familyName
    }
    
    init(copyFrom: AFBehaviorData) {
        self.name = NSUUID().uuidString // Always, a unique name, even when copying
        self.familyName = copyFrom.familyName
        
        copyFrom.goals.forEach {
            let newGoal = AFGoalData(copyFrom: $0.value.goalData)
            self.goals[newGoal.name] = (newGoal, $0.value.weight)
        }
    }
    
    func newGoal(_ type: AFGoalType, for agent: String, parentBehavior: String, weight: Float, targets: [String]? = nil,
                 angle: Float?, distance: Float?, speed: Float?, time: TimeInterval?, forward: Bool?) -> String {
        
        let newGoal = AFGoalData(type, for: agent, parentBehavior: parentBehavior, targets: targets,
                                 angle: angle, distance: distance, speed: speed,
                                 time: time, forward: forward)
        
        self.goals[newGoal.name] = (newGoal, weight)
        
        return newGoal.name
    }
}

class AFCompositeBehaviorData {
    var behaviors = [String : (behaviorData: AFBehaviorData, weight: Float)]()
    let familyName: String
    var isEnabled = true
    let name: String
    
    init(familyName: String) {
        self.name = NSUUID().uuidString
        self.familyName = familyName
    }
    
    init(copyFrom: AFCompositeBehaviorData) {
        self.name = NSUUID().uuidString // Always, a unique name, even when copying
        self.familyName = copyFrom.familyName
        
        copyFrom.behaviors.forEach {
            let newBehavior = AFBehaviorData(copyFrom: $0.value.behaviorData)
            self.behaviors[newBehavior.name] = (newBehavior, $0.value.weight)
        }
    }
    
    func newBehavior(weight: Float) -> String {
        let newBehavior = AFBehaviorData(familyName: self.familyName)
        behaviors[newBehavior.name] = (newBehavior, weight)
        return newBehavior.name
    }
}

class AFGoalData {
    let agents: [String]?
    let angle: Float?
    let distance: Float?
    let familyName: String
    let forward: Bool?
    let goalType: AFGoalType
    var isEnabled = true
    let name: String
    let parentBehavior: String
    let speed: Float?
    let targets: [String]?
    let time: TimeInterval?
    let weight: Float?
    
    init(copyFrom: AFGoalData) {
        self.agents = copyFrom.agents
        self.angle = copyFrom.angle
        self.distance = copyFrom.distance
        self.familyName = copyFrom.familyName
        self.forward = copyFrom.forward
        self.goalType = copyFrom.goalType
        self.name = NSUUID().uuidString // Always, a unique name, even when copying
        self.parentBehavior = copyFrom.parentBehavior
        self.speed = copyFrom.speed
        self.targets = copyFrom.targets
        self.time = copyFrom.time
        self.weight = copyFrom.weight
    }
    
    init(_ goalType: AFGoalType, for agent: String, parentBehavior: String, targets: [String]? = nil,
         angle: Float? = nil, distance: Float? = nil, speed: Float? = nil, time: TimeInterval? = nil, forward: Bool? = nil) {
        
        self.agents = [agent]
        self.angle = angle
        self.distance = distance
        self.familyName = agent
        self.forward = forward
        self.goalType = goalType
        self.name = NSUUID().uuidString
        self.parentBehavior = parentBehavior
        self.speed = speed
        self.targets = targets
        self.time = time
        self.weight = nil
    }
}

class AFGraphNodeData: Equatable {
    let familyName: String
    let name: String
    
    init(familyName: String) {
        self.name = NSUUID().uuidString
        self.familyName = familyName
    }

    static func ==(lhs: AFGraphNodeData, rhs: AFGraphNodeData) -> Bool {
        return lhs.name == rhs.name
    }
}

class AFPathData {
    var graphNodes = AFOrderedMap<String, AFGraphNodeData>()
    let name: String
    
    init() {
        self.name = NSUUID().uuidString
    }
}

