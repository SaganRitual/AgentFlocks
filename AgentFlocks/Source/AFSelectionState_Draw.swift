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
    var afPath = AFPath()
    var primarySelectionIndex: Int?
    var selectedIndexes = Set<Int>()
    var touchedNodes = [SKNode]()
    var upNodeIndex: Int?
    var vertices = [CGPoint]()

    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }
    
    func finalizePath(close: Bool) {
        afPath.refresh(final: close) // Auto-add the closing line segment
        gameScene.paths[afPath.name] = afPath
        gameScene.pathnames.append(afPath.name)
        afPath = AFPath()
    }
    
    func getPrimarySelectionIndex() -> Int? { return nil }
    func getSelectedIndexes() -> Set<Int> { return Set<Int>() }

    func getSelectedScenoids() -> [AFScenoid] {
        return [AFScenoid]()
    }

    func getTouchedNodeIndex() -> Int? {
        touchedNodes = gameScene.nodes(at: currentPosition!)
        
        var ix: Int?
        for (index, pathVertex) in gameScene.pathVertices.enumerated() {
            if touchedNodes.contains(pathVertex.sprite) {
                ix = index - GameScene.baseSKNodeIndex
                break
            }
        }
        
        return ix
    }
    
    func getTouchedNode() -> AFVertex? {
        touchedNodes = gameScene.nodes(at: currentPosition!)
        
        for pathVertex in gameScene.pathVertices {
            if touchedNodes.contains(pathVertex.sprite) {
                return pathVertex
            }
        }
        
        return nil
    }
    
    func keyDown(with event: NSEvent) {
        print("down in draw")
    }
    
    func keyUp(with event: NSEvent) {
        if event.keyCode == AFKeyCodes.escape.rawValue {
            deselectAll()
        } else if event.keyCode == AFKeyCodes.delete.rawValue {
            var newVertices = [AFVertex]()
            var newNodes = [AFGraphNode2D]()
            
            for (i, vertex) in gameScene.pathVertices.enumerated() {
                if !selectedIndexes.contains(i) {
                    newVertices.append(vertex)
                }
            }
            
            for (i, _) in afPath.nodes_new.enumerated() {
                if !selectedIndexes.contains(i) {
                    newNodes.append(afPath.nodes_new[i])
                }
            }

            // If I understand the way Swift works, when we assign this
            // new array, the old one will be discarded, and all the elements
            // in that array that don't have references in our new array will
            // be destructed. I'm counting on the AFVertex destructor to take
            // care of all the business.
            afPath.nodes_new = newNodes
            gameScene.pathVertices = newVertices
            afPath.refresh()
        }
    }

    func mouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNodeIndex = getTouchedNodeIndex()
        upNodeIndex = nil
        
        mouseState = .down
        
        if let index = downNodeIndex {
            let p = gameScene.pathVertices[index].position
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
        
        if let ix = upNodeIndex {
            deselectAll()
            select(ix, primary: true)

            if ix == 0 && gameScene.pathVertices.count > 1 {
                finalizePath(close: true)
            }
        } else {
            // Clicked in the black; add a node
            deselectAll()
            
            let vertex = AFVertex(scene: gameScene, position: currentPosition!)
            
            afPath.add(vertex: vertex)
            gameScene.pathVertices.append(vertex)
            select((afPath.nodes_new.count - 1), primary: true)
        }
        
        downNodeIndex = nil
        mouseState = .up
    }

    func deselectAll() {
        for vertex in gameScene.pathVertices {
            vertex.deselect()
        }
        
        selectedIndexes.removeAll()
        primarySelectionIndex = nil
    }

    func select(_ ix: Int, primary: Bool) {
        gameScene.pathVertices[ix + GameScene.baseSKNodeIndex].select(primary: primary)
        selectedIndexes.insert(ix)
        
        
        if selectedIndexes.count == 1 {
            primarySelectionIndex = ix
        }
    }

    func newAgent(_ nodeIndex: Int) {}
    func toggleMultiSelectMode() {}
}
