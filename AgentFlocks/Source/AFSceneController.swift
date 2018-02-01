//
// Created by Rob Bishop on 1/13/18
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

import GameplayKit

enum GoalSetupInputMode {
    case MultiSelectAgents, MultiSelectObstacles, NoSelect, SingleSelectAgent, SingleSelectPath
}

protocol AFCloneable {
    var name: String { get }
}

protocol AFSpriteContainerNode {
    func select(primary: Bool)
}

// Because there are so many people listening for scene activity,
// we have to use a broadcast rather than a delegate. But these
// are the messages you'll get anyway, just in a different form.
protocol AFSceneControllerDelegate {
    func hasBeenDeselected(_ name: String?)
    func hasBeenSelected(_ name: String, primary: Bool)
}

class AFSceneController: GKStateMachine, AFSceneInputStateDelegate {
    var activePath: AFPath!     // The one we're doing stuff to, whether it's selected or not (like dragging handles)
    let contextMenu: AFContextMenu
    var currentPosition = CGPoint.zero
    var coreData: AFCoreData!
    var draggedInTheBlack = false
    unowned let gameScene: GameScene
    var goalSetupInputMode = GoalSetupInputMode.NoSelect
    var mouseState = MouseStates.up
    var nodeToMouseOffset = CGPoint.zero
    var notificationsReceiver: NotificationCenter!
    let notificationsSender: NotificationCenter
    var obstacleCloneStamp = String()
    var parentOfNewMotivator: AFBehavior?
    var pathForNextPathGoal = 0
    var primarySelection: String?
    let selectionController: AFSelectionController
    var selectedNodes = Set<String>()
    var selectedPath: AFPath!   // The one that has a visible selection indicator on it, if any
    var ui: AppDelegate

    enum MouseStates { case down, dragging, rightDown, rightUp, up }
    enum NotificationType: String { case Deselected = "Deselected", Recalled = "Recalled", Selected = "Selected"}

    init(gameScene: GameScene, ui: AppDelegate, contextMenu: AFContextMenu) {
        self.contextMenu = contextMenu
        self.gameScene = gameScene
        self.notificationsSender = NotificationCenter()
        self.selectionController = AFSelectionController(scene: gameScene)

        self.ui = ui

        super.init(states: [ Draw(), Default(), GoalSetup() ])
        
        // Note: we're using the default center here; that's where we all
        // broadcast our ready messages.
        let center = NotificationCenter.default
        let sceneControllerReady = Notification.Name(rawValue: AFCoreData.NotificationType.AppCoreReady.rawValue)
        let selector = #selector(coreReady(notification:))
        center.addObserver(self, selector: selector, name: sceneControllerReady, object: nil)
        
        enter(Default.self)
    }
    
    func activateAgent(_ editor: AFAgentEditor, image: NSImage, at position: CGPoint) {
        let agent = AFAgent2D(coreData: coreData, editor: editor, image: image, position: currentPosition, scene: gameScene)
        selectionController.newAgentWasCreated(agent.name)
    }

    func addNodeToPath(at position: CGPoint) { activePath.addGraphNode(at: position) }

    func bringToTop(_ name: String) {
        let count = compressZOrder()
//        AFNodeAdapter(name).setZPosition(above: count - 1)
    }
   
    func cloneAgent() {
        guard let copyFrom = primarySelection else { return }
        coreData.core.sceneUI.cloneAgent()
    }

    func compressZOrder() -> Int {
        // Get them in order
        let zOrderStack = gameScene.children.sorted(by: { $0.zPosition < $1.zPosition })
        
        // Eliminate any gaps
        zOrderStack.enumerated().forEach {  $1.zPosition = ($1.name == nil) ? -1 : CGFloat($0) }
        
        return zOrderStack.count
    }
    
    @objc func coreReady(notification: Notification) {
        guard let info = notification.userInfo as? [String : Any] else { return }
        guard let coreDataEntry = info["AFCoreData"] as? AFCoreData else { return }
        
        NotificationCenter.default.removeObserver(self)
        
        self.coreData = coreDataEntry
        self.startStateMachine()
        self.coreData.core.sceneUI.startStateMachine()

        self.notificationsReceiver = info["DataNotifications"] as! NotificationCenter
        
        let aNotification = NSNotification.Name(rawValue: AFCoreData.NotificationType.NewAgent.rawValue)
        let aSelector = #selector(newAgentHasBeenCreated(_:))
        self.notificationsReceiver.addObserver(self, selector: aSelector, name: aNotification, object: nil)
        
        let bNotification = NSNotification.Name(rawValue: AFCoreData.NotificationType.NewPath.rawValue)
        let bSelector = #selector(newPathHasBeenCreated(_:))
        self.notificationsReceiver.addObserver(self, selector: bSelector, name: bNotification, object: nil)
    }

    func createAgent() {
        // Create a new agent and send it off into the world.
        let imageIndex = coreData.core.browserDelegate.agentImageIndex
        let image = ui.agents[imageIndex].image
        
        let agentEditor = coreData.createAgent(editorType: .createFromScratch)
        activateAgent(agentEditor, image: image, at: currentPosition)
    }
    
    func dragEnd(_ info: AFSceneInputState.InputInfo) {
        // Nothing to do, I think. Just stop tracking the mouse, which we do elsewhere. I think.
    }

    func finalizePath(close: Bool) {
//        coreData.newGraphNode(for: <#T##String#>)
//        activePath.refresh(final: close) // Auto-add the closing line segment
//        coreData.newPath()
//        coreData.paths.append(key: activePath.name, value: activePath)
        
//        contextMenu.includeInDisplay(.AddPathToLibrary, false)
//        contextMenu.includeInDisplay(.Place, true, enable: true)
//        
//        activePath = nil
//        enter(Default.self)
    }

    func flagsChanged(to newFlags: NSEvent.ModifierFlags) {
        drone.flagsChanged(to: newFlags)
    }
    
    func getNextZPosition() -> Int { return gameScene.children.count }

    func keyDown(_ info: AFSceneInputState.InputInfo) {
    }
    
    func keyUp(_ info: AFSceneInputState.InputInfo) {
    }
    
    func mouseDown(_ info: AFSceneInputState.InputInfo) {
        if let name = info.name {
            bringToTop(name)
        }
    }
    
    func mouseDrag(_ info: AFSceneInputState.InputInfo) {
        if let name = info.name, let downNode = info.downNode, name == downNode {
            AFNodeAdapter(scene: gameScene, name: name).move(to: info.mousePosition)
        }
    }
    
    func mouseMove(_ info: AFSceneInputState.InputInfo) {
        drone.mouseMove(to: info.mousePosition)
    }
    
    func mouseUp(_ info: AFSceneInputState.InputInfo) {
        print("scene controller drone.click")
        drone.click(info.name, flags: info.flags)
        print("and it's done")
    }
    
    @objc func newAgentHasBeenCreated(_ notification: Notification) {
        drone.newAgentHasBeenCreated(notification)
    }
    
    @objc func newPathHasBeenCreated(_ notification: Notification) {
        drone.newPathHasBeenCreated(notification)
    }
    
    func recallAgents() {
        let n = Notification.Name(rawValue: NotificationType.Recalled.rawValue)
        let nn = Notification(name: n, object: nil, userInfo: nil)
        notificationsSender.post(nn)
    }

    func rightMouseDown(_ info: AFSceneInputState.InputInfo) { }
    func rightMouseUp(_ info: AFSceneInputState.InputInfo) { }

    func setGoalSetupInputMode(_ mode: GoalSetupInputMode) {
        goalSetupInputMode = mode
        enter(GoalSetup.self)
    }
    
    func stampObstacle() {
//        let offset = currentPosition - CGPoint(activePath.graphNodes[0].position)
//        let newPath = AFPath.init(gameScene: gameScene, copyFrom: activePath, offset: offset)
//
//        newPath.stampObstacle()
//        data.obstacles[newPath.name] = newPath
    }
    
    func startStateMachine() { enter(Default.self) }
}
