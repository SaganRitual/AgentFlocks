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

struct AFNodeAdapter {
    let name: String?
    let node: SKNode
    
    init(_ node: SKNode) {
        // Lots of sprites out there, but we only care about the ones
        // that have names, and not even all of them.
        if let nodeName = node.name { self.name = nodeName } else { self.name = nil }
        self.node = node
    }
    
    func getIsClickable() -> Bool {
        return (getUserDataEntry("clickable") as? Bool) ?? false
    }
    
    static func getOwningAgent(for node: SKNode) -> AFAgent2D? {
        if let userData = node.userData, let value = userData["OwningAgent"] {
            return value as? AFAgent2D
        } else {
            return nil
        }
    }
    
    func getOwningAgent() -> AFAgent2D? {
        return AFNodeAdapter.getOwningAgent(for: self.node)
    }
    
    func getUserDataEntry(_ name: String) -> Any? {
        if let userData = node.userData, let value = userData[name] {
            return value
        } else {
            return nil
        }
    }
    
    func move(to position: CGPoint) {
        getOwningAgent()!.move(to: position)
    }
    
    func setIsClickable(_ set: Bool = true) {
        setUserDataEntry(key: "clickable", value: set)
    }
    
    func setOwningAgent(_ agent: AFAgent2D) {
        if let userData = node.userData { userData["OwningAgent"] = agent }
    }
    
    func setUserDataEntry(key: String, value: Any) {
        if let userData = node.userData {
            userData[key] = value
        }
    }
    
    func setZPosition(above: Int) {
        setUserDataEntry(key: "zPosition", value: above)
    }
}

class AFSceneController: GKStateMachine, AFSceneInputDelegate {
    var activePath: AFPath!     // The one we're doing stuff to, whether it's selected or not (like dragging handles)
    let contextMenu: AFContextMenu
    var currentPosition = CGPoint.zero
    var coreData: AFCoreData!
    var downNode: SKNode?
    unowned let gameScene: GameScene
    var goalSetupInputMode = GoalSetupInputMode.NoSelect
    var mouseState = MouseStates.up
    var nodeToMouseOffset = CGPoint.zero
    var notificationsReceiver: NotificationCenter!
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

    init(gameScene: GameScene, ui: AppDelegate, contextMenu: AFContextMenu) {
        self.contextMenu = contextMenu
        self.gameScene = gameScene
        self.notificationsSender = NotificationCenter()

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
    
    @objc func coreReady(notification: Notification) {
        guard let info = notification.userInfo as? [String : Any] else { return }
        guard let coreDataEntry = info["AFCoreData"] as? AFCoreData else { return }
        
        NotificationCenter.default.removeObserver(self)

        self.coreData = coreDataEntry
        self.notificationsReceiver = info["DataNotifications"] as! NotificationCenter

        let aNotification = NSNotification.Name(rawValue: AFCoreData.NotificationType.NewAgent.rawValue)
        let aSelector = #selector(newAgentHasBeenCreated(_:))
        self.notificationsReceiver.addObserver(self, selector: aSelector, name: aNotification, object: nil)
        
        let bNotification = NSNotification.Name(rawValue: AFCoreData.NotificationType.NewPath.rawValue)
        let bSelector = #selector(newPathHasBeenCreated(_:))
        self.notificationsReceiver.addObserver(self, selector: bSelector, name: bNotification, object: nil)
    }
    
    func addNodeToPath(at position: CGPoint) { activePath.addGraphNode(at: position) }
    
    func announceDeselect(_ node: SKNode?) {
        let n = Notification.Name(rawValue: NotificationType.Deselected.rawValue)
        let nn = Notification(name: n, object: node, userInfo: nil)
        notificationsSender.post(nn)
    }

    func announceSelect(_ node: SKNode, primary: Bool) {
        let n = Notification.Name(rawValue: NotificationType.Selected.rawValue)
        let nn = Notification(name: n, object: (node, primary), userInfo: nil)
        notificationsSender.post(nn)
    }

    func bringToTop(_ node: SKNode) {
        let count = compressZOrder()
        AFNodeAdapter(node).setZPosition(above: count - 1)
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
        
        if let node = info.node {
            AFNodeAdapter(node).move(to: info.mousePosition)
        }
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

    func rightMouseDown(_ info: AFSceneInput.InputInfo) {
        upNode = nil
        mouseState = .rightDown
    }
    
    func rightMouseUp(_ info: AFSceneInput.InputInfo) {
        upNode = info.node
        mouseState = .rightUp
    }
    
    func select(_ nodeName: String, primary: Bool) {
        let node = gameScene.nodes(at: currentPosition).filter { $0.name != nil && $0.name! == nodeName }
        if node.count > 0 {
            select(node.first!, primary: primary)
        }
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
        if selectedNodes.contains(node) { deselect(node) }
        else { select(node, primary: primarySelection == nil) }
    }
//
//    func updatePrimarySelectionState(agentNode: SKNode?) {
//        let afAgent = AFNodeAdapter(agentNode).getOwningAgent()
//        ui.changePrimarySelectionState(selectedAgent: afAgent)
//    }
}
