//
// Created by Rob Bishop on 1/17/18
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

import AppKit

class AFGameSceneDelegate {
    let data: AFData
    
    init(data: AFData) {
        self.data = data
    }
    
    func update(deltaTime dt: TimeInterval) {
        data.entities.forEach { $0.update(deltaTime: dt) }
    }
    
    func keyDown(with event: NSEvent) {
        
    }
    
    func keyUp(with event: NSEvent) {  }
    func mouseDown(with event: NSEvent) { AFCore.inputState.mouseDown(with: event) }
    func mouseDragged(with event: NSEvent) { AFCore.inputState.mouseDragged(with: event) }
    func mouseUp(with event: NSEvent) { AFCore.inputState.mouseUp(with: event) }
    func rightMouseUp(with event: NSEvent) {  }
    func rightMouseDown(with event: NSEvent) {  }
}
