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
    
    class GoalSetup: BaseState {
        override func didEnter(from previousState: GKState?) {
            sceneUI.showFullPathHandle(true)
            
            // Set selection indicator color to blue
        }
        
        override func click(name: String?, flags: NSEvent.ModifierFlags?) {
            if let name = name { click_node(name: name, flags: flags) }
            else { click_black(flags: flags) }
        }
        
        private func click_black(flags: NSEvent.ModifierFlags?) {
            // Ignore all modified clicks in the black, for now
            guard !((flags?.contains(.command) ?? false) ||
                (flags?.contains(.control) ?? false) ||
                (flags?.contains(.option) ?? false)) else { return }
            
            deselectAll()
        }
        
        // This looks a lot like Default.click_node()
        private func click_node(name: String, flags: NSEvent.ModifierFlags?) {
            // opt-click and ctrl-click currently have no meaning when
            // clicking on a node, so we just ignore them
            guard !((flags?.contains(.control) ?? false) ||
                (flags?.contains(.option) ?? false)) else { return }
            
            var effectiveFlagState = flags
            
            let mode = sceneUI.goalSetupInputMode
            if mode == .NoSelect { return }
            
            // So single-select mode will ignore click modifiers
            if mode == .SingleSelectAgent || mode == .SingleSelectPath { effectiveFlagState = nil }
            
            if effectiveFlagState?.contains(.command) ?? false {
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

        override func flagsChanged(to newFlags: NSEvent.ModifierFlags) {
            sceneUI.showFullPathHandle(true)
        }
    }
}
