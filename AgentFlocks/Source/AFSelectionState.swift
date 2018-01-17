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

import GameplayKit

protocol AFSelectionStatelet {
    var psm: AFSelectionState { get }
    
    func doubleClick(at position: CGPoint, node: SKNode?, flags: NSEvent.ModifierFlags?)
    func selectionChanged(primary: Bool, multiSelect: Bool)
    func singleClick(at position: CGPoint, node: SKNode?, flags: NSEvent.ModifierFlags?)
}

extension AFSelectionStatelet {
    func doubleClick(at position: CGPoint, node: SKNode?, flags: NSEvent.ModifierFlags?) { fatalError() }
    func selectionChanged(primary: Bool, multiSelect: Bool) { fatalError() }
    func singleClick(at position: CGPoint, node: SKNode?, flags: NSEvent.ModifierFlags?) { fatalError() }
}

class AFSelectionState: GKStateMachine {
    unowned let inputState: AFInputState
    var primarySelection: String?
    var selectedNodes = [String]()
    
    init(inputState: AFInputState) {
        self.inputState = inputState
        
        super.init(states: [
            Clear(self), MultiSelected(self), Selected(self)
        ])
        
        enter(Clear.self)
    }
}

// MARK: private methods

private extension AFSelectionState {
    
    func anyFlagsWeCareAbout(_ flags: NSEvent.ModifierFlags?) -> Bool {
        guard let flags = flags else { return false }
        
        let flagsWeCareAbout = NSEvent.ModifierFlags(rawValue:
            NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.control.rawValue |
                NSEvent.ModifierFlags.option.rawValue | NSEvent.ModifierFlags.shift.rawValue
        )
        
        return !flags.intersection(flagsWeCareAbout).isEmpty
    }

    func deselect(_ node: String) {
        inputState.deselect(node)
        
        if let ix = selectedNodes.index(of: node) { selectedNodes.remove(at: ix) }
        
        if let ps = primarySelection, node == ps  { primarySelection = nil }
        
        getCurrentState()?.selectionChanged(primary: primarySelection != nil, multiSelect: selectedNodes.count > 1)
    }
    
    func deselectAll() {
        inputState.deselectAll()
        selectedNodes.removeAll()
        primarySelection = nil
        
        getCurrentState()?.selectionChanged(primary: false, multiSelect: false)
    }
    
    func deselectPrimary() {
        deselect(primarySelection!)
    }
    
    func getCurrentState() -> AFSelectionStatelet? {
        return currentState as? AFSelectionStatelet
    }
    
    func place(primary: Bool, at position: CGPoint) {
        let newNode = inputState.place(at: position)
        selectedNodes.append(newNode)

        if primary { primarySelection = newNode }
        
        getCurrentState()?.selectionChanged(primary: primarySelection != nil, multiSelect: selectedNodes.count > 1)
    }
    
    func relaySingleClick(node: SKNode?, flags: NSEvent.ModifierFlags) {
        var editModeInstructions = EditModeInstructions(
            clickedNode: node, flags: flags, primarySelection: self.primarySelection,
            selectedNodes: self.selectedNodes
        )
        
        editModeInstructions = inputState.getEditModeInstructions(editModeInstructions)
        
        self.primarySelection = editModeInstructions.primarySelection
        self.selectedNodes = editModeInstructions.selectedNodes ?? [String]()
        
        getCurrentState()?.selectionChanged(primary: primarySelection != nil, multiSelect: selectedNodes.count > 1)
    }
    
    func select(_ node: String) {
        guard !selectedNodes.contains(node) else { fatalError() }

        selectedNodes.append(node)
        if primarySelection == nil { primarySelection = node }

        inputState.select(node, primary: primarySelection != nil)
        getCurrentState()?.selectionChanged(primary: primarySelection != nil, multiSelect: selectedNodes.count > 1)
    }
}

// MARK: Public methods

extension AFSelectionState {
    
    struct EditModeInstructions {
        let clickedNode: SKNode?
        let flags: NSEvent.ModifierFlags?
        let newNode: String?
        let primarySelection: String?
        let selectedNodes: [String]?

        init(clickedNode: SKNode?, flags: NSEvent.ModifierFlags?, primarySelection: String?, selectedNodes: [String]?) {
            self.clickedNode = clickedNode
            self.flags = flags
            self.newNode = nil
            self.primarySelection = primarySelection
            self.selectedNodes = selectedNodes
        }
    }

    func doubleClick(at position: CGPoint, node: SKNode?, flags: NSEvent.ModifierFlags?) {
        getCurrentState()?.doubleClick(at: position, node: node, flags: flags)
    }

    func singleClick(at position: CGPoint, node: SKNode?, flags: NSEvent.ModifierFlags?) {
        getCurrentState()?.singleClick(at: position, node: node, flags: flags)
    }
    
}

// MARK: States

private extension AFSelectionState {
    
    class Clear: GKState, AFSelectionStatelet {
        let psm_: AFSelectionState
        var psm: AFSelectionState { get { return psm_ } }

        init(_ parentStateMachine: AFSelectionState) { psm_ = parentStateMachine }
        
        func selectionChanged(primary: Bool, multiSelect: Bool) {
            // There's only one way to go from nothing selected
            psm.enter(Selected.self)
        }

        func singleClick(at position: CGPoint, node: SKNode?, flags: NSEvent.ModifierFlags?) {
            // Single click in the black means make a new node; for now,
            // modifiers for clicks in the black are ignored
            guard let node = node else {
                psm.place(primary: true, at: position)
                return
            }
            
            // We're in Clear state, ie, nothing is selected. User has clicked
            // on a node. Nothing to do but select it, and modifer flags
            // don't matter
            psm.select(node.name!)
        }
    }
    
    class MultiSelected: GKState, AFSelectionStatelet {
        let psm_: AFSelectionState
        var psm: AFSelectionState { get { return psm_ } }
        
        init(_ parentStateMachine: AFSelectionState) { psm_ = parentStateMachine }
        
        func selectionChanged(primary: Bool, multiSelect: Bool) {
            if multiSelect { }                              // We're already there
            else if primary { psm.enter(Selected.self) }    // No longer in single-select
            else { psm.enter(Clear.self) }                  // Nothing is selected
        }
        
        func singleClick(at position: CGPoint, node: SKNode?, flags: NSEvent.ModifierFlags?) {
            if psm.anyFlagsWeCareAbout(flags) {
                // Modified single-click. In the black or not, we can't decide what to do
                // because it's dependent on the input state. So pass it back up and have the
                // state machine relay it to the inputState
                psm.relaySingleClick(node: node, flags: flags!)
                return
            }
            
            // Unmodified single-click
            if let node = node { psm.select(node.name!) }
            else { psm.deselectAll() }
        }
    }

    class Selected: GKState, AFSelectionStatelet {
        let psm_: AFSelectionState
        var psm: AFSelectionState { get { return psm_ } }
        
        init(_ parentStateMachine: AFSelectionState) { psm_ = parentStateMachine }
        
        func selectionChanged(primary: Bool, multiSelect: Bool) {
            if multiSelect { psm.enter(MultiSelected.self) }
            else if primary { }                 // Nothing to do; we're already in single-select state
            else { psm.enter(Clear.self) }      // Nothing is selected
        }
        
        func singleClick(at position: CGPoint, node: SKNode?, flags: NSEvent.ModifierFlags?) {
            if psm.anyFlagsWeCareAbout(flags) {
                // Modified single-click. In the black or not, we can't decide what to do
                // because it's dependent on the input state. So pass it back up and have the
                // state machine relay it to the inputState
                psm.relaySingleClick(node: node, flags: flags!)
                return
            }
            
            // Unmodified single-click
            if let node = node { psm.select(node.name!) }
            else { psm.deselectAll() }
        }
    }

}
