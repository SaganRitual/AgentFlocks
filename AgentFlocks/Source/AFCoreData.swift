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
        var attribute: AFAgentAttribute?
        var coreData: AFCoreData?
        var editor: AFEditor?
        var gameScene: GameScene?
        var isPrimary: Bool?
        var name: String?
        var value: Any?
        var weight: Float?
        
        init(_ name: String, attribute: AFAgentAttribute? = nil, coreData: AFCoreData? = nil,
             editor: AFEditor? = nil, gameScene: GameScene? = nil, isPrimary: Bool? = nil, value: Any? = nil,
             weight: Float? = nil) {
            self.attribute = attribute
            self.coreData = coreData
            self.editor = editor
            self.gameScene = gameScene
            self.isPrimary = isPrimary
            self.name = name
            self.value = value
            self.weight = weight
        }
        
        func encode() -> [String : Any] {
            return ["attribute" : attribute ?? "",
                    "coreData"  : coreData as Any,
                    "editor"    : editor as Any,
                    "gameScene" : gameScene as Any,
                    "isPrimary" : self.isPrimary ?? false,
                    "name"      : self.name ?? "",
                    "value"     : self.value ?? "<missing value>",
                    "weight"    : self.weight ?? "<missing weight>" ]
        }
    }
    
    struct Decode {
        var attribute: AFAgentAttribute? { return getField("attribute") as? AFAgentAttribute }
        var coreData: AFCoreData? { return getField("coreData") as? AFCoreData }
        var editor: AFEditor? { return getField("editor") as? AFEditor }
        var gameScene: GameScene? { return getField("gameScene") as? GameScene }
        var isPrimary: Bool? { return getBool("isPrimary") }
        let macNotification: Notification
        var name: String? { return getField("name") as? String }
        var value: Any? { return getField("value") }
        var weight: Float? { return getFloat("weight") }

        init(_ macNotification: Notification) { self.macNotification = macNotification }
        func getField(_ key: String) -> Any? { return macNotification.userInfo?[key] }

        func getBool(_ key: String) -> Bool { return getField(key)! as! Bool }
        func getFloat(_ key: String) -> Float { return getField(key)! as! Float }
    }
}

protocol AFEditor {
    
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
        NewAgent = "NewAgent", NewComposite = "NewComposite", NewBehavior = "NewBehavior", NewGoal = "NewGoal",
        NewGraphNode = "NewGraphNode", NewPath = "NewPath", PostInit = "PostInit", SceneControllerReady = "SceneControllerReady",
        SetAttribute = "SetAttribute" }

    let agentsPath: [JSONSubscriptType] = ["agents"]
    let pathsPath: [JSONSubscriptType] = ["paths"]
    
    var data: JSON = [
        "agents": [],
        "paths": []
    ]
    
    var notifications = NotificationCenter()
    
    var postInitData: [String : Any] = [:]

    init() {
    }
    
    func setAttribute(_ attribute: AFAgentAttribute, to value: Float, for name: String) {
        let pathToAgent = getPathTo(name)!
        data[pathToAgent][attribute.rawValue] = JSON(value)
        announceAttributeChange(attribute: attribute, agentName: name, newValue: value)
    }
    
    // Reuse the notification we got--send it back out as our own message to the world
    func announce(mac notification: Notification) { notifications.post(notification) }
    
//    fileprivate func announceNewGraphNode(graphNodeName: String) { announce(event: .NewGraphNode, subjectName: graphNodeName) }
//    fileprivate func announceNewPath(pathName: String) { announce(event: .NewPath, subjectName: pathName) }
    func announceAttributeChange(attribute: AFAgentAttribute, agentName: String, newValue: Float) {
        let n = Notification.Name(rawValue: AFCoreData.NotificationType.SetAttribute.rawValue)
        let e = AFNotification.Encode(agentName, attribute: attribute, value: newValue)
        let nn = Notification(name: n, object: nil, userInfo: e.encode())
        notifications.post(nn)
    }

    func announce(event: NotificationType, subjectName: String) {
        let e = AFNotification.Encode(subjectName, coreData: self)
        let n = Notification.Name(rawValue: event.rawValue)
        let nn = Notification(name: n, object: nil, userInfo: e.encode())
        notifications.post(nn)
    }

    func announceNewAgent(agentName: String) {
        announce(event: .NewAgent, subjectName: agentName)
    }
    
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
    
    func getPathTo(_ nameToSeek: String, pathSoFar: [JSONSubscriptType] = [JSONSubscriptType]()) -> [JSONSubscriptType]? {
        for (key_, value) in data[pathSoFar] {
            // Couldn't believe this trick worked, but I couldn't believe that
            // it was necessary. SwiftyJSON would see my key as a string, and
            // wouldn't index properly into a normal array. So I have to forcibly
            // make it an integer if it looks like one.
            let s = Int(key_)
            let key: JSONSubscriptType = (s == nil) ? key_ : s!

            if value.stringValue == nameToSeek { return pathSoFar }
            else {
                if let p = getPathTo(nameToSeek, pathSoFar: pathSoFar + [key]) {
                    return p            // Say that we dug deeper
                }
            }
        }
        
        return nil
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

