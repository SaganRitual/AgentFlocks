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

class AFSelectionState_Draw: AFSelectionState {
    var currentPosition: CGPoint?
    var downNodeIndex: Int?
    unowned let gameScene: GameScene
    var mouseState = AFSelectionState_Primary.MouseStates.up
    var nodeToMouseOffset = CGPoint.zero
    var primarySelectionIndex: Int?
    var selectedIndexes = Set<Int>()
    var selectionState = AFSelectionState_Primary.SelectionStates.none
    var touchedNodes = [SKNode]()
    var upNodeIndex: Int?
    var vertices = [CGPoint]()

    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }
    
    func getPrimarySelectionIndex() -> Int? { return nil }
    func getSelectedAgents() -> [GKAgent2D] { return [GKAgent2D]() }
    func getSelectedIndexes() -> Set<Int> { return Set<Int>() }
    
    func getTouchedNodeIndex() -> Int? {
        touchedNodes = gameScene.nodes(at: currentPosition!)
        
        var ix: Int?
        for (index, pathHandle) in gameScene.pathHandles.enumerated() {
            if touchedNodes.contains(pathHandle) {
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
            let p = gameScene.pathHandles[index].position
            nodeToMouseOffset.x = p.x - currentPosition!.x
            nodeToMouseOffset.y = p.y - currentPosition!.y
        }
    }
    
    func mouseDragged(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
    }

    func mouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeIndex = getTouchedNodeIndex()
        
        if let index = upNodeIndex {
            // Clicked a node without moving it; delete it
            gameScene.pathHandles[index].removeFromParent()
            gameScene.pathHandles.remove(at: index)
            vertices.remove(at: index)
        } else {
            // Clicked in the black; add a node
            vertices.append(currentPosition!)
            
            let marker = SKShapeNode(circleOfRadius: 5)
            marker.fillColor = .yellow
            marker.position = currentPosition!
            gameScene.addChild(marker)
            gameScene.pathHandles.append(marker)
            
            if vertices.count > 1 {
                let last = vertices[vertices.count - 1]
                let penultimate = vertices[vertices.count - 2]

                let pathToDraw = CGMutablePath()
                pathToDraw.move(to: penultimate)
                pathToDraw.addLine(to: last)
                
                let line = SKShapeNode(path: pathToDraw)
                gameScene.addChild(line)
            }
        }
        
        downNodeIndex = nil
        mouseState = .up
    }

    func deselectAll(newState: AFSelectionState_Primary.SelectionStates = .none) {
        for entity in gameScene.entities {
            entity.agent.deselect()
        }
        
        selectionState = newState
        selectedIndexes.removeAll()
        primarySelectionIndex = nil
        AppDelegate.me!.removeAgentFrames()
    }

    func newAgent(_ nodeIndex: Int) {}
    func select(_ nodeIndex: Int) {}
    func toggleMultiSelectMode() {}
}
