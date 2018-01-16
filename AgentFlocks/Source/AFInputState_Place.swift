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
    
    class ModePlace: GKState, EditModeRelay {
        
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
            
            AFContextMenu.includeInDisplay(.CloneAgent, false)
        }
        
        func deselectAll() {
            let psm = getParentStateMachine()
            
            psm.data.entities.forEach{ $0.agent.deselect() }
            
            // Ugliness; this stuff should be in inputState
            psm.selectedNames.removeAll()
            psm.primarySelection = nil
            psm.updatePrimarySelectionState(agentName: nil)
            
            AFContextMenu.includeInDisplay(.CloneAgent, false)
        }
        
        override func didEnter(from previousState: GKState?) {
            AFContextMenu.reset()
            AFContextMenu.includeInDisplay(.Draw, true)
            AFContextMenu.enableInDisplay(.Draw, true)
        }
        
        func getPosition(ofNode name: String) -> CGPoint {
            return getParentStateMachine().data.entities[name].agent.spriteContainer.position
        }
        
        func getTouchedNode(touchedNodes: [SKNode]) -> SKNode? {
            let psm = getParentStateMachine()
            
            // Find the last descendant; I think that will be the top one
            for entity in psm.data.entities.reversed() {
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
                    guard psm.data.entities.count > 0 else { return }
                    
                    let originalIx = psm.data.entities.count - 1
                    let originalEntity = psm.data.entities[originalIx]
                    
                    newEntity = psm.data.createEntity(copyFrom: originalEntity, position: psm.currentPosition)
                } else {
                    let imageIndex = AFCore.browserDelegate.agentImageIndex
                    let image = AppDelegate.me!.agents[imageIndex].image
                    newEntity = psm.data.createEntity(image: image, position: psm.currentPosition)
                }
                
                select(newEntity.name, primary: true)
                psm.updatePrimarySelectionState(agentName: newEntity.name)
            } else {
                if event.modifierFlags.contains(.command) {
                    if psm.mouseState == .down { // cmd+click on a node
                        psm.toggleSelection(psm.upNodeName!)
                    }
                } else {
                    if psm.mouseState == .down {    // That is, we're coming out of down as opposed to drag
                        let setSelection = (psm.primarySelection != psm.upNodeName!)
                        
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
            let entity = psm.data.entities[index]
            select(entity.name, primary: primary)
        }
        
        func select(_ name: String, primary: Bool) {
            let psm = getParentStateMachine()
            
            psm.selectedNames.insert(name)
            
            let entity = psm.data.entities[name]
            entity.agent.select(primary: primary)
            
            if primary {
                AppDelegate.agentEditorController.goalsController.dataSource = entity
                AppDelegate.agentEditorController.attributesController.delegate = entity.agent
                
                psm.primarySelection = name // Ugliness; move this into inputState
                psm.updatePrimarySelectionState(agentName: name)
            }
            
            AFContextMenu.includeInDisplay(.CloneAgent, true, enable: true)
        }
        
        func trackMouse(nodeName: String, atPoint: CGPoint) {
            let psm = getParentStateMachine()
            let offset = psm.nodeToMouseOffset
            let agent = psm.data.entities[nodeName].agent
            
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

