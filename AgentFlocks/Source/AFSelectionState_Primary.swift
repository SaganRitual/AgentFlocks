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

protocol AFScenoid {
    func select(primary: Bool)
}

protocol AFSelectionState {
    func deselectAll()
    func getPrimarySelectionName() -> String?
    func getSelectedNames() -> Set<String>
    func getSelectedScenoids() -> [AFScenoid]
    func keyDown(with event: NSEvent)
    func keyUp(with event: NSEvent)
    func mouseDown(with event: NSEvent)
    func mouseDragged(with event: NSEvent)
    func mouseUp(with event: NSEvent)
	func rightMouseDown(with event: NSEvent)
	func rightMouseUp(with event: NSEvent)
    func newAgent(_ name: String)
    func select(_ name: String, primary: Bool)
}

class AFSelectionState_Primary: AFSelectionState {
    unowned let gameScene: GameScene

    var currentPosition: CGPoint?
    var downNodeName: String?
    var mouseState = MouseStates.up
    var mouseWasDragged = false
    var nodeToMouseOffset = CGPoint.zero
    var primarySelectionName: String?
    var selectedNames = Set<String>()
    var touchedNodes = [SKNode]()
    var upNodeName: String?

    init(gameScene: GameScene) {
        self.gameScene = gameScene
    }

    enum InputMode { case primary, drawPath }
    enum MouseStates { case down, dragging, rightDown, rightUp, up }
    
    func deselect(_ name: String) {
        gameScene.entities[name].agent.deselect()
        selectedNames.remove(name)
        
        // We just now deselected the primary. If there's anyone
        // else selected, they need to be made the primary.
        if primarySelectionName == name {
            if selectedNames.count > 0 {
                let selectNew = selectedNames.first!
                select(selectNew, primary: true)
                AppDelegate.me!.placeAgentFrames(agentName: selectNew)
            } else {
                primarySelectionName = nil
                AppDelegate.me!.removeAgentFrames()
            }
        }
    }
    
    func deselectAll() {
        for i in 0 ..< GameScene.me!.entities.count {
            let entity = GameScene.me!.entities[i]
            entity.agent.deselect()
        }
        
        selectedNames.removeAll()
        primarySelectionName = nil
        AppDelegate.me!.removeAgentFrames()

        // Clear out the sliders so they'll recalibrate themselves to the new values
        AppDelegate.agentEditorController.attributesController.resetSliderControllers()
    }
    
    func getAgent(name: String) -> AFAgent2D {
        let entity = gameScene.entities[name]
        return entity.agent
    }
    
    func getNode(at point: CGPoint) -> Int? {
        var nodeIndex: Int?
        
        for i in 0 ..< GameScene.me!.entities.count {
            let entity = GameScene.me!.entities[i]
            if touchedNodes.contains(entity.agent.spriteContainer) {
                nodeIndex = i
                break
            }
        }
        
        return nodeIndex
    }
    
    func getPrimarySelectionName() -> String? {
        return primarySelectionName
    }
    
    func getSelectedScenoids() -> [AFScenoid] {
        var agents = [AFAgent2D]()
        
        let names = getSelectedNames()
        for name in names {
            agents.append(gameScene.entities[name].agent)
        }
        
        return agents
    }
    
    func getSelectedNames() -> Set<String> {
        return selectedNames
    }
    
    func getTouchedNode() -> SKNode? {
        touchedNodes = gameScene.nodes(at: currentPosition!)
        
        // Find the last descendant; I think that will be the top one
        for i in stride(from: gameScene.entities.count - 1, through: 0, by: -1) {
            let entity = gameScene.entities[i]
            
            if touchedNodes.contains(entity.agent.sprite) {
                return entity.agent.sprite
            }
        }

        return nil
    }
    
    func getTouchedNodeName() -> String? {
        if let agentNode = getTouchedNode() {
            return agentNode.name
        } else {
            return nil
        }
    }

    func keyDown(with event: NSEvent) {
        print("keyDown in primary")
    }
    
    func keyUp(with event: NSEvent) {
        if event.keyCode == AFKeyCodes.escape.rawValue {
            deselectAll()
        }
    }
    
    func mouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNodeName = getTouchedNodeName()
        upNodeName = nil
        
        mouseState = .down
        
        if let down = downNodeName {
            let p = gameScene.entities[down].agent.spriteContainer.position
            nodeToMouseOffset.x = p.x - currentPosition!.x
            nodeToMouseOffset.y = p.y - currentPosition!.y
        } else {
            nodeToMouseOffset.x = -currentPosition!.x
            nodeToMouseOffset.y = -currentPosition!.y
        }
    }
    
    func mouseDragged(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        mouseState = .dragging
        
        if let d = downNodeName, let c = currentPosition {
            trackMouse(nodeName: d, atPoint: c)
        }
    }
    
    func mouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)

        upNodeName = getTouchedNodeName()
        
        var newEntity: AFEntity!
        
        if upNodeName == nil {
            // Mouse up in the black; always a full deselect
            deselectAll()
            
            if event.modifierFlags.contains(.control) {
                // ctrl-click gives a clone of the last guy, goals and all
                guard GameScene.me!.entities.count > 0 else { return }
                
                let originalIx = GameScene.me!.entities.count - 1
                let originalEntity = GameScene.me!.entities[originalIx]
                
                newEntity = AFEntity(scene: GameScene.me!, copyFrom: originalEntity, position: currentPosition!)
                _ = AppDelegate.me!.sceneController.addNode(entity: newEntity)
            } else {
                let imageIndex = AppDelegate.me!.agentImageIndex
                newEntity = AppDelegate.me!.sceneController.addNode(image: AppDelegate.me!.agents[imageIndex].image, at: currentPosition!)
            }
            
            select(newEntity.name, primary: true)
            
            AppDelegate.me!.placeAgentFrames(agentName: newEntity.name)
        } else {
            if event.modifierFlags.contains(.command) {
                if mouseState == .down {
                    // cmd+click on a node
                    toggleSelection(upNodeName!)
                } else {
                    print("drag")
                }
            } else {
                if mouseState == .down {    // That is, we're coming out of down as opposed to drag
                    let setSelection = (primarySelectionName != upNodeName!)

                    deselectAll()
                    
                    if setSelection {
                        select(upNodeName!, primary: true)
                    }
                }
            }
        }
        
        downNodeName = nil
        mouseState = .up
    }
    
    func newAgent(_ name: String) {
        deselectAll()
        select(name, primary: true)
    }
    
    func rightMouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeName = getTouchedNodeName()
        downNodeName = nil
        mouseState = .rightDown
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

        if upNodeName == nil {
            contextMenu.addItem(withTitle: titles[.DrawPaths]!, action: #selector(AppDelegate.contextMenuClicked(_:)), keyEquivalent: "")
        } else {
            contextMenu.addItem(withTitle: titles[.CloneAgent]!, action: #selector(AppDelegate.contextMenuClicked(_:)), keyEquivalent: "")
        }

        (NSApp.delegate as? AppDelegate)?.showContextMenu(at: event.locationInWindow)
    }
    
    func select(_ name: String, primary: Bool) {
        selectedNames.insert(name)
        
        gameScene.entities[name].agent.select(primary: primary)
        
        if primary {
            AppDelegate.agentEditorController.goalsController.dataSource = GameScene.me!.entities[name]
            AppDelegate.agentEditorController.attributesController.delegate = GameScene.me!.entities[name].agent

            primarySelectionName = name
            AppDelegate.me!.placeAgentFrames(agentName: name)
        }
    }
    
    func toggleSelection(_ name: String) {
        if selectedNames.contains(name) { deselect(name) }
        else { select(name, primary: primarySelectionName == nil) }
    }
    
    func trackMouse(nodeName: String, atPoint: CGPoint) {
        let agent = getAgent(name: nodeName)
        agent.position = vector_float2(Float(atPoint.x), Float(atPoint.y))
        agent.position.x += Float(nodeToMouseOffset.x)
        agent.position.y += Float(nodeToMouseOffset.y)
        agent.update(deltaTime: 0)
    }
}
