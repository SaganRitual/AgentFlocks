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

    var uiNotifications: Foundation.NotificationCenter!
    private unowned let gameScene: GameScene
    
    private var drone: AFSelectionState_Base? { return currentState as? AFSelectionState_Base }
    
    var primarySelection: String? {
        let primary = gameScene.children.filter { let n = getNodeAdapter($0.name); return n.isPrimarySelection }
        return primary.first?.name
    }

    init(gameScene: GameScene) {
        self.gameScene = gameScene
        
        super.init(states: [AFSelectionState_Default(gameScene), AFSelectionState_Draw(gameScene),
                            AFSelectionState_AgentsGoal(gameScene), AFSelectionState_PathsGoal(gameScene)])
        
        enter(AFSelectionState_Default.self)
    }
}

// MARK: Public interface

extension AFSelectionController {
    
    func agentWasDeleted(_ name: String) {
        
    }
    
    func click_black() { deselectAll() }
    
    func click_item(name: String, leavingMouseState: MouseState, flags: NSEvent.ModifierFlags) {
        drone?.click_item(name, leavingMouseState: leavingMouseState, flags: flags)
    }

    func click_item(_ name: String, flags: NSEvent.ModifierFlags?) {
        // The SceneController needs to call us here, but it doesnt
        // know anything about mouse states. We'll assume that if
        // it was good enough to call a click, it came from a nice
        // clean .down state.
        click_item(name: name, leavingMouseState: .down, flags: flags!)
    }
    
    func dragEnd(flags: NSEvent.ModifierFlags?) {
        // Nothing to do after a drag
    }

    func getNodeAdapter(_ name: String?) -> AFNodeAdapter { return AFNodeAdapter(gameScene: gameScene, name: name) }

    func getSelection() -> ([String]?, String?) {
        var selection = [String]()
        
        gameScene.children.forEach { if getNodeAdapter($0.name).isSelected { selection.append($0.name!) } }
        
        let primary = gameScene.children.filter { let n = getNodeAdapter($0.name); return n.isPrimarySelection }
        
        if selection.count > 0 { return (selection, primary.first!.name!) } else { return (nil, nil) }
    }
    
    func inject(_ injector: AFCore.AFDependencyInjector) {
        var iStillNeedSomething = false
        
        if let un = injector.uiNotifications { self.uiNotifications = un }
        else { injector.someoneStillNeedsSomething = true; iStillNeedSomething = true }

        if !iStillNeedSomething {
            injector.selectionController = self
        }
    }
    
    func isNodeSelected(_ name: String) -> (isSelected: Bool, isPrimarySelection: Bool) {
        let (selectionSet, nameOfPrimary) = getSelection()
        
        var isPrimarySelection = false
        if let selectionSet = selectionSet {
            let inThere = selectionSet.contains(name)
            isPrimarySelection = (nameOfPrimary ?? "") == name
            
            return (inThere, isPrimarySelection)
        } else {
            return (false, false)
        }
    }
    
    func newAgentWasCreated(_ name: String) {
        deselectAll()
        select(name, primary: true)
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

// MARK: Private methods

private extension AFSelectionController {
    func announceDeselect(_ name: String) {
        let p = AFNotificationPacket.ScenoidDeselected(name)
        let q = AFNotificationPacket.pack(p)
        let n = Foundation.Notification(name: .ScenoidDeselected, object: nil, userInfo: q)
        AppDelegate.me.uiNotifications.post(n)
    }
    
    func announceSelect(_ name: String, primary: Bool) {
        let p = AFNotificationPacket.ScenoidSelected(name, primary)
        let q = AFNotificationPacket.pack(p)
        let n = Foundation.Notification(name: .ScenoidSelected, object: nil, userInfo: q)
        AppDelegate.me.uiNotifications.post(n)
    }

    func deselect(_ name: String) { var a = getNodeAdapter(name); a.deselect(); announceDeselect(name) }
    func deselectAll() { gameScene.children.forEach { var a = getNodeAdapter($0.name); a.deselect(); announceDeselect($0.name!) } }
    func select(_ name: String, primary: Bool) { var a = getNodeAdapter(name); a.select(primary: primary); announceSelect(name, primary: primary) }
    
    func toggleSelection(_ name: String) {
        let (selectedAgents, primarySelection) = getSelection()
        let a = getNodeAdapter(name)

        if a.isSelected {
            
            // I'm being deselected. If I'm currently the primary selection,
            // someone else needs to become the primary. Unless there's no
            // one else selected, that is.
            let setNewPrimarySelection = ((primarySelection ?? "") == name) && (selectedAgents!.count > 1)
            deselect(name);

            if setNewPrimarySelection { select(selectedAgents!.first!, primary: setNewPrimarySelection) }
        } else {
            let isNewPrimarySelection = selectedAgents == nil || selectedAgents!.count == 0
            select(name, primary: isNewPrimarySelection)
        }
    }
}

// MARK: Miscellaney

fileprivate extension AFSelectionController {
    func isItemInCurrentlySelectedPath(_ name: String) -> Bool {
        return false
    }
    
    func isTypeCompatibleWithCurrentSelection(_ name: String) -> Bool {
        let (selectedItems, _) = getSelection()
        if let selectedItems = selectedItems {
            if selectedItems.count == 0 { return true }
            
            let candidate = AFNodeAdapter(gameScene: gameScene, name: name)
            let standard = AFNodeAdapter(gameScene: gameScene, name: selectedItems.first!)

            if standard.isPath { return candidate.isPath }
            if standard.isPathHandle { return candidate.isPathHandle }
        }

        return true
    }
}

// MARK: States for the state machine - base state

fileprivate class AFSelectionState_Base: GKState {
    unowned let gameScene: GameScene
    
    var afStateMachine: AFSelectionController? { return stateMachine as? AFSelectionController }

    init(_ gameScene: GameScene) {
        self.gameScene = gameScene
    }

    func click_black(flags: NSEvent.ModifierFlags?) {}
    func click_item(_ name: String, leavingMouseState: AFSelectionController.MouseState, flags: NSEvent.ModifierFlags?) { }
}

// MARK: States for the state machine

fileprivate class AFSelectionState_Default: AFSelectionState_Base {
    override func click_item(_ name: String, leavingMouseState: AFSelectionController.MouseState, flags: NSEvent.ModifierFlags?) {
        guard !(flags?.contains(.control) ?? false) else { return } // Ignore ctrl+click
        guard !(flags?.contains(.option) ?? false) else { return }  // Ignore opt+click
        
        // Ignore click on sprite if path selected, vice-versa
        guard (afStateMachine?.isTypeCompatibleWithCurrentSelection(name) ?? false) else { return }

        if (flags?.contains(.command) ?? false) && (afStateMachine?.isTypeCompatibleWithCurrentSelection(name) ?? false) {
            afStateMachine?.toggleSelection(name)         // cmd+click on a node
        } else {
            let (wasSelected, _) = afStateMachine!.isNodeSelected(name)
            afStateMachine?.deselectAll()                 // plain click on a node

            // If it was selected, leave it deselected. If it was not
            // selected, it's now the primary
            if !wasSelected { afStateMachine?.select(name, primary: true) }
        }
    }
}

fileprivate class AFSelectionState_Draw: AFSelectionState_Base {
    override func click_item(_ name: String, leavingMouseState: AFSelectionController.MouseState, flags: NSEvent.ModifierFlags?) {
        guard !(flags?.contains(.control) ?? false) else { return } // Ignore ctrl+click
        guard !(flags?.contains(.option) ?? false) else { return }  // Ignore opt+click
        guard !(flags?.contains(.command) ?? false) else { return } // Ignore prop+click
        guard leavingMouseState == .down else { return }            // Ignore mouse up after dragging in the black
                                                                    // Ignore clicks on sprites, or other paths
        guard (afStateMachine?.isItemInCurrentlySelectedPath(name) ?? false) else { return }
        
        guard !AFNodeAdapter(gameScene: gameScene, name: name).isPathHandle else { return }      // Ignore click on path handle
        guard !AFNodeAdapter(gameScene: gameScene, name: name).isSelected else { return }        // Ignore click on vertex handle already selected
        
        afStateMachine?.deselectAll()
        afStateMachine?.select(name, primary: true)
    }
}

fileprivate class AFSelectionState_AgentsGoal: AFSelectionState_Base {
    override func click_item(_ name: String, leavingMouseState: AFSelectionController.MouseState, flags: NSEvent.ModifierFlags?) {
        guard !(flags?.contains(.control) ?? false) else { return } // Ignore ctrl+click
        guard !(flags?.contains(.option) ?? false) else { return }  // Ignore opt+click
        guard leavingMouseState == .down else { return }            // Ignore mouse up after dragging in the black
        
        if flags?.contains(.command) ?? false {
            afStateMachine?.toggleSelection(name)
        } else if !AFNodeAdapter(gameScene: gameScene, name: name).isSelected && !AFNodeAdapter(gameScene: gameScene, name: name).isPrimarySelection {
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
        guard !(flags?.contains(.control) ?? false) else { return } // Ignore ctrl+click
        guard !(flags?.contains(.option) ?? false) else { return }  // Ignore opt+click
        guard leavingMouseState == .down else { return }            // Ignore mouse up after dragging in the black
        guard AFNodeAdapter(gameScene: gameScene, name: name).isPath else { return } // Ignore clicks on agents or vertex handles
        
        if flags?.contains(.command) ?? false {
            afStateMachine?.toggleSelection(name)
        } else if !AFNodeAdapter(gameScene: gameScene, name: name).isSelected {
            // We ignore plain click on someone already selected
            afStateMachine?.deselectAll()
            afStateMachine?.select(name, primary: false)
        }
    }
}
