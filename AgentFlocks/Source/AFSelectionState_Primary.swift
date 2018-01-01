//
// Created by Rob Bishop on 12/31/17
//
// Copyright © 2017 Rob Bishop
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

protocol AFSelectionState {
    func deselectAll(newState: AFSelectionState_Primary.SelectionStates)
    func getPrimarySelectionIndex() -> Int?
    func getSelectedAgents() -> [GKAgent2D]
    func getSelectedIndexes() -> Set<Int>
    func mouseDown(with event: NSEvent)
    func mouseDragged(with event: NSEvent)
    func mouseUp(with event: NSEvent)
    func newAgent(_ nodeIndex: Int)
    func select(_ nodeIndex: Int)
    func toggleMultiSelectMode()
}

class AFSelectionState_Primary: AFSelectionState {
    unowned let gameScene: GameScene

    var currentPosition: CGPoint?
    var downNodeIndex: Int?
    var mouseState = MouseStates.up
    var mouseWasDragged = false
    var nodeToMouseOffset = CGPoint.zero
    var primarySelectionIndex: Int?
    var selectedIndexes = Set<Int>()
    var selectionState = SelectionStates.none
    var touchedNodes = [SKNode]()
    var upNodeIndex: Int?

    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }

    enum InputMode { case primary, drawPath }
    enum MouseStates { case down, dragging, rightDown, rightUp, up }
    enum SelectionStates { case none, one, multi }
    
    func deselect(_ ix: Int) {
        gameScene.entities[ix].agent.deselect()
        selectedIndexes.remove(ix)
        
        if primarySelectionIndex == ix { primarySelectionIndex = nil }
        AppDelegate.me!.removeAgentFrames()
    }
    
    func deselectAll(newState: SelectionStates = .none) {
        for entity in gameScene.entities {
            entity.agent.deselect()
        }
        
        selectionState = newState
        selectedIndexes.removeAll()
        primarySelectionIndex = nil
        AppDelegate.me!.removeAgentFrames()
    }
    
    func getAgent(at index: Int) -> AFAgent2D {
        let entity = gameScene.entities[index]
        return entity.agent
    }
    
    func getNode(at point: CGPoint) -> Int? {
        var nodeIndex: Int?
        
        for (index, entity) in gameScene.entities.enumerated() {
            if touchedNodes.contains(entity.agent.spriteContainer) {
                nodeIndex = index
                break
            }
        }
        
        return nodeIndex
    }
    
    func getPrimarySelectionIndex() -> Int? {
        return primarySelectionIndex
    }
    
    func getSelectedAgents() -> [GKAgent2D] {
        var agents = [GKAgent2D]()
        
        let indexes = getSelectedIndexes()
        for i in indexes {
            agents.append(gameScene.entities[i].agent)
        }
        
        return agents
    }
    
    func getSelectedIndexes() -> Set<Int> {
        return selectedIndexes
    }
    
    func getTouchedNodeIndex() -> Int? {
        touchedNodes = gameScene.nodes(at: currentPosition!)
        
        var ix: Int?
        for (index, entity) in gameScene.entities.enumerated() {
            if touchedNodes.contains(entity.agent.spriteContainer) {
                ix = index
                break
            }
        }
        
        return ix
    }
    
    func mouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNodeIndex = getTouchedNodeIndex()
        upNodeIndex = nil
        
        mouseState = .down
        
        if let index = downNodeIndex {
            let p = gameScene.entities[index].agent.spriteContainer.position
            nodeToMouseOffset.x = p.x - currentPosition!.x
            nodeToMouseOffset.y = p.y - currentPosition!.y
        }
    }
    
    func mouseDragged(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        mouseState = .dragging
        
        if let d = downNodeIndex, let c = currentPosition {
            trackMouse(nodeIndex: d, atPoint: c)
        }
    }
    
    func mouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        
        upNodeIndex = getTouchedNodeIndex()

        if mouseState == .down {
            updateSelectionState()
        }
        
        downNodeIndex = nil
        mouseState = .up
    }
    
    func newAgent(_ nodeIndex: Int) {
        deselectAll()
        select(nodeIndex)
        selectionState = .one
    }
    
    func rightMouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeIndex = getTouchedNodeIndex()
        downNodeIndex = nil
        mouseState = .rightDown
    }
    
    func rightMouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeIndex = getTouchedNodeIndex()
        downNodeIndex = nil
        mouseState = .rightUp
    }
    
    func select(_ ix: Int) {
        let primarySelection = (selectedIndexes.count == 0)
        
        gameScene.entities[ix].agent.select(primary: primarySelection)
        selectedIndexes.insert(ix)
        
        if selectedIndexes.count == 1 {
            primarySelectionIndex = ix
            AppDelegate.me!.placeAgentFrames(agentIndex: ix)
        }
    }
    
    func toggleSelection(_ ix: Int) {
        if selectedIndexes.contains(ix) { deselect(ix) }
        else { select(ix) }
    }
    
    func toggleMultiSelectMode() {
        if selectionState == .multi {
            // We were already in multi-mode. Now just turn it off.
            selectionState = .none
        } else {
            deselectAll(newState: .multi)
        }
    }
    
    func trackMouse(nodeIndex: Int, atPoint: CGPoint) {
        let agent = getAgent(at: nodeIndex)
        agent.position = vector_float2(Float(atPoint.x), Float(atPoint.y))
        agent.position.x += Float(nodeToMouseOffset.x)
        agent.position.y += Float(nodeToMouseOffset.y)
        agent.update(deltaTime: 0)
    }
    
    func updateSelectionState() {
        if upNodeIndex == nil {
            // User clicked on a blank area of the scene
            deselectAll()
        } else {
            switch selectionState {
            case .none:
                select(upNodeIndex!)
                selectionState = .one
                
            case .one:
                let selectedIndex = selectedIndexes.first!
                
                deselect(selectedIndex)
                selectionState = .none
                
                // If he clicked on a node other than the one that we just deselected
                if upNodeIndex != selectedIndex {
                    select(upNodeIndex!)
                    selectionState = .one
                }
                
            case .multi:
                toggleSelection(upNodeIndex!)
            }
        }
    }
}
