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

extension CGPoint {
    init(float2Point: vector_float2) {
        self.x = CGFloat(float2Point.x)
        self.y = CGFloat(float2Point.y)
    }
}

class AFSelectionState_Draw: AFSelectionState {
    var currentPosition: CGPoint?
    var downNodeName: String?
    unowned let gameScene: GameScene
    var mouseState = AFSelectionState_Primary.MouseStates.up
    var nodeToMouseOffset = CGPoint.zero
    var afPath = AFPath()
    var primarySelectionName: String?
    var namesOfSelectedScenoids = [String]()
    var selectedNames = Set<String>()
    var touchedNodes = [SKNode]()
    var upNodeName: String?
    var vertices = [CGPoint]()

    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }
    
    func finalizePath(close: Bool) {
        afPath.refresh(final: close) // Auto-add the closing line segment
        gameScene.paths.append(key: afPath.name, value: afPath)
        
        // Start a new path in for next round of drawing
        afPath = AFPath()
    }
    
    func getPrimarySelectionName() -> String? { return nil }
    func getSelectedNames() -> Set<String> { return Set<String>() }

    func getSelectedScenoids() -> [AFScenoid] {
        return [AFScenoid]()
    }
    
    func getTouchedNode() -> AFGraphNode2D? {
        touchedNodes = gameScene.nodes(at: currentPosition!)
        
        // Find the last descendant; I think that will be the top one
        for i in stride(from: afPath.graphNodes.count - 1, through: 0, by: -1) {
            let graphNode = afPath.graphNodes[i]
            
            if touchedNodes.contains(graphNode.sprite) {
                return graphNode
            }
        }
        
        return nil
    }
    
    func getTouchedNodeName() -> String? {
        if let graphNode = getTouchedNode() {
            return graphNode.name
        } else {
            return nil
        }
    }
    
    func keyDown(with event: NSEvent) {
        print("down in draw")
    }
    
    func keyUp(with event: NSEvent) {
        if event.keyCode == AFKeyCodes.escape.rawValue {
            deselectAll()
        } else if event.keyCode == AFKeyCodes.delete.rawValue {
            let newNodes = AFOrderedMap<String, AFGraphNode2D>()
            
            for graphNode in afPath.graphNodes {
                let newNode = AFGraphNode2D(float2Point: graphNode.position)
                if !namesOfSelectedScenoids.contains(graphNode.name) {
                    newNodes.append(key: newNode.name, value: newNode)
                }
            }

            // If I understand the way Swift works, when we assign this
            // new array, the old one will be discarded, and all the elements
            // in that array that don't have references in our new array will
            // be destructed. I'm counting on the AFVertex destructor to take
            // care of all the business.
            afPath.graphNodes = newNodes
            afPath.refresh()
        }
    }

    func mouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNodeName = getTouchedNodeName()
        upNodeName = nil
        
        mouseState = .down
        
        if let down = downNodeName {
            let p = CGPoint(afPath.graphNodes[down].position)
            nodeToMouseOffset.x = p.x - currentPosition!.x
            nodeToMouseOffset.y = p.y - currentPosition!.y
        }
    }
    
    func mouseDragged(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
    }

    func mouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeName = getTouchedNodeName()
        
        if let up = upNodeName {
            deselectAll()
            
            select(up, primary: true)

            if up == afPath.graphNodes[0].name && afPath.graphNodes.count > 1 {
                finalizePath(close: true)
            }
        } else {
            // Clicked in the black; add a node
            deselectAll()
            
            let newNode = afPath.addGraphNode(at: currentPosition!)
            select(newNode.name, primary: true)
        }
        
        downNodeName = nil
        mouseState = .up
    }
	
	func rightMouseDown(with event: NSEvent) {
	}
	
	func rightMouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeName = getTouchedNodeName()
        downNodeName = nil
        mouseState = .rightUp

        let contextMenu = AppDelegate.me!.contextMenu!
        let titles = AppDelegate.me!.contextMenuTitles
        
        contextMenu.removeAllItems()
        contextMenu.addItem(withTitle: titles[.PlaceAgents]!, action: #selector(AppDelegate.contextMenuClicked(_:)), keyEquivalent: "")

        contextMenu.autoenablesItems = false
        
        let m = contextMenu.item(at: 0)!; m.isEnabled = true

        (NSApp.delegate as? AppDelegate)?.showContextMenu(at: event.locationInWindow)
	}
	
    func deselectAll() {
        afPath.deselectAll()
    }

    func select(_ name: String, primary: Bool) {

        afPath.select(name)
    }

    func newAgent(_ name: String) {}
    func toggleMultiSelectMode() {}
}
