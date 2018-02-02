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

func Nickname(_ name: String?) -> String {
    guard let name = name else { return "<no name>" }
    
    let indexStartOfText = name.index(name.startIndex, offsetBy: 0)
    let indexEndOfText = name.index(name.startIndex, offsetBy: 4)
    return String(name[indexStartOfText ..< indexEndOfText])
}

struct AFNotification {
    struct Encode {
        let isPrimary: Bool
        let name: String
        
        init(_ name: String, isPrimary: Bool = false) {
            self.isPrimary = isPrimary
            self.name = name
        }
        
        func encode() -> [String : Any] {
            return ["isPrimary" : self.isPrimary, "name" : self.name]
        }
    }
    
    struct Decode {
        let macNotification: Notification
        var isPrimary: Bool? { return getField("isPrimary") as? Bool }
        var name: String? { return getField("name") as? String }
        
        init(_ macNotification: Notification) {
            self.macNotification = macNotification
        }
        
        func getField(_ key: String) -> Any? {
            return macNotification.userInfo?[key]
        }
    }
}

class AFCoreData {
    struct Core {
        var agentGoalsDelegate: AFAgentGoalsDelegate!
        var browserDelegate: AFBrowserDelegate!
        var contextMenuDelegate: AFContextMenuDelegate!
        var sceneController: AFSceneController!
        var sceneInputState: AFSceneInputState!
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
        NewGraphNode = "NewGraphNode", NewPath = "NewPath", PostInit = "PostInit", SceneControllerReady = "SceneControllerReady",
        SetAttribute = "SetAttribute" }

    let agentsPath: [JSONSubscriptType] = ["agents"]
    let pathsPath: [JSONSubscriptType] = ["paths"]
    
    var data: JSON = [ "agents": [], "paths": [] ]
    var notifications = NotificationCenter()
    
    var postInitData: [String : Any] = [:]

    init() {
    }
    
//    fileprivate func announceNewGraphNode(graphNodeName: String) { announce(event: .NewGraphNode, subjectName: graphNodeName) }
//    fileprivate func announceNewPath(pathName: String) { announce(event: .NewPath, subjectName: pathName) }
//    fileprivate func setAttribute(attributeName: String) { announce(event: .SetAttribute, subjectName: attributeName) }

    func announce(event: NotificationType, subjectName: String) {
        print("Core announces \(subjectName) on \(notifications))")
        let n = Notification.Name(rawValue: event.rawValue)
        let nn = Notification(name: n, object: subjectName, userInfo: nil)
        notifications.post(nn)
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
        if let rs = data.rawString(.utf8, options: .sortedKeys) { return rs }
        else { return "no string?" }
    }
    
    func getPathTo(_ nameToSeek: String, pathSoFar: [JSONSubscriptType] = [JSONSubscriptType]()) -> [JSONSubscriptType] {
        for (name, _) in data[pathSoFar] {
            if name == nameToSeek { return pathSoFar + [name] }
            else { return getPathTo(nameToSeek, pathSoFar: pathSoFar + [name]) }
        }
        
        return pathSoFar
    }
    
    class AFDependencyInjector {
        var afSceneController: AFSceneController?
        var agentGoalsDelegate: AFAgentGoalsDelegate?
        var browserDelegate: AFBrowserDelegate?
        var contextMenuDelegate: AFContextMenuDelegate?
        var coreData: AFCoreData?
        var gameScene: GameScene?
        var notifications: NotificationCenter?
        var sceneInputState: AFSceneInputState?
        var selectionController: AFSelectionController?
        var itemEditorDelegate: AFItemEditorDelegate?
        var menuBarDelegate: AFMenuBarDelegate?
        var topBarDelegate: AFTopBarDelegate?
        
        var someoneStillNeedsSomething = true
        
        init(afSceneController: AFSceneController, coreData: AFCoreData, gameScene: GameScene, notifications: NotificationCenter) {
            self.afSceneController = afSceneController
            self.coreData = coreData
            self.gameScene = gameScene
            self.notifications = notifications
        }
    }
    
    static func makeCore(ui: AppDelegate, gameScene: GameScene) -> AFGameSceneDelegate {
        let coreData = AFCoreData()
        var c = coreData.core

        c.sceneController = AFSceneController(gameScene: gameScene, ui: ui, contextMenu: AFContextMenu(ui: ui))
        
        let injector = AFDependencyInjector(afSceneController: c.sceneController, coreData: coreData,
                                            gameScene: gameScene, notifications: coreData.notifications)
        
        c.agentGoalsDelegate = AFAgentGoalsDelegate(injector)
        c.browserDelegate = AFBrowserDelegate(injector)
        c.contextMenuDelegate = AFContextMenuDelegate(injector)
        c.itemEditorDelegate = AFItemEditorDelegate(injector)
        c.menuBarDelegate = AFMenuBarDelegate(injector)
        
        c.sceneInputState = AFSceneInputState(injector)
        c.sceneInputState.delegate = c.sceneController

        c.topBarDelegate = AFTopBarDelegate(injector)

        repeat {
            injector.someoneStillNeedsSomething = false

            ui.inject(injector)

            c.agentGoalsDelegate.inject(injector)
            c.browserDelegate.inject(injector)
            c.contextMenuDelegate.inject(injector)
            c.itemEditorDelegate.inject(injector)
            c.menuBarDelegate.inject(injector)
            c.sceneController.inject(injector)
            c.topBarDelegate.inject(injector)
            
        } while injector.someoneStillNeedsSomething
        
        // We don't add this one to AppDelegate, because it's owned by
        // GameScene. We return it so AppDelegate can plug it into
        // GameScene.
        return c.sceneInputState
    }
    
    // Hopefully will make dependency injection cleaner, so everyone can get
    // what they need from a central place.
    @objc func postInit() {
        let n = Notification.Name(rawValue: NotificationType.PostInit.rawValue)
        let nn = Notification(name: n, object: self, userInfo: postInitData)
        
        // Note that we post the core-ready message to the default notification
        // center, not our app-specific one.
        NotificationCenter.default.post(nn)
    }
}

