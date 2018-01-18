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
    var stateMachine: AFSceneUI.StateMachine!
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
    
    func mouseDown(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
        downNodeName = node
        currentPosition = position
        stateMachine.mouseDown(on: node, at: position, flags: flags)
        mouseState = .down
        upNodeName = nil
    }
    
    func mouseDrag(on node: String?, at position: CGPoint) {
        if let node = node {
            stateMachine.drone.trackMouse(nodeName: node, atPoint: position)
        }
        mouseState = .dragging
    }
    
    func mouseMove(at position: CGPoint) {
        stateMachine.mouseMove(at: position)
    }
    
    func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
        upNodeName = node
        currentPosition = position
        stateMachine.mouseUp(on: node, at: position, flags: flags)
        mouseState = .up
        downNodeName = nil
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
    func getPosition(ofNode name: String) -> CGPoint
    func mouseDown(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?)
    func mouseMove(at position: CGPoint)
    func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?)
    func select(_ name: String, primary: Bool)
    func select(_ imageIndex: Int, primary: Bool)
    func trackMouse(nodeName: String, atPoint: CGPoint)
}

extension AFSceneUI {
    
    class StateMachine: GKStateMachine {
        let sceneUI: AFSceneUI
        
        var drone: AFSceneDrone { set{} get { return currentState! as! AFSceneDrone } }
        
        init(sceneUI: AFSceneUI) {
            self.sceneUI = sceneUI
            
            super.init(states: [ Draw(sceneUI), Default(sceneUI) ])
            
            enter(Default.self)
        }
        
        func mouseDown(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
            drone.mouseDown(on: node, at: position, flags: flags)
        }

        func mouseMove(at position: CGPoint) {
            drone.mouseMove(at: position)
        }
        
        func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
            drone.mouseUp(on: node, at: position, flags: flags)
        }
    }
}

