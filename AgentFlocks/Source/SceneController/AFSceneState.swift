//
// Created by Rob Bishop on 1/19/18
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

protocol AFSceneControllerState {
    func click(_ name: String?, flags: NSEvent.ModifierFlags?)
    func flagsChanged(to newFlags: NSEvent.ModifierFlags)
    func mouseMove(to position: CGPoint)
    func newAgentHasBeenCreated(_ notification: Foundation.Notification)
    func newPathHasBeenCreated(_ notification: Foundation.Notification)
}

extension AFSceneController {
    var drone: AFSceneControllerState { return currentState as! AFSceneControllerState }
    
    class BaseState: GKState, AFSceneControllerState {
        var afSceneController: AFSceneController { return stateMachine! as! AFSceneController }
        
        func click(_ name: String?, flags: NSEvent.ModifierFlags?) { }
        func flagsChanged(to newFlags: NSEvent.ModifierFlags) {}
        func mouseMove(to position: CGPoint) {}
        func newAgentHasBeenCreated(_ notification: Foundation.Notification) {}
        func newPathHasBeenCreated(_ notification: Foundation.Notification) {}

        func click_item(_ name: String, flags: NSEvent.ModifierFlags?) {
            // Ignore all modified clicks on a path node, for now
            guard !((flags?.contains(.command) ?? false) ||
                (flags?.contains(.control) ?? false) ||
                (flags?.contains(.option) ?? false)) else { return }
            
            afSceneController.selectionController.click_item(name, flags: flags)
        }
    }
}
