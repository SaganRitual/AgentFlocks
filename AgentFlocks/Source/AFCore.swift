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

class AFCore {
    var bigData = AFData()

    var agentGoalsDataSource: AFMotivatorsReader!
    var agentGoalsDelegate: AFAgentGoalsDelegate!
    var browserDelegate: AFBrowserDelegate!
    var contextMenuDelegate: AFContextMenuDelegate!
    var scene: GameScene!
    var sceneController: AFSceneController!
    var sceneInputState: AFSceneInputState!
    var itemEditorDelegate: AFItemEditorDelegate!
    var menuBarDelegate: AFMenuBarDelegate!
    var topBarDelegate: AFTopBarDelegate!
    
    var ui: AppDelegate!

    init() {
        bigData.core = self
    }
    
    func getNodeWriter(_ pathToParent: [JSONSubscriptType]) -> NodeWriter {
        return NodeWriter(pathToParent, core: self)
    }
    
    func createAgent() -> AFAgentEditor {
        let agents: JSONSubscriptType = "agents"
        let newAgentName: JSONSubscriptType = NSUUID().uuidString
        let pathToHere = [agents]
        let pathToNewAgent = pathToHere + [newAgentName]
        
        getNodeWriter(pathToHere).write(this: JSON([:]), to: newAgentName)
        
        return AFAgentEditor(pathToNewAgent, core: self)
    }
    
//
//    func getAgentEditor(for name: JSON) -> AFAgentEditor {
//        return AFAgentEditor(name, core: self)
    
    func getPathTo(_ nameToSeek: String, pathSoFar: [JSONSubscriptType] = [JSONSubscriptType]()) -> [JSONSubscriptType]? {
        for (key_, value) in bigData.data[pathSoFar] {
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
    
    static func makeCore(ui: AppDelegate, gameScene: GameScene) -> AFGameSceneDelegate {
        let c = AFCore()
        
        c.sceneController = AFSceneController(gameScene: gameScene, ui: ui, contextMenu: AFContextMenu(ui: ui))
        
        let injector = AFDependencyInjector(afSceneController: c.sceneController, core: c,
                                            gameScene: gameScene, notifications: c.bigData.notifications)
        
        c.agentGoalsDelegate = AFAgentGoalsDelegate(injector)
        c.agentGoalsDataSource = AFMotivatorsReader(injector)
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
            
            c.agentGoalsDataSource.inject(injector)
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
}

extension AFCore {
    enum NotificationType: String { case AppCoreReady = "AppCoreReady", DeletedAgent = "DeletedAgent",
        DeletedBehavior = "DeletedBehavior", DeletedGoal = "DeletedGoal",
        DeletedGraphNode = "DeletedGraphNode", DeletedPath = "DeletedPath", GameSceneReady = "GameSceneReady",
        NewAgent = "NewAgent", NewComposite = "NewComposite", NewBehavior = "NewBehavior", NewGoal = "NewGoal",
        NewGraphNode = "NewGraphNode", NewPath = "NewPath", PostInit = "PostInit", SceneControllerReady = "SceneControllerReady",
        SetAttribute = "SetAttribute"
    }

    class AFDependencyInjector {
        var afSceneController: AFSceneController?
        var agentGoalsController: AgentGoalsController?
        var agentGoalsDataSource: AFMotivatorsReader?
        var agentGoalsDelegate: AFAgentGoalsDelegate?
        var browserDelegate: AFBrowserDelegate?
        var contextMenuDelegate: AFContextMenuDelegate?
        var core: AFCore?
        var gameScene: GameScene?
        var notifications: NotificationCenter?
        var sceneInputState: AFSceneInputState?
        var selectionController: AFSelectionController?
        var itemEditorDelegate: AFItemEditorDelegate?
        var menuBarDelegate: AFMenuBarDelegate?
        var topBarDelegate: AFTopBarDelegate?
        
        var someoneStillNeedsSomething = true
        
        init(afSceneController: AFSceneController, core: AFCore, gameScene: GameScene, notifications: NotificationCenter) {
            self.afSceneController = afSceneController
            self.core = core
            self.gameScene = gameScene
            self.notifications = notifications
        }
    }
}

