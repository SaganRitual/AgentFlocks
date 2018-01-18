//
// Created by Rob Bishop on 1/13/18
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

class AFSceneUI {
    var activePath: AFPath!     // The one we're doing stuff to, whether it's selected or not (like dragging handles)
    let contextMenu: AFContextMenu
    var currentPosition = CGPoint.zero
    var data: AFData!
    var downNodeName: String?
    var mouseState = MouseStates.up
    var nodeToMouseOffset = CGPoint.zero
    var obstacleCloneStamp = String()
    var parentOfNewMotivator: AFBehavior?
    var pathForNextPathGoal = 0
    var primarySelection: String?
    unowned let gameScene: GameScene
    var selectedNames = Set<String>()
    var selectedPath: AFPath!   // The one that has a visible selection indicator on it, if any
    var ui: AppDelegate
    var upNodeName: String?

    enum MouseStates { case down, dragging, rightDown, rightUp, up }

    init(gameScene: GameScene, ui: AppDelegate, contextMenu: AFContextMenu) {
        self.contextMenu = contextMenu
        self.gameScene = gameScene
        self.ui = ui
    }
    
    func deselect(_ name: String) {
        selectedNames.remove(name)
        if primarySelection == name || selectedNames.count == 0 {
            deselect_()
        }
    }
    
    func deselectAll() {
        selectedNames.removeAll()
        deselect_()
    }
    
    func deselect_() {
        contextMenu.includeInDisplay(.SetObstacleCloneStamp, false)
    }

    func finalizePath(close: Bool) {
        activePath.refresh(final: close) // Auto-add the closing line segment
        data.paths.append(key: activePath.name, value: activePath)

        contextMenu.includeInDisplay(.AddPathToLibrary, false)
        contextMenu.includeInDisplay(.Place, true, enable: true)
    }

    func getPathThatOwnsTouchedNode(_ name: String) -> (AFPath, String)? {
        for path in data.paths {
            if path.graphNodes.getIndexOf(name) != nil {
                return (path, name)
            }
        }
        
        if let obstacle = data.obstacles[name] {
            return (obstacle, name)
        }
        
        return nil
    }

    func getParentForNewMotivator() -> AFBehavior {
        if let p = parentOfNewMotivator { return p }
        else {
            let agentName = primarySelection!
            let entity = data.entities[agentName]
            return (entity.agent.behavior! as! GKCompositeBehavior)[0] as! AFBehavior
        }
    }

    func getPathThatOwnsNode(_ name: String) -> (AFPath, String)? {
        for path in data.paths {
            if path.graphNodes.getIndexOf(name) != nil {
                return (path, name)
            }
        }
                
        if let obstacle = data.obstacles[name] {
            return (obstacle, name)
        }

        return nil
    }

    func getPosition(ofNode name: String) -> CGPoint {
        if activePath.graphNodes.contains(name) {
            return activePath.graphNodes[name].sprite.position
        } else {
            return activePath.containerNode!.position
        }
    }
    
    func keyDown(mouseAt: CGPoint) {
        
    }
    
    func keyUp(mouseAt: CGPoint) {
        
    }
    
    func makeEntity(image: NSImage, position: CGPoint) -> AFEntity {
        return AFEntity(scene: gameScene, image: image, position: position)
    }
    
    func makeEntity(prototype: AFEntity_Script) -> AFEntity {
        return AFEntity(scene: gameScene, prototype: prototype)
    }
    
    func makeEntity(copyFrom: AFEntity, position: CGPoint) -> AFEntity {
        return AFEntity(scene: gameScene, copyFrom: copyFrom, position: position)
    }
    
    func makePath(prototype: AFPath_Script) -> AFPath {
        return AFPath(gameScene: gameScene, prototype: prototype)
    }
    
    func mouseDown(on node: String?, at position: CGPoint) {
        downNodeName = node   // Because the context menu needs to see it; change to notification?
        upNodeName = nil

        if let node = node {
            currentPosition = position
            let center = getPosition(ofNode: node)
            setNodeToMouseOffset(anchor: center)
        }
        mouseState = .down
    }
    
    func mouseDrag(on node: String?) {
        trackMouse(nodeName: node!, atPoint: currentPosition)
        mouseState = .dragging
    }
    
    func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
        upNodeName = node   // Because the context menu needs to see it; change to notification?
        downNodeName = nil
        
        if let up = node {
            if let flags = flags, flags.contains(.command) {
                if mouseState == .down { // cmd+click on a node
                    toggleSelection(up)
                }
            } else if let (path, pathname) = getPathThatOwnsTouchedNode(up) {
                // Click on a path that isn't selected; select that path
                deselectAll()
                
                activePath = path
                select(pathname, primary: true)
            } else {
                if mouseState == .down {    // That is, we just clicked the node
                    deselectAll()
                    
                    select(up, primary: true)
                    
                    if !activePath.finalized && up == activePath.graphNodes[0].name && activePath.graphNodes.count > 1 {
                        finalizePath(close: true)
                    }
                } else {                    // That is, we just finished dragging the node
                    trackMouse(nodeName: up, atPoint: currentPosition)
                }
            }
        } else {
            // Clicked in the black; add a node
            deselectAll()
            
            if let flags = flags, flags.contains(.control) {
                // Stamp an obstacle, if there's something stampable
                stampObstacle()
            } else {
                let startNewPath = (activePath == nil) || (activePath.finalized)
                if startNewPath {
                    activePath = AFPath(gameScene: gameScene)
                    
                    // With a new path started, no other options are available
                    // until the path is finalized. However, the "add path" option
                    // is disabled until there are at least two nodes in the path.
                    contextMenu.reset()
                    contextMenu.includeInDisplay(.AddPathToLibrary, true, enable: false)
                }
                
                let newNode = activePath.addGraphNode(at: currentPosition)
                select(newNode.name, primary: true)
                
                // With two or more nodes, we now have a path that can be
                // added to the library
                if activePath.graphNodes.count > 1 {
                    contextMenu.enableInDisplay(.AddPathToLibrary)
                }
            }
        }

        mouseState = .up
    }

    func place(at point: CGPoint) -> String {
        let imageIndex = AFCore.browserDelegate.agentImageIndex
        let image = ui.agents[imageIndex].image
        let newEntity = data.createEntity(image: image, position: point)
        
        return newEntity.name
    }

    func rightMouseDown(on node: String?) {
        downNodeName = node   // Because the context menu needs to see it; change to notification?
        upNodeName = nil
        mouseState = .rightDown
    }
    
    func rightMouseUp(on node: String?) {
        upNodeName = node   // Because the context menu needs to see it; change to notification?
        downNodeName = nil
        mouseState = .rightUp
    }
    
    func select(_ index: Int, primary: Bool) {
        let entity = data.entities[index]
        select(entity.name, primary: primary)
    }

    func select(_ name: String, primary: Bool) {
        activePath.select(name)
        selectedPath = activePath
        
        if activePath.name == name {
            // Selecting the path as a whole
            contextMenu.includeInDisplay(.SetObstacleCloneStamp, true, enable: true)
        } else {
            // Selecting a node in a path
            contextMenu.includeInDisplay(.SetObstacleCloneStamp, false)
        }
    }
    
    func setNodeToMouseOffset(anchor: CGPoint) {
        nodeToMouseOffset.x = anchor.x - currentPosition.x
        nodeToMouseOffset.y = anchor.y - currentPosition.y
    }

    func setObstacleCloneStamp() {
        obstacleCloneStamp = selectedPath.name
        
        contextMenu.includeInDisplay(.StampObstacle, true, enable: true)
    }
    
    func stampObstacle() {
        deselectAll()

        let offset = currentPosition - CGPoint(activePath.graphNodes[0].position)
        let newPath = AFPath.init(gameScene: gameScene, copyFrom: activePath, offset: offset)

        newPath.stampObstacle()
        data.obstacles[newPath.name] = newPath
        select(newPath.name, primary: true)
    }

    func toggleSelection(_ name: String) {
        if selectedNames.contains(name) { deselect(name) }
        else { select(name, primary: primarySelection == nil) }
    }
    
    func trackMouse(nodeName: String, atPoint: CGPoint) {
        let offset = nodeToMouseOffset
        
        if activePath.graphNodes.getIndexOf(nodeName) == nil {
            activePath.containerNode!.position = atPoint + offset
        } else {
            activePath.moveNode(node: nodeName, to: atPoint + offset)
        }
    }

    func updatePrimarySelectionState(agentName: String?) {
        var agent: AFAgent2D?
        
        if let agentName = agentName {
            agent = data.entities[agentName].agent
        }
        
        ui.changePrimarySelectionState(selectedAgent: agent)
    }
}

