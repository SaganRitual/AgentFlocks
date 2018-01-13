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
    var afPath: AFPath!
    var currentPosition: CGPoint?
    var downNodeName: String?
    unowned let gameScene: GameScene
    var mouseState = AFSelectionState_Primary.MouseStates.up
    var nodeToMouseOffset = CGPoint.zero
    var primarySelectionName: String?
    var namesOfSelectedScenoids = [String]()
    var obstacleCloneStamp: String?
    var selectedNames = Set<String>()
    var touchedNodes = [SKNode]()
    var upNodeName: String?
    var vertices = [CGPoint]()

    init(gameScene: GameScene) {
        self.gameScene = gameScene
        afPath = AFPath()
    }
    
    func activate() { GameScene.me!.paths.forEach{ $0.showNodes(true) } }
    
    func deactivate() { GameScene.me!.paths.forEach{ $0.showNodes(false) } }
    
    func deselectAll() {
        afPath?.deselectAll()
        namesOfSelectedScenoids.removeAll()
    }

    func finalizePath(close: Bool) {
        afPath.refresh(final: close) // Auto-add the closing line segment
        gameScene.paths.append(key: afPath.name, value: afPath)
    }
    
    func getPathThatOwnsTouchedNode() -> (AFPath, String)? {
        touchedNodes = gameScene.nodes(at: currentPosition!)
        
        for skNode in touchedNodes.reversed() {
            if let name = skNode.name {
                for path in gameScene.paths {
                    if path.graphNodes.getIndexOf(name) != nil {
                        return (path, name)
                    }
                }
            }
        }
        
        return nil
    }
    
    func getPrimarySelectionName() -> String? { return nil }
    func getSelectedNames() -> Set<String> { return Set<String>() }

    func getSelectedScenoids() -> [AFScenoid] {
        return [AFScenoid]()
    }
    
    func getTouchedNode() -> AFGraphNode2D? {
        guard let afPath = self.afPath else { return nil }

        var touchedNode: AFGraphNode2D?

        touchedNodes = gameScene.nodes(at: currentPosition!)

        for skNode in touchedNodes.reversed() {
            if let name = skNode.name {
                if let ix = afPath.graphNodes.getIndexOf(name) {
                    touchedNode = afPath.graphNodes[ix]
                    break
                }
            }
        }
        
        return touchedNode
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
            namesOfSelectedScenoids.forEach { afPath.remove(node: $0) }

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
        guard let down = downNodeName else { return }

        mouseState = .dragging
        currentPosition = event.location(in: gameScene)
        trackMouse(name: down, atPoint: currentPosition!)
        afPath.moveNode(node: down, to: currentPosition!)
    }

    func mouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeName = getTouchedNodeName()
        
        if let up = upNodeName {
            if mouseState == .down {    // That is, we just clicked the node
                deselectAll()
                
                select(up, primary: true)
                
                if !afPath.finalized && up == afPath.graphNodes[0].name && afPath.graphNodes.count > 1 {
                    finalizePath(close: true)
                }
            } else {                    // That is, we just finished dragging the node
                trackMouse(name: up, atPoint: currentPosition!)
                afPath.moveNode(node: up, to: currentPosition!)
            }
        } else {
            if let (path, nodename) = getPathThatOwnsTouchedNode() {
                // Click on a path that isn't selected; select that path
                deselectAll()

                afPath = path
                select(nodename, primary: true)
            } else {
                // Clicked in the black; add a node
                deselectAll()
                
                print((afPath == nil),(afPath.finalized))
                let startNewPath = (afPath == nil) || (afPath.finalized)
                if startNewPath { afPath = AFPath() }

                let newNode = afPath.addGraphNode(at: currentPosition!)
                select(newNode.name, primary: true)
            }
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
        contextMenu.autoenablesItems = false
        
        let okToLeaveDrawMode = (afPath == nil) || afPath.finalized
        let aNodeWasClicked = (upNodeName != nil)
        let nodeClickYeahButFinalizedPath = afPath.finalized
        
        if (aNodeWasClicked && !nodeClickYeahButFinalizedPath) || !okToLeaveDrawMode {
            contextMenu.addItem(withTitle: titles[.AddPathToLibrary]!, action: #selector(AppDelegate.contextMenuClicked(_:)), keyEquivalent: "")
            let m = contextMenu.item(at: 0)!; m.isEnabled = (afPath.graphNodes.count > 1)
        } else {
            contextMenu.addItem(withTitle: titles[.PlaceAgents]!, action: #selector(AppDelegate.contextMenuClicked(_:)), keyEquivalent: "")
            contextMenu.addItem(withTitle: titles[.SetObstacleCloneStamp]!, action: #selector(AppDelegate.contextMenuClicked(_:)), keyEquivalent: "")
            contextMenu.addItem(withTitle: titles[.StampObstacle]!, action: #selector(AppDelegate.contextMenuClicked(_:)), keyEquivalent: "")
            
            contextMenu.item(at: 2)!.isEnabled = (self.obstacleCloneStamp != nil)
        }

        (NSApp.delegate as? AppDelegate)?.showContextMenu(at: event.locationInWindow)
	}

    func select(_ name: String, primary: Bool) {
        if primary { primarySelectionName = name }

        namesOfSelectedScenoids.append(name)
        afPath.select(name)
    }

    func newAgent(_ name: String) {}
    func toggleMultiSelectMode() {}
    
    func setObstacleCloneStamp() {
        obstacleCloneStamp = afPath.name
    }
    
    func stampObstacle(at point: CGPoint) {
        let offset = point - CGPoint(afPath.graphNodes[0].position)
        let newPath = AFPath.init(copyFrom: afPath, offset: offset)
        newPath.stampObstacle()
        GameScene.me!.obstacles[newPath.name] = newPath
    }
    
    func trackMouse(name: String, atPoint: CGPoint) {
        let node = afPath.graphNodes[name]
        node.position = vector_float2(Float(atPoint.x), Float(atPoint.y))
        node.position.x += Float(nodeToMouseOffset.x)
        node.position.y += Float(nodeToMouseOffset.y)
    }
}
