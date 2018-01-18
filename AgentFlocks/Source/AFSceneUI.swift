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
    private let contextMenu: AFContextMenu
    var currentPosition = CGPoint.zero
    var data: AFData!
    var mouseState = MouseStates.up
    var nodeToMouseOffset = CGPoint.zero
    var obstacleCloneStamp = String()
    var parentOfNewMotivator: AFBehavior?
    var pathForNextPathGoal = 0
    var primarySelection: String?
    unowned let gameScene: GameScene
    var selectedNames = Set<String>()
    var selectedPath: AFPath!   // The one that has a visible selection indicator on it, if any
    fileprivate var stateMachine: AFSceneUI.StateMachine!    // Because the type is private
    var ui: AppDelegate
    var upNodeName: String?

    enum MouseStates { case down, dragging, rightDown, rightUp, up }

    init(gameScene: GameScene, ui: AppDelegate, contextMenu: AFContextMenu) {
        self.contextMenu = contextMenu
        self.gameScene = gameScene
        self.ui = ui
        
        stateMachine = StateMachine(sceneUI: self)
    }
    
    func cloneAgent() {
        let originalEntity = data.entities[upNodeName!]
        
        _ = makeEntity(copyFrom: originalEntity, position: currentPosition)
    }
    
    func finalizePath(close: Bool) {
        stateMachine.drone.finalizePath(close: close)
    }
    
    /*
    func deselect(_ name: String) {
        let psm = getParentStateMachine()
        
        psm.data.entities[name].agent.deselect()
        psm.selectedNames.remove(name)
        
        // We just now deselected the primary. If there's anyone
        // else selected, they need to be made the primary.
        if psm.primarySelection == name {
            var selectNew: String?
            
            if psm.selectedNames.count > 0 {
                selectNew = psm.selectedNames.first!
                select(selectNew!, primary: true)
            } else {
                psm.primarySelection = nil
            }
            
            psm.updatePrimarySelectionState(agentName: selectNew)
        }
        
        psm.contextMenu.includeInDisplay(.CloneAgent, false)
    }*/

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
        if let node = node {
            currentPosition = position
            let center = getPosition(ofNode: node)
            setNodeToMouseOffset(anchor: center)
        }
        mouseState = .down
        upNodeName = nil
    }
    
    func mouseDrag(on node: String?, at position: CGPoint) {
        trackMouse(nodeName: node!, atPoint: position)
        mouseState = .dragging
    }
    
    func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
        upNodeName = node
        currentPosition = position
        stateMachine.mouseUp(on: node, at: position, flags: flags)
        mouseState = .up
    }

    func place(at point: CGPoint) -> String {
        let imageIndex = AFCore.browserDelegate.agentImageIndex
        let image = ui.agents[imageIndex].image
        let newEntity = data.createEntity(image: image, position: point)
        
        return newEntity.name
    }

    func rightMouseDown(on node: String?) {
        upNodeName = nil
        mouseState = .rightDown
    }
    
    func rightMouseUp(on node: String?) {
        upNodeName = node
        mouseState = .rightUp
    }
    
    func select(_ imageIndex: Int, primary: Bool) {
        stateMachine.drone.select(imageIndex, primary: primary)
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
        stateMachine.drone.deselectAll()

        let offset = currentPosition - CGPoint(activePath.graphNodes[0].position)
        let newPath = AFPath.init(gameScene: gameScene, copyFrom: activePath, offset: offset)

        newPath.stampObstacle()
        data.obstacles[newPath.name] = newPath
        stateMachine.drone.select(newPath.name, primary: true)
    }

    func toggleSelection(_ name: String) {
        if selectedNames.contains(name) { stateMachine.drone.deselect(name) }
        else { stateMachine.drone.select(name, primary: primarySelection == nil) }
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

protocol AFSceneDrone {
    func deselect(_ name: String)
    func deselectAll()
    func finalizePath(close: Bool)
    func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?)
    func select(_ name: String, primary: Bool)
    func select(_ imageIndex: Int, primary: Bool)
}

private extension AFSceneUI {
    
    class StateMachine: GKStateMachine {
        let sceneUI: AFSceneUI
        
        var drone: AFSceneDrone { set{} get { return currentState! as! AFSceneDrone } }
        
        init(sceneUI: AFSceneUI) {
            self.sceneUI = sceneUI
            
            super.init(states: [ Draw(sceneUI), Standard(sceneUI) ])
            
            enter(Standard.self)
        }
        
        func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
            drone.mouseUp(on: node, at: position, flags: flags)
        }
    }
    
    class Draw: GKState, AFSceneDrone {
        var activePath: AFPath!
        let sceneUI: AFSceneUI

        init(_ sceneUI: AFSceneUI) {
            self.sceneUI = sceneUI
        }

        func deselect(_ name: String) {
            sceneUI.selectedNames.remove(name)
            if sceneUI.primarySelection == name || sceneUI.selectedNames.count == 0 {
                deselect_()
            }
        }
        
        func deselectAll() {
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
        }

        func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
            if let up = node {
                if let flags = flags, flags.contains(.command) {
                    if sceneUI.mouseState == .down { // cmd+click on a node
                        sceneUI.toggleSelection(up)
                    }
                } else if let (path, pathname) = sceneUI.getPathThatOwnsTouchedNode(up) {
                    // Click on a path that isn't selected; select that path
                    deselectAll()
                    
                    activePath = path
                    select(pathname, primary: true)
                } else {
                    if sceneUI.mouseState == .down {    // That is, we just clicked the node
                        deselectAll()
                        
                        select(up, primary: true)
                        
                        if !activePath.finalized && up == activePath.graphNodes[0].name && activePath.graphNodes.count > 1 {
                            finalizePath(close: true)
                        }
                    } else {                    // That is, we just finished dragging the node
                        sceneUI.trackMouse(nodeName: up, atPoint: position)
                    }
                }
            } else {
                // Clicked in the black; add a node
                deselectAll()
                
                if let flags = flags, flags.contains(.control) {
                    // Stamp an obstacle, if there's something stampable
                    sceneUI.stampObstacle()
                } else {
                    let startNewPath = (activePath == nil) || (activePath.finalized)
                    if startNewPath {
                        activePath = AFPath(gameScene: sceneUI.gameScene)
                        
                        // With a new path started, no other options are available
                        // until the path is finalized. However, the "add path" option
                        // is disabled until there are at least two nodes in the path.
                        sceneUI.contextMenu.reset()
                        sceneUI.contextMenu.includeInDisplay(.AddPathToLibrary, true, enable: false)
                    }
                    
                    let newNode = activePath.addGraphNode(at: position)
                    select(newNode.name, primary: true)
                    
                    // With two or more nodes, we now have a path that can be
                    // added to the library
                    if activePath.graphNodes.count > 1 {
                        sceneUI.contextMenu.enableInDisplay(.AddPathToLibrary)
                    }
                }
            }
        }
        
        func select(_ index: Int, primary: Bool) {
            let entity = AFCore.data.entities[index]
            select(entity.name, primary: primary)
        }
        
        func select(_ name: String, primary: Bool) {
            activePath.select(name)
            sceneUI.selectedPath = activePath
            
            if activePath.name == name {
                // Selecting the path as a whole
                sceneUI.contextMenu.includeInDisplay(.SetObstacleCloneStamp, true, enable: true)
            } else {
                // Selecting a node in a path
                sceneUI.contextMenu.includeInDisplay(.SetObstacleCloneStamp, false)
            }
        }

    }
    
    class Standard: GKState, AFSceneDrone {
        let sceneUI: AFSceneUI
        
        init(_ sceneUI: AFSceneUI) {
            self.sceneUI = sceneUI
        }
        
        func deselect(_ name: String) {
            sceneUI.data.entities[name].agent.deselect()
            sceneUI.selectedNames.remove(name)
            
            // We just now deselected the primary. If there's anyone
            // else selected, they need to be made the primary.
            if sceneUI.primarySelection == name {
                var selectNew: String?
                
                if sceneUI.selectedNames.count > 0 {
                    selectNew = sceneUI.selectedNames.first!
                    select(selectNew!, primary: true)
                } else {
                    sceneUI.primarySelection = nil
                }
                
                sceneUI.updatePrimarySelectionState(agentName: selectNew)
            }
            
            sceneUI.contextMenu.includeInDisplay(.CloneAgent, false)
        }
            
        func deselectAll() {
            sceneUI.data.entities.forEach{ $0.agent.deselect() }
            
            // Ugliness; this stuff should be in inputState
            sceneUI.selectedNames.removeAll()
            sceneUI.primarySelection = nil
            sceneUI.updatePrimarySelectionState(agentName: nil)
            
            sceneUI.contextMenu.includeInDisplay(.CloneAgent, false)
        }
        
        override func didEnter(from previousState: GKState?) {
            sceneUI.contextMenu.reset()
            sceneUI.contextMenu.includeInDisplay(.Draw, true)
            sceneUI.contextMenu.enableInDisplay(.Draw, true)
        }
        
        func finalizePath(close: Bool) {}

        func getPosition(ofNode name: String) -> CGPoint {
            return sceneUI.data.entities[name].agent.spriteContainer.position
        }
        
        func getTouchedNode(touchedNodes: [SKNode]) -> SKNode? {
            // Find the last descendant; I think that will be the top one
            for entity in sceneUI.data.entities.reversed() {
                if touchedNodes.contains(entity.agent.sprite) {
                    return entity.agent.sprite
                }
            }
            
            return nil
        }
        
        func keyUp(with event: NSEvent) {
            if event.keyCode == AFKeyCodes.escape.rawValue {
                deselectAll()
            }
        }
        
        func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
            if sceneUI.upNodeName == nil {
                // Mouse up in the black; always a full deselect
                deselectAll()
                
                var newEntity: AFEntity!
                
                if let flags = flags, flags.contains(.control) {
                    // ctrl-click gives a clone of the last guy, goals and all
                    guard sceneUI.data.entities.count > 0 else { return }
                    
                    let originalIx = sceneUI.data.entities.count - 1
                    let originalEntity = sceneUI.data.entities[originalIx]
                    
                    newEntity = sceneUI.data.createEntity(copyFrom: originalEntity, position: position)
                } else {
                    let imageIndex = AFCore.browserDelegate.agentImageIndex
                    let image = sceneUI.ui.agents[imageIndex].image
                    newEntity = sceneUI.data.createEntity(image: image, position: position)
                }
                
                select(newEntity.name, primary: true)
                sceneUI.updatePrimarySelectionState(agentName: newEntity.name)
            } else {
                if let flags = flags, flags.contains(.command) {
                    if sceneUI.mouseState == .down { // cmd+click on a node
                        sceneUI.toggleSelection(sceneUI.upNodeName!)
                    }
                } else {
                    if sceneUI.mouseState == .down {    // That is, we're coming out of down as opposed to drag
                        let setSelection = (sceneUI.primarySelection != sceneUI.upNodeName!)
                        
                        deselectAll()
                        
                        if setSelection {
                            select(sceneUI.upNodeName!, primary: true)
                        }
                    }
                }
            }
        }
        
        func rightMouseUp(with event: NSEvent) {
            sceneUI.contextMenu.show(at: event.locationInWindow)
        }
        
        func select(_ index: Int, primary: Bool) {
            let entity = sceneUI.data.entities[index]
            select(entity.name, primary: primary)
        }
        
        func select(_ name: String, primary: Bool) {
            sceneUI.selectedNames.insert(name)
            
            let entity = sceneUI.data.entities[name]
            entity.agent.select(primary: primary)
            
            if primary {
                AFCore.ui.agentEditorController.goalsController.dataSource = entity
                AFCore.ui.agentEditorController.attributesController.delegate = entity.agent
                
                sceneUI.primarySelection = name // Ugliness; move this into inputState
                sceneUI.updatePrimarySelectionState(agentName: name)
            }
            
            sceneUI.contextMenu.includeInDisplay(.CloneAgent, true, enable: true)
        }
        
        func trackMouse(nodeName: String, atPoint: CGPoint) {
            let offset = sceneUI.nodeToMouseOffset
            let agent = sceneUI.data.entities[nodeName].agent
            
            agent.position = vector_float2(Float(atPoint.x), Float(atPoint.y))
            agent.position.x += Float(offset.x)
            agent.position.y += Float(offset.y)
            agent.update(deltaTime: 0)
        }
        
        override func willExit(to nextState: GKState) {
            deselectAll()
        }
    }
}

