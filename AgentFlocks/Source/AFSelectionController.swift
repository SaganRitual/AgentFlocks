//
// Created by Rob Bishop on 1/30/18 
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

class AFSelectionController: GKStateMachine {
    enum MouseState { case down, dragging, rightDown, rightUp, up }
    enum NotificationType: String { case Deselected = "Deselected", Recalled = "Recalled", Selected = "Selected"}

    private let notifications: NotificationCenter
    private unowned let scene: GameScene
    
    private var drone: AFSelectionState_Base? {
        print("gninord", currentState)
        print(currentState as? AFSelectionState_Base)
        
        return currentState as? AFSelectionState_Base
    }

    init(scene: GameScene) {
        self.notifications = NotificationCenter()
        self.scene = scene
        
        super.init(states: [AFSelectionState_Default(scene), AFSelectionState_Draw(scene),
                            AFSelectionState_AgentsGoal(scene), AFSelectionState_PathsGoal(scene)])
        
        print("setting state")
        enter(AFSelectionState_Default.self)
        print("how about now", drone)
        drone?.click_item("fart", leavingMouseState: .down, flags: nil)
        print("now?")
    }
}

// MARK: Public interface

extension AFSelectionController {
    
    func agentWasDeleted(_ name: String) {
        
    }
    
    func click_black() { deselectAll() }
    
    func click_item(name: String, leavingMouseState: MouseState, flags: NSEvent.ModifierFlags) {
        print("because I'm totally flummoxed", drone)
        drone?.click_item(name, leavingMouseState: leavingMouseState, flags: flags)
        print("and graffled")
    }

    func click_item(_ name: String, flags: NSEvent.ModifierFlags?) {
        // The SceneController needs to call us here, but it doesnt
        // know anything about mouse states. We'll assume that if
        // it was good enough to call a click, it came from a nice
        // clean .down state.
        print("and glummoxed")
        click_item(name: name, leavingMouseState: .down, flags: flags!)
        print("and baffled")
    }
    
    func dragEnd(flags: NSEvent.ModifierFlags?) {
        // Nothing to do after a drag
    }

    func getNodeAdapter(_ name: String?) -> AFNodeAdapter { return AFNodeAdapter(scene: scene, name: name) }

    func getSelection() -> ([String]?, String?) {
        var selection = [String]()
        
        scene.children.forEach { if getNodeAdapter($0.name).isSelected { selection.append($0.name!) } }
        
        let primary = scene.children.filter { return getNodeAdapter($0.name).isPrimarySelection }
        
        if selection.count > 0 { return (selection, primary.first!.name!) } else { return (nil, nil) }
    }
    
    func isNodeSelected(_ name: String) -> (isSelected: Bool, isPrimary: Bool) {
        let (selectionSet, nameOfPrimary) = getSelection()
        
        var isPrimary = false
        if let selectionSet = selectionSet {
            let inThere = selectionSet.contains(name)
            isPrimary = (nameOfPrimary ?? "") == name
            
            return (inThere, isPrimary)
        } else {
            return (false, false)
        }
    }
    
    func newAgentWasCreated(_ name: String) {
        deselectAll()
        select(name, primary: true)
        announceSelect(name, primary: true)
    }
    
    func newPathWasCreated(_ name: String) {
        
    }
    
    func newPathHandleWasCreated(_ name: String) {
        
    }
    
    func pathHandleWasDeleted(_ name: String) {
        
    }
    
    func pathWasDeleted(_ name: String) {
        
    }
    
    func startStateMachine() { enter(AFSelectionState_Default.self) }
}

/*
 
 func announceDeselect(_ node: SKNode?) {
 let n = Notification.Name(rawValue: NotificationType.Deselected.rawValue)
 let nn = Notification(name: n, object: node, userInfo: nil)
 notificationsSender.post(nn)
 }
 
 func announceSelect(_ name: String, primary: Bool) {
 let n = Notification.Name(rawValue: NotificationType.Selected.rawValue)
 let nn = Notification(name: n, object: (name, primary), userInfo: nil)
 notificationsSender.post(nn)
 }
 
 func announceSelect(_ node: SKNode, primary: Bool) {
 let n = Notification.Name(rawValue: NotificationType.Selected.rawValue)
 let nn = Notification(name: n, object: (node, primary), userInfo: nil)
 notificationsSender.post(nn)
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

 func toggleSelection(_ node: SKNode) {
 if selectedNodes.contains(node) { deselect(node) }
 else { select(node, primary: primarySelection == nil) }
 }
 //
 //    func updatePrimarySelectionState(agentNode: SKNode?) {
 //        let afAgent = AFNodeAdapter(agentNode).getOwningAgent()
 //        ui.changePrimarySelectionState(selectedAgent: afAgent)
 //    }
 */
*/

// MARK: Private methods

private extension AFSelectionController {

    func announceDeselect(_ name: String) {
        let n = Notification.Name(rawValue: NotificationType.Deselected.rawValue)
        let nn = Notification(name: n, object: name, userInfo: nil)
        notifications.post(nn)
    }
    
    func announceSelect(_ name: String, primary: Bool) {
        let n = Notification.Name(rawValue: NotificationType.Selected.rawValue)
        let nn = Notification(name: n, object: name, userInfo: nil)
        notifications.post(nn)
    }

    func deselect(_ name: String, primary: Bool) { getNodeAdapter(name).deselect() }
    
    func deselectAll() { scene.children.forEach { getNodeAdapter($0.name).deselect() } }
    
    func select(_ name: String, primary: Bool) { getNodeAdapter(name).select(primary: true) }
    
    func toggleSelection(_ name: String) {}
}

fileprivate extension AFSelectionController {
    func isItemInCurrentlySelectedPath(_ name: String) -> Bool {
        return false
    }
    
    func isTypeCompatibleWithCurrentSelection(_ name: String) -> Bool {
        let (selectedItems, _) = getSelection()
        if let selectedItems = selectedItems {
            if selectedItems.count == 0 { return true }
            
            let candidate = AFNodeAdapter(scene: scene, name: name)
            let standard = AFNodeAdapter(scene: scene, name: selectedItems.first!)

            if standard.isAgent { return candidate.isAgent }
            if standard.isPath { return candidate.isPath }
            if standard.isPathHandle { return candidate.isPathHandle }
        }

        return true
    }
}

// MARK: States for the state machine - base state

fileprivate class AFSelectionState_Base: GKState {
    unowned let scene: GameScene
    
    var afStateMachine: AFSelectionController? { return stateMachine as? AFSelectionController }

    init(_ scene: GameScene) {
        self.scene = scene
    }

    func click_black(flags: NSEvent.ModifierFlags?) {}
    func click_item(_ name: String, leavingMouseState: AFSelectionController.MouseState, flags: NSEvent.ModifierFlags?) {
        print("base")
    }
}

// MARK: States for the state machine

fileprivate class AFSelectionState_Default: AFSelectionState_Base {
    override func click_item(_ name: String, leavingMouseState: AFSelectionController.MouseState, flags: NSEvent.ModifierFlags?) {
        print("default")
        guard !(flags?.contains(.control) ?? false) else { return } // Ignore ctrl+click
        print("one")
        guard !(flags?.contains(.option) ?? false) else { return }  // Ignore opt+click
        print("two")
        
        // Ignore click on sprite if path selected, vice-versa
        guard (afStateMachine?.isTypeCompatibleWithCurrentSelection(name) ?? false) else { return }
        print("four")

        if (flags?.contains(.command) ?? false) && (afStateMachine?.isTypeCompatibleWithCurrentSelection(name) ?? false) {
            print("five")
            afStateMachine?.toggleSelection(name)         // cmd+click on a node
            print("six")
        } else {
            print("seven")
            let (wasSelected, _) = afStateMachine!.isNodeSelected(name)
            afStateMachine?.deselectAll()                 // plain click on a node
            print("eight")

            // If it was selected, leave it deselected. If it was not
            // selected, it's now the primary
            if !wasSelected {
                print("nine")
                afStateMachine?.select(name, primary: true)
            }
            print("_")
        }
    }
}

fileprivate class AFSelectionState_Draw: AFSelectionState_Base {
    override func click_item(_ name: String, leavingMouseState: AFSelectionController.MouseState, flags: NSEvent.ModifierFlags?) {
        print("draw")
        guard !(flags?.contains(.control) ?? false) else { return } // Ignore ctrl+click
        guard !(flags?.contains(.option) ?? false) else { return }  // Ignore opt+click
        guard !(flags?.contains(.command) ?? false) else { return } // Ignore prop+click
        guard leavingMouseState == .down else { return }            // Ignore mouse up after dragging in the black
                                                                    // Ignore clicks on sprites, or other paths
        guard (afStateMachine?.isItemInCurrentlySelectedPath(name) ?? false) else { return }
        
        guard !AFNodeAdapter(scene: scene, name: name).isPathHandle else { return }      // Ignore click on path handle
        guard !AFNodeAdapter(scene: scene, name: name).isSelected else { return }        // Ignore click on vertex handle already selected
        
        afStateMachine?.deselectAll()
        afStateMachine?.select(name, primary: true)
    }
}

fileprivate class AFSelectionState_AgentsGoal: AFSelectionState_Base {
    override func click_item(_ name: String, leavingMouseState: AFSelectionController.MouseState, flags: NSEvent.ModifierFlags?) {
        print("agent goals")
        guard !(flags?.contains(.control) ?? false) else { return } // Ignore ctrl+click
        guard !(flags?.contains(.option) ?? false) else { return }  // Ignore opt+click
        guard leavingMouseState == .down else { return }            // Ignore mouse up after dragging in the black
        guard AFNodeAdapter(scene: scene, name: name).isAgent else { return }           // Ignore clicks on paths or handles
        
        if flags?.contains(.command) ?? false {
            afStateMachine?.toggleSelection(name)
        } else if !AFNodeAdapter(scene: scene, name: name).isSelected && !AFNodeAdapter(scene: scene, name: name).isPrimarySelection {
            // We ignore plain click on someone already selected. Note that isPrimarySelection
            // implies isSelected, but I want to think of them separately, because we ignore
            // the click for different reasons in each case. Ignoring a click on a non-primary
            // is just ignoring the click. Ignoring a click on the primary is because we're in
            // agents selection mode; if you could deselect the primary, the reasonable response
            // for the UI would be to cancel out of agents selection mode. That might be an ok
            // feature, but I don't think I'd like it.
            afStateMachine?.deselectAll()
            afStateMachine?.select(name, primary: false)
        }
    }
}

fileprivate class AFSelectionState_PathsGoal: AFSelectionState_Base {
    override func click_item(_ name: String, leavingMouseState: AFSelectionController.MouseState, flags: NSEvent.ModifierFlags?) {
        print("paths goal")
        guard !(flags?.contains(.control) ?? false) else { return } // Ignore ctrl+click
        guard !(flags?.contains(.option) ?? false) else { return }  // Ignore opt+click
        guard leavingMouseState == .down else { return }            // Ignore mouse up after dragging in the black
        guard AFNodeAdapter(scene: scene, name: name).isPath else { return } // Ignore clicks on agents or vertex handles
        
        if flags?.contains(.command) ?? false {
            afStateMachine?.toggleSelection(name)
        } else if !AFNodeAdapter(scene: scene, name: name).isSelected {
            // We ignore plain click on someone already selected
            afStateMachine?.deselectAll()
            afStateMachine?.select(name, primary: false)
        }
    }
}
