//
// Created by Rob Bishop on 1/20/18
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
    class Default: BaseState {
        override func click(name: String?, flags: NSEvent.ModifierFlags?) {
            // If the user has dragged across the black for no particular reason,
            // ignore the mouse up; pretend nothing happened
            guard !(sceneUI.upNode == nil && sceneUI.mouseState == .dragging) else { return }
            
            if let name = name { click_node(name: name, flags: flags) }
            else { click_black(flags: flags) }
        }
        
        private func click_black(flags: NSEvent.ModifierFlags?) {
            deselectAll()
            
            var newEntity: AFEntity!
            
            if flags?.contains(.option) ?? false {
                sceneUI.enter(Draw.self)
                return
            } else if flags?.contains(.control) ?? false {
                // ctrl-click gives a clone of the selected guy, goals and all.
                // If no one is selected, we don't do anything.
                guard sceneUI.data.entities.count > 0 else { return }
                
                let originalIx = sceneUI.data.entities.count - 1
                let originalEntity = sceneUI.data.entities[originalIx]
                
                newEntity = sceneUI.data.createEntity(copyFrom: originalEntity, position: sceneUI.currentPosition)
            } else {
                let imageIndex = AFCore.browserDelegate.agentImageIndex
                let image = sceneUI.ui.agents[imageIndex].image
                newEntity = sceneUI.data.createEntity(image: image, position: sceneUI.currentPosition)
            }
            
            select(newEntity.name, primary: true)
        }
        
        private func click_node(name: String, flags: NSEvent.ModifierFlags?) {
            // opt-click and ctrl-click currently have no meaning when
            // clicking on a node, so we just ignore them
            guard !((flags?.contains(.control) ?? false) ||
                (flags?.contains(.option) ?? false)) else { return }
            
            if let flags = flags, flags.contains(.command) {
                if sceneUI.mouseState == .down { // cmd+click on a node
                    sceneUI.toggleSelection(sceneUI.upNode!.name!)
                }
            } else {
                if sceneUI.mouseState == .down {    // That is, we're coming out of down as opposed to drag
                    let setSelection = (sceneUI.primarySelection != sceneUI.upNode!)
                    
                    deselectAll()
                    
                    if setSelection {
                        select(sceneUI.upNode!.name!, primary: true)
                    }
                }
            }
        }
        
        override func deselect(_ name: String) {
            if let entity = sceneUI.data.entities[name] {
                deselectEntity(entity)
            } else if let path = sceneUI.data.paths[name] {
                deselectPath(path)
            } else if let ix = sceneUI.activePath.graphNodes.getIndexOf(name) {
                sceneUI.activePath.deselect(ix)
            } else {
                print("obstacle or something")
            }
        }
        
        override func deselectAll() {
            sceneUI.data.entities.forEach{ $0.agent.deselect() }
            sceneUI.data.paths.forEach { $0.deselectAll() }
            
            sceneUI.selectedNames.removeAll()
            sceneUI.primarySelection = nil
            sceneUI.updatePrimarySelectionState(agentName: nil)
            
            sceneUI.contextMenu.includeInDisplay(.CloneAgent, false)
        }
        
        func deselectEntity(_ entity: AFEntity) {
            entity.agent.deselect()
            sceneUI.selectedNames.remove(entity.name)
            
            // We just now deselected the primary. If there's anyone
            // else selected, they need to be made the primary.
            if sceneUI.primarySelection == entity {
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
        
        func deselectPathNode(path: AFPath, nodeName: String) {
            path.graphNodes[nodeName]!.deselect()
            sceneUI.selectedNames.remove(nodeName)
        }
        
        func deselectPath(_ path: AFPath) {
            path.deselect()
        }
        
        override func didEnter(from previousState: GKState?) {
        }
        
        override func select(_ index: Int, primary: Bool) {
            let entity = sceneUI.data.entities[index]
            select(entity.name, primary: primary)
        }
        
        override func select(_ name: String, primary: Bool) {
            sceneUI.selectedNames.insert(name)
            
            if let entity = sceneUI.data.entities[name] {
                selectAgent(of: entity, primarySelectionName: (primary ? name : nil))
            } else if let path = sceneUI.data.paths[name] {
                path.select(name)
            } else {
                print("obstacles or something")
            }
        }
        
        func selectAgent(of entity: AFEntity, primarySelectionName: String?) {
            entity.agent.select(primary: primarySelectionName != nil)
            
            if let name = primarySelectionName {
                AFCore.ui.agentEditorController.goalsController.dataSource = entity
                AFCore.ui.agentEditorController.attributesController.delegate = entity.agent
                
                sceneUI.primarySelection = entity.agent.sprite
                sceneUI.updatePrimarySelectionState(agentName: name)
            }
            
            sceneUI.contextMenu.includeInDisplay(.CloneAgent, true, enable: true)
        }
        
        override func willExit(to nextState: GKState) {
            deselectAll()
        }
    }
}
