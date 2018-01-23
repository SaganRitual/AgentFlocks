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
    func hasBeenDeselected()
    func hasBeenSelected(primary: Bool)
}

struct AFNodeAdapter {
    let name: String
    let node: SKNode
    
    init(_ node: SKNode) { self.name = node.name!; self.node = node }
    
    func getIsClickable() -> Bool {
        return false
    }
    
    func getOwningAgent() -> AFAgent2D {
        fatalError()
    }
    
    func move(to: CGPoint) {
        
    }
    
    func setZPosition(above: Int) {
        
    }
}

class AFSceneController: GKStateMachine, AFSceneInputDelegate {
    var activePath: AFPath!     // The one we're doing stuff to, whether it's selected or not (like dragging handles)
    let contextMenu: AFContextMenu
    var currentPosition = CGPoint.zero
    var appData: AFDataModel!
    var downNode: SKNode?
    unowned let gameScene: GameScene
    var goalSetupInputMode = GoalSetupInputMode.NoSelect
    var mouseState = MouseStates.up
    var nodeToMouseOffset = CGPoint.zero
    unowned let notificationsReceiver: NotificationCenter
    let notificationsSender: NotificationCenter
    var obstacleCloneStamp = String()
    var parentOfNewMotivator: AFBehavior?
    var pathForNextPathGoal = 0
    var primaryExclusion: SKNode?
    var primarySelection: SKNode?
    var selectedNodes = Set<SKNode>()
    var selectedPath: AFPath!   // The one that has a visible selection indicator on it, if any
    var ui: AppDelegate
    var upNode: SKNode?

    enum MouseStates { case down, dragging, rightDown, rightUp, up }
    enum NotificationType: String { case Deselected = "Deselected", Recalled = "Recalled", Selected = "Selected"}

    init(appData: AFDataModel, gameScene: GameScene, ui: AppDelegate, contextMenu: AFContextMenu) {
        self.appData = appData
        self.contextMenu = contextMenu
        self.gameScene = gameScene
        self.notificationsReceiver = appData.notifications
        self.notificationsSender = NotificationCenter()

        self.ui = ui

        super.init(states: [ Draw(), Default(), GoalSetup() ])

        let newAgent = NSNotification.Name(rawValue: AFDataModel.NotificationType.NewAgent.rawValue)
        let aSelector = #selector(newAgentHasBeenCreated(_:))
        self.notificationsReceiver.addObserver(self, selector: aSelector, name: newAgent, object: appData)
        
        let newPath = NSNotification.Name(rawValue: AFDataModel.NotificationType.NewPath.rawValue)
        let bSelector = #selector(newPathHasBeenCreated(_:))
        self.notificationsReceiver.addObserver(self, selector: bSelector, name: newPath, object: appData)

        enter(Default.self)
    }
    
    func addNodeToPath(at position: CGPoint) { activePath.addGraphNode(at: position) }
    
    func announceSelect(_ node: SKNode, primary: Bool) {
        let n = Notification.Name(rawValue: NotificationType.Selected.rawValue)
        let nn = Notification(name: n, object: (node, primary), userInfo: nil)
        notificationsSender.post(nn)
    }
    
    func announceDeselect(_ node: SKNode?) {
        let n = Notification.Name(rawValue: NotificationType.Deselected.rawValue)
        let nn = Notification(name: n, object: node, userInfo: nil)
        notificationsSender.post(nn)
    }

    func bringToTop(_ node: SKNode) {
        let count = compressZOrder()
        AFNodeAdapter(node).setZPosition(above: count - 1)
    }
   
    func cloneAgent() {
        guard let copyFrom = primarySelection else { return }
        appData.cloneAgent(copyFrom.name!)
    }

    func compressZOrder() -> Int {
        // Get them in order
        let zOrderStack = gameScene.children.sorted(by: { $0.zPosition < $1.zPosition })
        
        // Eliminate any gaps
        zOrderStack.enumerated().forEach {  $1.zPosition = ($1.name == nil) ? -1 : CGFloat($0) }
        
        return zOrderStack.count
    }
    
    func deselect(_ node: SKNode) {
        // Seems untidy to leave a node set as the
        // primary when we're deleting it from the
        // array of selected nodes.
        if let p = primarySelection, node == p { primarySelection = nil }
        
        selectedNodes.remove(node)
        announceDeselect(node)
    }
    
    func deselectAll() {
        primarySelection = nil
        selectedNodes.removeAll()
        announceDeselect(nil)
    }

    func finalizePath(close: Bool) {
//        appData.newGraphNode(for: <#T##String#>)
//        activePath.refresh(final: close) // Auto-add the closing line segment
//        appData.newPath()
//        appData.paths.append(key: activePath.name, value: activePath)
        
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

    func getNode(named: String?) -> SKNode? {
        guard let name = named else { return nil }
        
        return gameScene.childNode(withName: name)
    }

    func keyDown(_ info: AFSceneInput.InputInfo) {
    }
    
    func keyUp(_ info: AFSceneInput.InputInfo) {
    }
    
    func mouseDown(_ info: AFSceneInput.InputInfo) {
        downNode = info.node
        currentPosition = info.mousePosition

        if let node = info.node {
            bringToTop(node)
            setNodeToMouseOffset(anchor: node.position)
        }

        mouseState = .down
        upNode = nil
    }
    
    func mouseDrag(_ info: AFSceneInput.InputInfo) {
        mouseState = .dragging
        
        if let node = info.node { AFNodeAdapter(node).move(to: info.mousePosition) }
    }
    
    func mouseMove(_ info: AFSceneInput.InputInfo) {
        drone.mouseMove(to: info.mousePosition)
    }
    
    func mouseUp(_ info: AFSceneInput.InputInfo) {
        upNode = info.node
        currentPosition = info.mousePosition
        
        drone.click(info.node, flags: info.flags)
        
        mouseState = .up
        downNode = nil
    }
    
    @objc func newAgentHasBeenCreated(_ name: String) {
        drone.newAgentHasBeenCreated(name)
    }
    
    @objc func newPathHasBeenCreated(_ name: String) {
        drone.newPathHasBeenCreated(name)
    }
    
    func recallAgents() {
        let n = Notification.Name(rawValue: NotificationType.Recalled.rawValue)
        let nn = Notification(name: n, object: nil, userInfo: nil)
        notificationsSender.post(nn)
    }

    func rightMouseDown(_ info: AFSceneInput.InputInfo) {
        upNode = nil
        mouseState = .rightDown
    }
    
    func rightMouseUp(_ info: AFSceneInput.InputInfo) {
        upNode = info.node
        mouseState = .rightUp
    }
    
    func select(_ node: SKNode, primary: Bool) {
        if primary { primarySelection = node }
        selectedNodes.insert(node)
        announceSelect(node, primary: primary)
    }
    
    /*
     if let node = sceneUI.primarySelection {
     AFCore.ui.agentEditorController.goalsController.dataSource = entity
     AFCore.ui.agentEditorController.attributesController.delegate = entity.agent
     
     sceneUI.primarySelection = node
     sceneUI.updatePrimarySelectionState(agentNode: node)
     }
     
     sceneUI.contextMenu.includeInDisplay(.CloneAgent, true, enable: true)
 */

    func setGoalSetupInputMode(_ mode: GoalSetupInputMode) {
        goalSetupInputMode = mode
        enter(GoalSetup.self)
    }

    func setNodeToMouseOffset(anchor: CGPoint) {
        nodeToMouseOffset.x = anchor.x - currentPosition.x
        nodeToMouseOffset.y = anchor.y - currentPosition.y
    }
    
//    func showFullPathHandle(_ show: Bool = true) {
//        activePath?.showPathHandle(show)
//    }
    
    func stampObstacle() {
//        let offset = currentPosition - CGPoint(activePath.graphNodes[0].position)
//        let newPath = AFPath.init(gameScene: gameScene, copyFrom: activePath, offset: offset)
//
//        newPath.stampObstacle()
//        data.obstacles[newPath.name] = newPath
    }

    func toggleSelection(_ node: SKNode) {
        if selectedNodes.contains(node) { drone.deselect(node) }
        else { drone.select(node, primary: primarySelection == nil) }
    }
//
//    func updatePrimarySelectionState(agentNode: SKNode?) {
//        let afAgent = AFNodeAdapter(agentNode).getOwningAgent()
//        ui.changePrimarySelectionState(selectedAgent: afAgent)
//    }
}
