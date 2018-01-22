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
            
            if flags?.contains(.option) ?? false {
                sceneUI.enter(Draw.self)
                return
            } else if flags?.contains(.control) ?? false {
                // ctrl-click gives a clone of the selected guy, goals and all.
                // If no one is selected, we don't do anything.
                guard let selected = sceneUI.primarySelection else { return }
                
                if let theClone = clone(selected, position: sceneUI.currentPosition) {
                    select(theClone.agent.sprite, primary: true)
                }
            } else {
                let imageIndex = AFCore.browserDelegate.agentImageIndex
                let image = sceneUI.ui.agents[imageIndex].image
                let newEntity = sceneUI.data.createEntity(image: image, position: sceneUI.currentPosition)
                select(newEntity.agent.sprite, primary: true)
            }
        }
        
        private func click_node(name: String, flags: NSEvent.ModifierFlags?) {
            // opt-click and ctrl-click currently have no meaning when
            // clicking on a node, so we just ignore them
            guard !((flags?.contains(.control) ?? false) ||
                    (flags?.contains(.option) ?? false)) else { return }
            
            if let flags = flags, flags.contains(.command) {
                if sceneUI.mouseState == .down { // cmd+click on a node
                    sceneUI.toggleSelection(sceneUI.upNode!)
                }
            } else {
                if sceneUI.mouseState == .down {    // That is, we're coming out of down as opposed to drag
                    let setSelection = (sceneUI.primarySelection != sceneUI.upNode!)
                    
                    deselectAll()
                    
                    if setSelection {
                        select(sceneUI.upNode!, primary: true)
                    }
                }
            }
        }
        
        func clone(_ node: SKNode, position: CGPoint) -> AFEntity? {
            if let toBeCloned = AFSceneUI.getUserDataItem(.TheCloneablePart, from: node) as? AFCloneable {
                return toBeCloned.clone(position: position)
            }
            
            return nil
        }

        override func deselect(_ node: SKNode) {
            if let entity = sceneUI.data.entities[node.name!] {
                deselectEntity(entity)
            } else if let path = sceneUI.data.paths[node.name!] {
                deselectPath(path)
            } else if let ix = sceneUI.activePath.graphNodes.getIndexOf(node.name!) {
                sceneUI.activePath.deselect(ix)
            } else {
                print("obstacle or something")
            }
        }
        
        override func deselectAll() {
            sceneUI.data.entities.forEach{ $0.agent.deselect() }
            sceneUI.data.paths.forEach { $0.deselectAll() }
            
            sceneUI.selectedNodes.removeAll()
            sceneUI.primarySelection = nil
            sceneUI.updatePrimarySelectionState(agentNode: nil)
            
            sceneUI.contextMenu.includeInDisplay(.CloneAgent, false)
        }
        
        func deselectEntity(_ entity: AFEntity) {
            entity.agent.deselect()
            sceneUI.selectedNodes.remove(entity.agent.sprite)
            
            // We just now deselected the primary. If there's anyone
            // else selected, they need to be made the primary.
            if sceneUI.primarySelection == entity.agent.sprite {
                var selectNew: SKNode?
                
                if sceneUI.selectedNodes.count > 0 {
                    selectNew = sceneUI.selectedNodes.first!
                    select(selectNew!, primary: true)
                } else {
                    sceneUI.primarySelection = nil
                }
                
                sceneUI.updatePrimarySelectionState(agentNode: selectNew)
            }
            
            sceneUI.contextMenu.includeInDisplay(.CloneAgent, false)
        }
        
        func deselectPathNode(path: AFPath, nodeName: String) {
            path.graphNodes[nodeName]!.deselect()
            //sceneUI.selectedNodes.remove(nodeName)
        }
        
        func deselectPath(_ path: AFPath) {
            path.deselect()
        }
        
        override func didEnter(from previousState: GKState?) {
        }
        
        override func select(_ index: Int, primary: Bool) {
            let entity = sceneUI.data.entities[index]
            select(entity.agent.sprite, primary: primary)
        }
        
        override func select(_ node: SKNode, primary: Bool) {
            sceneUI.selectedNodes.insert(node)
            
            let nodeOwner = AFSceneUI.getUserDataItem(.NodeOwner, from: node)
            
            switch nodeOwner {
            case let entity as AFEntity: selectAgent(of: entity, primarySelection: (primary ? node : nil))
            case let path as AFPath: path.select(node)
            default: print("obstacles or smething")
            }
        }
        
        func selectAgent(of entity: AFEntity, primarySelection: SKNode?) {
            entity.agent.select(primary: primarySelection != nil)
            
            if let node = sceneUI.primarySelection {
                AFCore.ui.agentEditorController.goalsController.dataSource = entity
                AFCore.ui.agentEditorController.attributesController.delegate = entity.agent
                
                sceneUI.primarySelection = node
                sceneUI.updatePrimarySelectionState(agentNode: node)
            }
            
            sceneUI.contextMenu.includeInDisplay(.CloneAgent, true, enable: true)
        }
        
        override func willExit(to nextState: GKState) {
            deselectAll()
        }
    }
}

protocol AFCloneable {
    var name: String { get }
    func clone(position: CGPoint) -> AFEntity
}
