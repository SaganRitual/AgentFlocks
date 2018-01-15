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

class AFCore {
    static var browserDelegate: AFBrowserDelegate!
    static var inputState: AFInputState!
    
    static func makeCore(gameScene: GameScene) {
        inputState = AFInputState(gameScene: gameScene)
        browserDelegate = AFBrowserDelegate(inputState)
    }
}

class AFInputState: GKStateMachine {
    var currentPosition = CGPoint.zero
    var downNodeName: String?
    var nodeToMouseOffset = CGPoint.zero
    var primarySelectionName: String?
    unowned let gameScene: GameScene
    var mouseState = MouseStates.up
    var selectedNames = Set<String>()
    var touchedNodes = [SKNode]()
    var upNodeName: String?
    
    enum MouseStates { case down, dragging, rightDown, rightUp, up }

    init(gameScene: GameScene) {
        self.gameScene = gameScene
        
        super.init(states: [ ModeDraw(), ModePlace() ])
        
        enter(ModePlace.self)
    }
    
    func finalizePath(close: Bool) {
        if let cs = currentState as? ModeDraw {
            cs.finalizePath(close: close)
            
            AFContextMenu.includeInDisplay(.AddPathToLibrary, false)
            
            AFContextMenu.includeInDisplay(.Place, true, enable: true)
        } else {
            fatalError()
        }
    }
    
    func getInputRelay() -> EditModeRelay? {
        if currentState == nil { return nil }
        else { return currentState! as? EditModeRelay }
    }
    
    func getPathThatOwnsTouchedNode() -> (AFPath, String)? {
        touchedNodes = gameScene.nodes(at: currentPosition)
        
        for skNode in touchedNodes.reversed() {
            if let name = skNode.name {
                for path in gameScene.paths {
                    if path.graphNodes.getIndexOf(name) != nil {
                        return (path, name)
                    }
                }
                
                if let obstacle = gameScene.obstacles[name] {
                    return (obstacle, name)
                }
            }
        }
        
        return nil
    }
    
    func getPrimarySelectionName() -> String? {
        return primarySelectionName
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
    
    func setNodeToMouseOffset(anchor: CGPoint) {
        nodeToMouseOffset.x = anchor.x - currentPosition.x
        nodeToMouseOffset.y = anchor.y - currentPosition.y
    }

    func setObstacleCloneStamp() { (currentState! as! ModeDraw).setObstacleCloneStamp() }
    func stampObstacle(at point: CGPoint) { (currentState! as! ModeDraw).stampObstacle(at: point) }
}

extension AFInputState {

    class ModeDraw: GKState, EditModeRelay {
        var activePath: AFPath!
        var namesOfSelectedScenoids = [String]()
        var obstacleCloneStamp: String?
        var selectedPath: AFPath!

        func deselectAll() {
            activePath?.deselectAll()
            namesOfSelectedScenoids.removeAll()
            
            selectedPath = nil

            AFContextMenu.includeInDisplay(.SetObstacleCloneStamp, false)
        }
        
        override func didEnter(from previousState: GKState?) {
            AFContextMenu.reset()
            AFContextMenu.includeInDisplay(.Place, true)
            AFContextMenu.enableInDisplay(.Place, true)
        }

        func finalizePath(close: Bool) {
            activePath.refresh(final: close) // Auto-add the closing line segment
            getParentStateMachine().gameScene.paths.append(key: activePath.name, value: activePath)
            
            AFContextMenu.includeInDisplay(.SetObstacleCloneStamp, true, enable: true)
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
            var paths = psm.gameScene.paths
            
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

            for (_, afPath) in psm.gameScene.obstacles {
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
                namesOfSelectedScenoids.forEach { activePath.remove(node: $0) }
                
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
                    let p = CGPoint(path.graphNodes[down].position)
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
                if psm.mouseState == .down {    // That is, we just clicked the node
                    deselectAll()
                    
                    select(up, primary: true)
                    
                    if !activePath.finalized && up == activePath.graphNodes[0].name && activePath.graphNodes.count > 1 {
                        psm.finalizePath(close: true)
                    }
                } else {                    // That is, we just finished dragging the node
                    trackMouse(nodeName: up, atPoint: psm.currentPosition)
                    
//                    if afPath.name != up {
//                        afPath.moveNode(node: up, to: psm.currentPosition)
//                    }
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

                    let startNewPath = (activePath == nil) || (activePath.finalized)
                    if startNewPath {
                        activePath = AFPath()
                        
                        // With a new path started, no other options are available
                        // until the path is finalized. However, the "add path" option
                        // is disabled until there are at least two nodes in the path.
                        AFContextMenu.reset()
                        AFContextMenu.includeInDisplay(.AddPathToLibrary, true, enable: false)
                    }
                    
                    let newNode = activePath.addGraphNode(at: psm.currentPosition)
                    select(newNode.name, primary: true)
                    
                    // With two or more nodes, we now have a path that can be
                    // added to the library
                    if activePath.graphNodes.count > 1 {
                        AFContextMenu.enableInDisplay(.AddPathToLibrary)
                    }
                }
            }
        }
        
        func rightMouseUp(with event: NSEvent) {
            AFContextMenu.show(at: event.locationInWindow)
        }

        func select(_ name: String, primary: Bool) {
            if primary { getParentStateMachine().primarySelectionName = name }
            
            namesOfSelectedScenoids.append(name)
            
            activePath.select(name)
            selectedPath = activePath
            
            if activePath.name == name {
                // Selecting the path as a whole
                AFContextMenu.includeInDisplay(.SetObstacleCloneStamp, true, enable: true)
            } else {
                // Selecting a node in a path
                AFContextMenu.includeInDisplay(.SetObstacleCloneStamp, false)
            }
        }
        
        func setObstacleCloneStamp() {
            obstacleCloneStamp = selectedPath.name
            
            AFContextMenu.includeInDisplay(.StampObstacle, true, enable: true)
        }
        
        func stampObstacle(at point: CGPoint) {
            deselectAll()
            let offset = point - CGPoint(activePath.graphNodes[0].position)
            let newPath = AFPath.init(copyFrom: activePath, offset: offset)
            newPath.stampObstacle()
            getParentStateMachine().gameScene.obstacles[newPath.name] = newPath
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

extension AFInputState {
    
    class ModePlace: GKState, EditModeRelay {
        
        func deselect(_ name: String) {
            let psm = getParentStateMachine()

            psm.gameScene.entities[name].agent.deselect()
            psm.selectedNames.remove(name)
            
            // We just now deselected the primary. If there's anyone
            // else selected, they need to be made the primary.
            if psm.primarySelectionName == name {
                if psm.selectedNames.count > 0 {
                    let selectNew = psm.selectedNames.first!
                    select(selectNew, primary: true)
                    AppDelegate.me!.placeAgentFrames(agentName: selectNew)
                } else {
                    psm.primarySelectionName = nil
                    AppDelegate.me!.removeAgentFrames()
                }
            }
            
            AFContextMenu.includeInDisplay(.CloneAgent, false)
        }

        func deselectAll() {
            let psm = getParentStateMachine()
            
            psm.gameScene.entities.forEach{ $0.agent.deselect() }
            
            psm.selectedNames.removeAll()
            psm.primarySelectionName = nil

            // Turn off the agent attributes and goals edit views
            AppDelegate.me!.removeAgentFrames()
            
            // Clear out the sliders so they'll recalibrate themselves to the new values
            AppDelegate.agentEditorController.attributesController.resetSliderControllers()
            
            AFContextMenu.includeInDisplay(.CloneAgent, false)
        }
        
        override func didEnter(from previousState: GKState?) {
            AFContextMenu.reset()
            AFContextMenu.includeInDisplay(.Draw, true)
            AFContextMenu.enableInDisplay(.Draw, true)
        }
        
        func getPosition(ofNode name: String) -> CGPoint {
            return getParentStateMachine().gameScene.entities[name].agent.spriteContainer.position
        }

        func getTouchedNode(touchedNodes: [SKNode]) -> SKNode? {
            let psm = getParentStateMachine()
            
            // Find the last descendant; I think that will be the top one
            for entity in psm.gameScene.entities.reversed() {
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

        func mouseUp(with event: NSEvent) {
            let psm = getParentStateMachine()

            if psm.upNodeName == nil {
                // Mouse up in the black; always a full deselect
                deselectAll()
                
                var newEntity: AFEntity!
                
                if event.modifierFlags.contains(.control) {
                    // ctrl-click gives a clone of the last guy, goals and all
                    guard psm.gameScene.entities.count > 0 else { return }
                    
                    let originalIx = psm.gameScene.entities.count - 1
                    let originalEntity = psm.gameScene.entities[originalIx]
                    
                    newEntity = AFEntity(scene: psm.gameScene, copyFrom: originalEntity, position: psm.currentPosition)
                    _ = AppDelegate.me!.sceneController.addNode(entity: newEntity)
                } else {
                    let imageIndex = AFCore.browserDelegate.agentImageIndex
                    let image = AppDelegate.me!.agents[imageIndex].image
                    newEntity = AppDelegate.me!.sceneController.addNode(image: image, at: psm.currentPosition)
                }
                
                select(newEntity.name, primary: true)
                
                AppDelegate.me!.placeAgentFrames(agentName: newEntity.name)
            } else {
                if event.modifierFlags.contains(.command) {
                    if psm.mouseState == .down { // cmd+click on a node
                        toggleSelection(psm.upNodeName!)
                    }
                } else {
                    if psm.mouseState == .down {    // That is, we're coming out of down as opposed to drag
                        let setSelection = (psm.primarySelectionName != psm.upNodeName!)
                        
                        deselectAll()
                        
                        if setSelection {
                            select(psm.upNodeName!, primary: true)
                        }
                    }
                }
            }
        }
        
        func rightMouseUp(with event: NSEvent) {
            AFContextMenu.show(at: event.locationInWindow)
        }
        
        func select(_ index: Int, primary: Bool) {
            let psm = getParentStateMachine()
            let entity = psm.gameScene.entities[index]
            select(entity.name, primary: primary)
        }
        
        func select(_ name: String, primary: Bool) {
            let psm = getParentStateMachine()

            psm.selectedNames.insert(name)
            psm.gameScene.entities[name].agent.select(primary: primary)
            
            if primary {
                AppDelegate.agentEditorController.goalsController.dataSource = psm.gameScene.entities[name]
                AppDelegate.agentEditorController.attributesController.delegate = psm.gameScene.entities[name].agent
                
                psm.primarySelectionName = name
                AppDelegate.me!.placeAgentFrames(agentName: name)
            }
            
            AFContextMenu.includeInDisplay(.CloneAgent, true, enable: true)
        }
        
        func toggleSelection(_ name: String) {
            let psm = getParentStateMachine()

            if psm.selectedNames.contains(name) { deselect(name) }
            else { select(name, primary: psm.primarySelectionName == nil) }
        }
        
        func trackMouse(nodeName: String, atPoint: CGPoint) {
            let psm = getParentStateMachine()
            let offset = psm.nodeToMouseOffset
            let agent = psm.gameScene.entities[nodeName].agent
            
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
