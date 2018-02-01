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
        override func click(_ name: String?, flags: NSEvent.ModifierFlags?) {
            if let name = name { click_node(name, flags: flags) }
            else { click_black(flags: flags) }
        }
        
        private func click_black(flags: NSEvent.ModifierFlags?) {
            if flags?.contains(.option) ?? false {
                sceneUI.enter(Draw.self)
                return
            } else if flags?.contains(.control) ?? false {
                // ctrl-click gives a clone of the selected guy, goals and all.
                // If no one is selected, we don't do anything.
                guard let selected = sceneUI.primarySelection else { return }
                
                clone(selected, position: sceneUI.currentPosition)
            } else {
                // plain click in the black
                sceneUI.createAgent()
            }
        }
        
        private func click_node(_ name: String, flags: NSEvent.ModifierFlags?) {
            // Nothing to do here; only selection changes, and the selection
            // controller takes care of that.
        }
        
        func clone(_ name: String, position: CGPoint) { /*sceneUI.coreData.cloneAgent(node.name!)*/ }
        
        override func didEnter(from previousState: GKState?) {
        }
        
        override func willExit(to nextState: GKState) {
        }
    }
}

