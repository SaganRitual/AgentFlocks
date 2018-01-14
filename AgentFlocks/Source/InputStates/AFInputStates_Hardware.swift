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

protocol HardwareInputRelay {
    func getParent() -> AFInputState_Hardware
    func mouseDown(with event: NSEvent)
    func mouseDragged(with event: NSEvent)
    func mouseUp(with event: NSEvent)
    func rightMouseDown(with event: NSEvent)
    func rightMouseUp(with event: NSEvent)
}

// Empty default functions so the states don't have to be cluttered with them
extension HardwareInputRelay {
    func getParent() -> AFInputState_Hardware { return ((self as! GKState).stateMachine) as! AFInputState_Hardware }
    func mouseDown(with event: NSEvent) {}
    func mouseDragged(with event: NSEvent) {}
    func mouseUp(with event: NSEvent) {}
    func rightMouseDown(with event: NSEvent) {}
    func rightMouseUp(with event: NSEvent) {}
}

class AFInputState_Hardware: GKStateMachine {
    var mouseDownAt = CGPoint.zero
    var mouseDraggedAt = CGPoint.zero
    var mouseUpAt = CGPoint.zero
    var rightMouseDownAt = CGPoint.zero
    var rightMouseUpAt = CGPoint.zero
    
    init() {
        super.init(states: [
            MouseDown(), MouseUp()
        ])
        
        enter(MouseUp.self)
    }
    
    func getInputRelay() -> HardwareInputRelay? {
        if currentState == nil { return nil }
        else { return currentState! as? HardwareInputRelay }
    }
    
    func mouseDown(with event: NSEvent, at: CGPoint) { mouseDownAt = at; getInputRelay()?.mouseDown(with: event) }
    func mouseDragged(with event: NSEvent, at: CGPoint) { mouseDraggedAt = at; getInputRelay()?.mouseDragged(with: event) }
    func mouseUp(with event: NSEvent, at: CGPoint) { mouseUpAt = at; getInputRelay()?.mouseUp(with: event) }
    func rightMouseDown(with event: NSEvent, at: CGPoint) { rightMouseDownAt = at; getInputRelay()?.rightMouseDown(with: event) }
    func rightMouseUp(with event: NSEvent, at: CGPoint) { rightMouseUpAt = at; getInputRelay()?.rightMouseUp(with: event) }
    
    class KeyDown: GKState, HardwareInputRelay {
    }

    class MouseDown: GKState, HardwareInputRelay {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass is MouseDragged.Type || stateClass is MouseUp.Type
        }
    }

    class MouseDragged: GKState, HardwareInputRelay {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass is MouseUp.Type
        }
    }

    class MouseUp: GKState, HardwareInputRelay {
        override func didEnter(from previousState: GKState?) {
            // State machine sets us into mouseUp state at the beginning.
            // There's no previous state, so we do nothing
            guard previousState != nil else { return }
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass is MouseDown.Type || stateClass is RightMouseDown.Type || stateClass is KeyDown.Type
        }
    }
    
    class RightMouseDown: GKState, HardwareInputRelay {
    }
}

