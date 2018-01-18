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

protocol EditModeRelay {
    func deselect(_ name: String)
    func getParentStateMachine() -> AFInputState
    func getPosition(ofNode name: String) -> CGPoint
    func getTouchedNode(touchedNodes: [SKNode]) -> SKNode?
    func keyDown(with event: NSEvent)
    func keyUp(with event: NSEvent)
    func mouseDown(with event: NSEvent)
    func mouseDragged(with event: NSEvent)
    func mouseUp(with event: NSEvent)
    func rightMouseDown(with event: NSEvent)
    func rightMouseUp(with event: NSEvent)
    func select(_ name: String, primary: Bool)
    func trackMouse(nodeName: String, atPoint: CGPoint)
}

// Empty default functions so the states don't have to be cluttered with them
extension EditModeRelay {
    func getParentStateMachine() -> AFInputState { return ((self as! GKState).stateMachine) as! AFInputState }
    func keyDown(with event: NSEvent) {}
    func keyUp(with event: NSEvent) {}
    func mouseDown(with event: NSEvent) {}
    func mouseDragged(with event: NSEvent) {}
    func mouseUp(with event: NSEvent) {}
    func rightMouseDown(with event: NSEvent) {}
    func rightMouseUp(with event: NSEvent) {}
    func trackMouse(nodeName: String, atPoint: CGPoint) {}
}

class AFInputState: GKStateMachine {
    let contextMenu: AFContextMenu
    var currentPosition = CGPoint.zero
    var data: AFData!
    var downNodeName: String?
    var nodeToMouseOffset = CGPoint.zero
    var parentOfNewMotivator: AFBehavior?
    var pathForNextPathGoal = 0
    var primarySelection: String?
    unowned let gameScene: GameScene
    var mouseState = MouseStates.up
    var selectedNames = Set<String>()
    var touchedNodes = [SKNode]()
    var ui: AppDelegate
    var upNodeName: String?
    
    enum MouseStates { case down, dragging, rightDown, rightUp, up }

    init(gameScene: GameScene, ui: AppDelegate, contextMenu: AFContextMenu) {
        self.contextMenu = contextMenu
        self.gameScene = gameScene
        self.ui = ui
        
        super.init(states: [ ModeDraw(), ModePlace() ])
        
        enter(ModePlace.self)
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
        if let cs = currentState as? ModeDraw {
            cs.finalizePath(close: close)
            
            contextMenu.includeInDisplay(.AddPathToLibrary, false)
            
            contextMenu.includeInDisplay(.Place, true, enable: true)
        } else {
            fatalError()
        }
    }
    
    func getInputRelay() -> EditModeRelay? {
        if currentState == nil { return nil }
        else { return currentState! as? EditModeRelay }
    }
    
    func getParentForNewMotivator() -> AFBehavior {
        if let p = parentOfNewMotivator { return p }
        else {
            let agentName = getPrimarySelectionName()!
            let entity = data.entities[agentName]
            return (entity.agent.behavior! as! GKCompositeBehavior)[0] as! AFBehavior
        }
    }

    func getPathThatOwnsTouchedNode() -> (AFPath, String)? {
        touchedNodes = gameScene.nodes(at: currentPosition)
        
        for skNode in touchedNodes.reversed() {
            if let name = skNode.name {
                for path in data.paths {
                    if path.graphNodes.getIndexOf(name) != nil {
                        return (path, name)
                    }
                }
                
                if let obstacle = data.obstacles[name] {
                    return (obstacle, name)
                }
            }
        }
        
        return nil
    }
    
    func getPrimarySelectionName() -> String? {
        return primarySelection
    }

    func getSelectedNames() -> Set<String> {
        return selectedNames
    }
    
    func getTouchedNode() -> SKNode? {
        touchedNodes = gameScene.nodes(at: currentPosition)
        return getInputRelay()?.getTouchedNode(touchedNodes: touchedNodes)
    }
    
    func getTouchedNodeName() -> String? {
        if let node = getTouchedNode() {
            return node.name
        } else {
            return nil
        }
    }
    
    func keyDown(with event: NSEvent) { }
    
    func keyUp(with event: NSEvent) {
        getInputRelay()?.keyUp(with: event)
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

    func mouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNodeName = getTouchedNodeName()
        
        if let down = downNodeName {
            let p = getInputRelay()!.getPosition(ofNode: down)
            setNodeToMouseOffset(anchor: p)
        } else {
            setNodeToMouseOffset(anchor: CGPoint.zero)
        }

        getInputRelay()?.mouseDown(with: event)

        upNodeName = nil
        mouseState = .down
    }

    func mouseDragged(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)

        mouseState = .dragging
        
        if let down = downNodeName {
            getInputRelay()?.trackMouse(nodeName: down, atPoint: currentPosition)
        }

        getInputRelay()?.mouseDragged(with: event)
    }
    
    func mouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeName = getTouchedNodeName()
        
        getInputRelay()?.mouseUp(with: event)

        downNodeName = nil
        mouseState = .up
    }

    func rightMouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeName = getTouchedNodeName()

        getInputRelay()?.rightMouseDown(with: event)

        downNodeName = nil
        mouseState = .rightDown
    }

    func rightMouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeName = getTouchedNodeName()

        getInputRelay()?.rightMouseUp(with: event)

        downNodeName = nil
        mouseState = .rightUp
    }

    func select(_ name: String, primary: Bool) {
        selectedNames.insert(name)
        if primary { primarySelection = name }
    }
    
    func setNodeToMouseOffset(anchor: CGPoint) {
        nodeToMouseOffset.x = anchor.x - currentPosition.x
        nodeToMouseOffset.y = anchor.y - currentPosition.y
    }

    func setObstacleCloneStamp() { (currentState! as! ModeDraw).setObstacleCloneStamp() }
    func stampObstacle() { (currentState! as! ModeDraw).stampObstacle(at: currentPosition) }
    
    func toggleSelection(_ name: String) {
        if selectedNames.contains(name) { getInputRelay()?.deselect(name) }
        else { getInputRelay()?.select(name, primary: primarySelection == nil) }
    }

    func updatePrimarySelectionState(agentName: String?) {
        var agent: AFAgent2D?
        
        if let agentName = agentName {
            agent = data.entities[agentName].agent
        }
        
        ui.changePrimarySelectionState(selectedAgent: agent)
    }
}

