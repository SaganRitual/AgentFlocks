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

extension AFInputState {
    
    class ModeDraw: GKState, EditModeRelay {
        var activePath: AFPath!
        var obstacleCloneStamp: String?
        var selectedPath: AFPath!
        
        func deselect(_ name: String) {
            AFCore.data.obstacles[name]!.deselect()
            getParentStateMachine().deselect(name)
        }
        
        func deselectAll() {
            activePath?.deselectAll()
            getParentStateMachine().deselectAll()
        }
        
        override func didEnter(from previousState: GKState?) {
            let psm = getParentStateMachine()
            psm.contextMenu.reset()
            psm.contextMenu.includeInDisplay(.Place, true)
            psm.contextMenu.enableInDisplay(.Place, true)
        }
        
        func finalizePath(close: Bool) {
            let psm = getParentStateMachine()
            activePath.refresh(final: close) // Auto-add the closing line segment
            psm.data.paths.append(key: activePath.name, value: activePath)
            
            psm.contextMenu.includeInDisplay(.SetObstacleCloneStamp, true, enable: true)
        }
        
        func getPosition(ofNode name: String) -> CGPoint {
            if activePath.graphNodes.contains(name) {
                return activePath.graphNodes[name].sprite.position
            } else {
                return activePath.containerNode!.position
            }
        }
        
        func getTouchedNode(touchedNodes: [SKNode]) -> SKNode? {
            let psm = getParentStateMachine()
            var paths = psm.data.paths
            
            // Add the current path to the lookup, in case it's not
            // already registered with the gameScene
            if let activePath = self.activePath, !paths.contains(activePath) {
                paths.append(key: activePath.name, value: activePath)
            }
            
            for afPath in paths {
                // Find the last descendant; I think that will be the top one
                for node in afPath.graphNodes.reversed() {
                    if touchedNodes.contains(node.sprite) {
                        return node.sprite
                    }
                }
            }
            
            for (_, afPath) in psm.data.obstacles {
                if touchedNodes.contains(afPath.containerNode!) {
                    return afPath.containerNode!
                }
            }
            
            return nil
        }
        
        func keyUp(with event: NSEvent) {
            if event.keyCode == AFKeyCodes.escape.rawValue {
                deselectAll()
            } else if event.keyCode == AFKeyCodes.delete.rawValue {
                getParentStateMachine().selectedNames.forEach { activePath.remove(node: $0) }
                
                activePath.refresh()
            }
        }
        
        func mouseDown(with event: NSEvent) {
            let psm = getParentStateMachine()
            
            if let down = psm.downNodeName {
                // Check whether this mouse-down is on a node that's
                // not in the currently active path; if it is, set
                // that node's parent path active. Not the same as selecting it!
                if let (path, name) = psm.getPathThatOwnsTouchedNode() {
                    var p = CGPoint()
                    if path.name == name {
                        p = path.containerNode!.position
                    } else {
                        p = CGPoint(path.graphNodes[down].position)
                    }
                    psm.setNodeToMouseOffset(anchor: p)
                    
                    // Name of the path, rather than the name of one of its nodes
                    psm.downNodeName = name
                    activePath = path
                }
            }
        }
        
        func mouseUp(with event: NSEvent) {
            let psm = getParentStateMachine()
            
            if let up = psm.upNodeName {
                if event.modifierFlags.contains(.command) {
                    if psm.mouseState == .down { // cmd+click on a node
                        psm.toggleSelection(up)
                    }
                } else {
                    if psm.mouseState == .down {    // That is, we just clicked the node
                        deselectAll()
                        
                        select(up, primary: true)
                        
                        if !activePath.finalized && up == activePath.graphNodes[0].name && activePath.graphNodes.count > 1 {
                            psm.finalizePath(close: true)
                        }
                    } else {                    // That is, we just finished dragging the node
                        trackMouse(nodeName: up, atPoint: psm.currentPosition)
                    }
                }
            } else {
                if let (path, pathname) = psm.getPathThatOwnsTouchedNode() {
                    // Click on a path that isn't selected; select that path
                    deselectAll()
                    
                    activePath = path
                    select(pathname, primary: true)
                } else {
                    // Clicked in the black; add a node
                    deselectAll()
                    
                    if event.modifierFlags.contains(.control) {
                        // Stamp an obstacle, if there's something stampable
                        stampObstacle(at: psm.currentPosition)
                    } else {
                        let startNewPath = (activePath == nil) || (activePath.finalized)
                        if startNewPath {
                            activePath = AFPath(gameScene: psm.gameScene)
                            
                            // With a new path started, no other options are available
                            // until the path is finalized. However, the "add path" option
                            // is disabled until there are at least two nodes in the path.
                            psm.contextMenu.reset()
                            psm.contextMenu.includeInDisplay(.AddPathToLibrary, true, enable: false)
                        }
                        
                        let newNode = activePath.addGraphNode(at: psm.currentPosition)
                        select(newNode.name, primary: true)
                        
                        // With two or more nodes, we now have a path that can be
                        // added to the library
                        if activePath.graphNodes.count > 1 {
                            psm.contextMenu.enableInDisplay(.AddPathToLibrary)
                        }
                    }
                }
            }
        }
        
        func rightMouseUp(with event: NSEvent) {
            getParentStateMachine().contextMenu.show(at: event.locationInWindow)
        }
        
        func select(_ name: String, primary: Bool) {
            let psm = getParentStateMachine()
            
            psm.select(name, primary: primary)
            
            activePath.select(name)
            selectedPath = activePath
            
            if activePath.name == name {
                // Selecting the path as a whole
                psm.contextMenu.includeInDisplay(.SetObstacleCloneStamp, true, enable: true)
            } else {
                // Selecting a node in a path
                psm.contextMenu.includeInDisplay(.SetObstacleCloneStamp, false)
            }
        }
        
        func setObstacleCloneStamp() {
            obstacleCloneStamp = selectedPath.name
            
            getParentStateMachine().contextMenu.includeInDisplay(.StampObstacle, true, enable: true)
        }
        
        func stampObstacle(at point: CGPoint) {
            deselectAll()
            let offset = point - CGPoint(activePath.graphNodes[0].position)
            let newPath = AFPath.init(gameScene: AFCore.inputState.gameScene, copyFrom: activePath, offset: offset)
            newPath.stampObstacle()
            getParentStateMachine().data.obstacles[newPath.name] = newPath
            select(newPath.name, primary: true)
        }
        
        func trackMouse(nodeName: String, atPoint: CGPoint) {
            let offset = getParentStateMachine().nodeToMouseOffset
            
            if activePath.graphNodes.getIndexOf(nodeName) == nil {
                activePath.containerNode!.position = atPoint + offset
            } else {
                activePath.moveNode(node: nodeName, to: atPoint + offset)
            }
        }
        
        override func willExit(to nextState: GKState) {
            deselectAll()
        }
    }
}

