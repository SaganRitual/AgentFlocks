//
// Created by Rob Bishop on 1/26/18
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

import SpriteKit

func Nickname(_ node: SKNode) -> String  {
    if let name = node.name {
        return Nickname(name)
    } else {
        return "<no name>"
    }
}

func Nickname(_ name: String) -> String {
    let indexStartOfText = name.index(name.startIndex, offsetBy: 0)
    let indexEndOfText = name.index(name.startIndex, offsetBy: 4)
    return String(name[indexStartOfText ..< indexEndOfText])
}

class AFCoreData {
    struct Core {
        var agentGoalsDelegate: AFAgentGoalsDelegate!
        var browserDelegate: AFBrowserDelegate!
        var contextMenuDelegate: AFContextMenuDelegate!
        var sceneInput: AFSceneInput!
        var sceneUI: AFSceneController!
        var itemEditorDelegate: AFItemEditorDelegate!
        var menuBarDelegate: AFMenuBarDelegate!
        var topBarDelegate: AFTopBarDelegate!
        var ui: AppDelegate!
        
        init() {}
    }

    var core = Core()

    enum EditorType { case loadFromCoreData, createFromScratch }
    
    enum NotificationType: String { case AppCoreReady = "AppCoreReady", DeletedAgent = "DeletedAgent",
        DeletedBehavior = "DeletedBehavior", DeletedGoal = "DeletedGoal",
        DeletedGraphNode = "DeletedGraphNode", DeletedPath = "DeletedPath", GameSceneReady = "GameSceneReady",
        NewAgent = "NewAgent", NewBehavior = "NewBehavior", NewGoal = "NewGoal",
        NewGraphNode = "NewGraphNode", NewPath = "NewPath", SetAttribute = "SetAttribute" }

    let agentsPath: [JSONSubscriptType] = ["agents"]
    let pathsPath: [JSONSubscriptType] = ["paths"]
    
    var data: JSON = [ "agents": [], "paths": [] ]
    var notifier = NotificationCenter()
    
    init() {
    }

//    fileprivate func announceNewGraphNode(graphNodeName: String) { announce(event: .NewGraphNode, subjectName: graphNodeName) }
//    fileprivate func announceNewPath(pathName: String) { announce(event: .NewPath, subjectName: pathName) }
//    fileprivate func setAttribute(attributeName: String) { announce(event: .SetAttribute, subjectName: attributeName) }

    func announce(event: NotificationType, subjectName: String) {
        let n = Notification.Name(rawValue: event.rawValue)
        let nn = Notification(name: n, object: subjectName, userInfo: nil)
        notifier.post(nn)
    }
    
    private func announceCoreReady() {
        let u: [String : Any] = [
            "AFCoreData" : self, "UINotifications" : self.core.sceneUI.notificationsSender,
            "DataNotifications" : notifier
        ]
        
        let n = Notification.Name(rawValue: NotificationType.AppCoreReady.rawValue)
        let nn = Notification(name: n, object: self, userInfo: u)
        
        // Note that we post the core ready message to the default notification
        // center, not our app-specific one.
        NotificationCenter.default.post(nn)
    }

    func announceNewAgent(agentName: String) { announce(event: .NewAgent, subjectName: agentName) }

    func createAgent(editorType: EditorType) -> AFAgentEditor {
        switch editorType {
        case .createFromScratch:
            let nextSlot: JSONSubscriptType = data[agentsPath].count
        
            let newAgentNode: JSON = [:]
            data[agentsPath].arrayObject!.append(newAgentNode)

            let editor = AFAgentEditor(coreData: self, fullPath: agentsPath + [nextSlot])
        
            editor.name = NSUUID().uuidString
            data[agentsPath + [nextSlot]]["name"] = JSON(editor.name)
            
            announceNewAgent(agentName: editor.name)

            return editor
            
        default:
            fatalError()
        }
    }
    
    func dump() -> String {
        if let rs = data.rawString(.utf8, options: .sortedKeys) { print(rs); return rs }
        else { print("no string?"); return "no string?" }
    }
    
    static func makeCore(ui: AppDelegate, gameScene: GameScene) -> AFGameSceneDelegate {
        var coreData = AFCoreData()

        coreData.core.sceneUI = AFSceneController(gameScene: gameScene, ui: coreData.core.ui, contextMenu: AFContextMenu(ui: coreData.core.ui))
        
        coreData.core.agentGoalsDelegate = AFAgentGoalsDelegate(coreData: coreData, sceneUI: coreData.core.sceneUI)
        coreData.core.browserDelegate = AFBrowserDelegate(coreData.core.sceneUI)
        coreData.core.contextMenuDelegate = AFContextMenuDelegate(sceneUI: coreData.core.sceneUI)
        coreData.core.itemEditorDelegate = AFItemEditorDelegate(coreData: coreData, sceneUI: coreData.core.sceneUI)
        coreData.core.menuBarDelegate = AFMenuBarDelegate(coreData: coreData, sceneUI: coreData.core.sceneUI)
        
        coreData.core.sceneInput = AFSceneInput(coreData: coreData, gameScene: gameScene)
        coreData.core.sceneInput.delegate = coreData.core.sceneUI
        
        coreData.core.topBarDelegate = AFTopBarDelegate(coreData: coreData, sceneUI: coreData.core.sceneUI)
        
        // Here, "ui" just means the AppDelegate
        coreData.core.ui = ui
        ui.coreAgentGoalsDelegate = coreData.core.agentGoalsDelegate
        ui.coreBrowserDelegate = coreData.core.browserDelegate
        ui.coreContextMenuDelegate = coreData.core.contextMenuDelegate
        ui.coreItemEditorDelegate = coreData.core.itemEditorDelegate
        ui.coreMenuBarDelegate = coreData.core.menuBarDelegate
        ui.coreTopBarDelegate = coreData.core.topBarDelegate
        
        coreData.announceCoreReady()
        
        // We don't add this one to AppDelegate, because it's owned by
        // GameScene. We return it so AppDelegate can plug it into
        // GameScene.
        return coreData.core.sceneInput
    }
}

