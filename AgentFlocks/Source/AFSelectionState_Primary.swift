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

protocol AFScenoid {
    func select(primary: Bool)
}

protocol AFSelectionState {
    func deselectAll()
    func getPrimarySelectionIndex() -> Int?
    func getSelectedIndexes() -> Set<Int>
    func getSelectedScenoids() -> [AFScenoid]
    func keyDown(with event: NSEvent)
    func keyUp(with event: NSEvent)
    func mouseDown(with event: NSEvent)
    func mouseDragged(with event: NSEvent)
    func mouseUp(with event: NSEvent)
    func newAgent(_ nodeIndex: Int)
    func select(_ nodeIndex: Int, primary: Bool)
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
    var touchedNodes = [SKNode]()
    var upNodeIndex: Int?

    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }

    enum InputMode { case primary, drawPath }
    enum MouseStates { case down, dragging, rightDown, rightUp, up }
    
    func deselect(_ ix: Int) {
        gameScene.entities[ix].agent.deselect()
        selectedIndexes.remove(ix)
        
        // We just now deselected the primary. If there's anyone
        // else selected, they need to be made the primary.
        if primarySelectionIndex == ix {
            if selectedIndexes.count > 0 {
                let newix = selectedIndexes.first!
                select(newix, primary: true)
                AppDelegate.me!.placeAgentFrames(agentIndex: newix)
            } else {
                primarySelectionIndex = nil
                AppDelegate.me!.removeAgentFrames()
            }
        }
    }
    
    func deselectAll() {
        for entity in gameScene.entities {
            entity.agent.deselect()
        }
        
        selectedIndexes.removeAll()
        primarySelectionIndex = nil
        AppDelegate.me!.removeAgentFrames()

        // Clear out the sliders so they'll recalibrate themselves to the new values
        AppDelegate.agentEditorController.attributesController.resetSliderControllers()
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
    
    func getSelectedScenoids() -> [AFScenoid] {
        var agents = [AFAgent2D]()
        
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
    
    func keyDown(with event: NSEvent) {
        print("keyDown in primary")
    }
    
    func keyUp(with event: NSEvent) {
        if event.keyCode == AFKeyCodes.escape.rawValue {
            deselectAll()
        }
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
        
        if upNodeIndex == nil {
            // Mouse up in the black; always a full deselect
            deselectAll()
            
            let imageIndex = AppDelegate.me!.agentImageIndex
            _ = AppDelegate.me!.sceneController.addNode(image: AppDelegate.me!.agents[imageIndex].image, at: currentPosition!)
            
            let nodeIndex = GameScene.me!.entities.count - 1
            newAgent(nodeIndex)
            
            AppDelegate.me!.placeAgentFrames(agentIndex: nodeIndex)
        } else {
            if event.modifierFlags.contains(.command) {
                if mouseState == .down {
                    // cmd+click on a node
                    toggleSelection(upNodeIndex!)
                }
            } else {
                if mouseState == .down {    // That is, we're coming out of down as opposed to drag
                    let setSelection = (primarySelectionIndex != upNodeIndex!)

                    deselectAll()
                    
                    if setSelection {
                        select(upNodeIndex!, primary: true)
                    }
                }
            }
        }
        
        downNodeIndex = nil
        mouseState = .up
    }
    
    func newAgent(_ nodeIndex: Int) {
        deselectAll()
        select(nodeIndex, primary: true)
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
    
    func select(_ ix: Int, primary: Bool) {
        gameScene.entities[ix].agent.select(primary: primary)
        selectedIndexes.insert(ix)
        
        if selectedIndexes.count == 1 {
            primarySelectionIndex = ix
            AppDelegate.me!.placeAgentFrames(agentIndex: ix)
            
            AppDelegate.agentEditorController.goalsController.dataSource = GameScene.me!.entities[ix]
            AppDelegate.agentEditorController.attributesController.delegate = GameScene.me!.entities[ix].agent
        }
    }
    
    func toggleSelection(_ ix: Int) {
        if selectedIndexes.contains(ix) { deselect(ix) }
        else { select(ix, primary: primarySelectionIndex == nil) }
    }
    
    func trackMouse(nodeIndex: Int, atPoint: CGPoint) {
        let agent = getAgent(at: nodeIndex)
        agent.position = vector_float2(Float(atPoint.x), Float(atPoint.y))
        agent.position.x += Float(nodeToMouseOffset.x)
        agent.position.y += Float(nodeToMouseOffset.y)
        agent.update(deltaTime: 0)
    }
}
