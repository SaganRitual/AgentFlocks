//
// Created by Rob Bishop on 1/18/18
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

extension AFSceneUI {
    
    class Draw: GKState, AFSceneDrone {
        var activePath: AFPath!
        var drawIndicator: SKShapeNode!
        let sceneUI: AFSceneUI
        
        init(_ sceneUI: AFSceneUI) {
            self.sceneUI = sceneUI
        }
        
        func addNodeIfOk(at position: CGPoint) -> Bool {
            var addNewNode = true
            
            // if the user clicked on a node in the path that isn't the start node,
            // just ignore the click. Don't add a node in the same position. Might
            // change that in the future.
            for node in activePath.graphNodes {
                let touchedNodes = sceneUI.gameScene.nodes(at: position).filter { $0.name != nil }
                if touchedNodes.contains(where: { return $0.name == node.name }) {
                    addNewNode = false
                    break
                }
            }
            
            if addNewNode {
                addNodeToPath(at: sceneUI.currentPosition)
            }
            
            return addNewNode
        }
        
        func addNodeToPath(at position: CGPoint) {
            let newNode = activePath.addGraphNode(at: position)
            select(newNode.name, primary: true)
            
            // With two or more nodes, we now have a path that can be
            // added to the library
            if activePath.graphNodes.count > 1 {
                sceneUI.contextMenu.enableInDisplay(.AddPathToLibrary)
            }
        }
        
        func deselect(_ name: String) {
            activePath.graphNodes[name].deselect()
            sceneUI.selectedNames.remove(name)
            if sceneUI.primarySelection == name || sceneUI.selectedNames.count == 0 {
                deselect_()
            }
        }
        
        func deselectAll() {
            sceneUI.selectedNames.forEach { deselect($0) }
            sceneUI.selectedNames.removeAll()
            deselect_()
        }
        
        func deselect_() {
            sceneUI.contextMenu.includeInDisplay(.SetObstacleCloneStamp, false)
        }
        
        func finalizePath(close: Bool) {
            activePath.refresh(final: close) // Auto-add the closing line segment
            AFCore.data.paths.append(key: activePath.name, value: activePath)
            
            sceneUI.contextMenu.includeInDisplay(.AddPathToLibrary, false)
            sceneUI.contextMenu.includeInDisplay(.Place, true, enable: true)
            
            activePath = nil
        }
        
        func finalizePathIfOk() {
            guard activePath.graphNodes.count > 1 else { return }

            finalizePath(close: true)
            sceneUI.stateMachine.enter(Default.self)
        }
        
        func getPosition(ofNode name: String) -> CGPoint {
            if activePath.graphNodes.contains(name) {
                return activePath.graphNodes[name].sprite.position
            } else {
                return activePath.containerNode!.position
            }
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // Can't leave draw state while we have an unregistered path
            return activePath == nil || activePath!.finalized
        }
        
        func mouseDown(on nodeName: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
            if let drawIndicator = self.drawIndicator {
                drawIndicator.removeFromParent()
            }

            if let downName = nodeName, let node = sceneUI.gameScene.childNode(withName: downName) {
                sceneUI.setNodeToMouseOffset(anchor: node.position)
            } else {
                sceneUI.setNodeToMouseOffset(anchor: CGPoint.zero)
            }
        }

        func mouseMove(at position: CGPoint) {
            updateDrawIndicator(at: position)
        }
        
        func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
            var updateIndicator = true

            if sceneUI.mouseState == .down {
                if let up = node {
                    updateIndicator = mouseUp_(on: up, at: position, flags: flags)
                } else {
                    updateIndicator = mouseUp_(at: position, flags: flags)
                }
            }
            
            if updateIndicator { updateDrawIndicator(at: position) }
        }
        
        func mouseUp_(on node: String, at position: CGPoint, flags: NSEvent.ModifierFlags?) -> Bool {
            var endOfDrag = false
            
            if let flags = flags, flags.contains(.command) {
                if sceneUI.mouseState == .down { // cmd+click on a node
                    sceneUI.toggleSelection(node)
                }
            } else if let (path, pathname) = sceneUI.getPathThatOwnsTouchedNode(node) {
                // Click on a path that isn't selected; select that path
                deselectAll()
                
                activePath = path
                select(pathname, primary: true)
            } else {
                if sceneUI.mouseState == .down {    // That is, we just clicked the node
                    deselectAll()
                    
                    select(node, primary: true)
                    
                    if let ap = activePath, node == ap.graphNodes[0].name, ap.graphNodes.count > 1 {
                     finalizePathIfOk()
                    }
                } else {                    // That is, we just finished dragging the node
                    endOfDrag = true
                    trackMouse(nodeName: node, atPoint: position)
                }
            }

            return endOfDrag
        }
        
        func mouseUp_(at position: CGPoint, flags: NSEvent.ModifierFlags?) -> Bool {
            // Clicked in the black; add a node
            deselectAll()
            
            var controlKey = false
            var optionKey = false
            if let flags = flags {
                controlKey = flags.contains(.control)
                optionKey = flags.contains(.option)
            }
            
            var addedANode = false
            if optionKey {
                addedANode = newPathIfOk()  // Start a new path if we aren't already in the middle of one
            } else if controlKey {
                sceneUI.stampObstacle()     // Stamp an obstacle, if there's something stampable
            } else {
                addedANode = addNodeIfOk(at: position)
            }

            return addedANode
        }
        
        func newPathIfOk() -> Bool {
            // Create a new path if we aren't already drawing one. If
            // we're already drawing, ignore the click
            guard activePath == nil else { return false }

            activePath = AFPath(gameScene: sceneUI.gameScene)
            
            // With a new path started, no other options are available
            // until the path is finalized. However, the "add path" option
            // is disabled until there are at least two nodes in the path.
            sceneUI.contextMenu.reset()
            sceneUI.contextMenu.includeInDisplay(.AddPathToLibrary, true, enable: false)
            
            addNodeToPath(at: sceneUI.currentPosition)
            return true
        }

        func select(_ index: Int, primary: Bool) {
            let entity = AFCore.data.entities[index]
            select(entity.name, primary: primary)
        }
        
        func select(_ name: String, primary: Bool) {
            activePath.select(name)
            sceneUI.selectedPath = activePath
            sceneUI.selectedNames.insert(name)
            
            if activePath.name == name {
                // Selecting the path as a whole
                sceneUI.contextMenu.includeInDisplay(.SetObstacleCloneStamp, true, enable: true)
            } else {
                // Selecting a node in a path
                sceneUI.contextMenu.includeInDisplay(.SetObstacleCloneStamp, false)
            }
        }
        
        func trackMouse(nodeName: String, atPoint: CGPoint) {
            let offset = sceneUI.nodeToMouseOffset
            
            if activePath.graphNodes.getIndexOf(nodeName) == nil {
                activePath.containerNode!.position = atPoint + offset
            } else {
                activePath.moveNode(node: nodeName, to: atPoint + offset)
            }
        }
        
        func updateDrawIndicator(at position: CGPoint) {
            if let drawIndicator = self.drawIndicator {
                drawIndicator.removeFromParent()
            }
            
            if let last = activePath?.graphNodes.last {
                let linePath = CGMutablePath()
                linePath.move(to: CGPoint(last.position))
                linePath.addLine(to: position)
                
                drawIndicator = SKShapeNode(path: linePath)
                sceneUI.gameScene.addChild(drawIndicator)
            }
        }

        override func willExit(to nextState: GKState) {
            if let drawIndicator = self.drawIndicator {
                drawIndicator.removeFromParent()
            }
        }
    }
}
