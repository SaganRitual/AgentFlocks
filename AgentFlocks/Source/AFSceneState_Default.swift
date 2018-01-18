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
    
    class Default: GKState, AFSceneDrone {
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
        
        func mouseDown(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
            
        }
        
        func mouseMove(at position: CGPoint) { }
        
        func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
            // If the user has dragged across the black for no particular reason,
            // ignore the mouse up; pretend nothing happened
            guard !(sceneUI.upNodeName == nil && sceneUI.mouseState == .dragging) else { return }
            
            if sceneUI.upNodeName == nil {
                // Mouse up in the black; always a full deselect
                deselectAll()
                
                var newEntity: AFEntity!
                var controlKey = false
                var optionKey = false
                if let flags = flags {
                    controlKey = flags.contains(.control)
                    optionKey = flags.contains(.option)
                }
                
                if optionKey {
                    sceneUI.stateMachine.enter(Draw.self)
                    sceneUI.mouseUp(on: node, at: position, flags: flags)
                    return
                } else if controlKey {
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
