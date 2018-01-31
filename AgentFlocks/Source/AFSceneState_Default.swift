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

extension AFSceneController {
    class Default: BaseState {
        override func click(_ node: SKNode?, flags: NSEvent.ModifierFlags?) {
            // If the user has dragged across the black for no particular reason,
            // ignore the mouse up; pretend nothing happened
            guard !(sceneUI.upNode == nil && sceneUI.mouseState == .dragging) else { return }
            
            if let node = node { click_node(node, flags: flags) }
            else { click_black(flags: flags) }
        }
        
        private func click_black(flags: NSEvent.ModifierFlags?) {
            sceneUI.deselectAll()
            
            if flags?.contains(.option) ?? false {
                sceneUI.enter(Draw.self)
                return
            } else if flags?.contains(.control) ?? false {
                // ctrl-click gives a clone of the selected guy, goals and all.
                // If no one is selected, we don't do anything.
                guard let selected = sceneUI.primarySelection else { return }
                
                clone(selected, position: sceneUI.currentPosition)
            } else {
//                // plain click in the black; create a new agent
//                let imageIndex = AFCore.browserDelegate.agentImageIndex
//                let image = sceneUI.ui.agents[imageIndex].image
                
//                coreData.core.sceneUI.newAgent()  // We'll hear back when the low-level data is setup
            }
        }
        
        private func click_node(_ node: SKNode, flags: NSEvent.ModifierFlags?) {
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
                    
                    sceneUI.deselectAll()
                    
                    if setSelection {
                        sceneUI.select(sceneUI.upNode!, primary: true)
                    }
                }
            }
        }
        
        func clone(_ node: SKNode, position: CGPoint) { /*sceneUI.coreData.cloneAgent(node.name!)*/ }
        
        override func didEnter(from previousState: GKState?) {
        }
        
        override func newAgentHasBeenCreated(_ notification: Notification) {
//            let agent = notification.object as! String
//            let embryo = sceneUI.coreData.getAgent(agent)
//            let image = sceneUI.ui.agents[AFCore.browserDelegate.agentImageIndex].image
//            let afAgent = AFAgent2D(coreData: sceneUI.coreData, embryo: embryo, image: image,
//                          position: sceneUI.currentPosition, scene: sceneUI.gameScene)
//            
//            sceneUI.select(afAgent.name, primary: true)
        }
        
        override func willExit(to nextState: GKState) {
            sceneUI.deselectAll()
        }
    }
}

