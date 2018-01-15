//
// Created by Rob Bishop on 12/17/17.
//
// Copyright © 2017 Rob Bishop
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

import SpriteKit
import GameplayKit

enum AFKeyCodes: UInt {
    case delete = 51
    case enter = 36
    case escape = 53
}

class GameScene: SKScene, SKViewDelegate {
    static var me: GameScene?

    var inputState: AFInputState!
    var pathForNextPathGoal = 0

    var lastUpdateTime : TimeInterval = 0

    override func didMove(to view: SKView) {
        GameScene.me = self
    }

    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        AFCore.makeCore(gameScene: self)
        inputState = AFCore.inputState
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in AFCore.data.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}

extension GameScene {
    func getSelectedNames() -> Set<String> { return inputState.getSelectedNames() }
    func getPrimarySelectionName() -> String? { return inputState.getPrimarySelectionName() }

    override func keyDown(with event: NSEvent) { inputState.keyDown(with: event) }
    override func keyUp(with event: NSEvent) { inputState.keyUp(with: event) }
    override func mouseDown(with event: NSEvent) { inputState.mouseDown(with: event) }
    override func mouseDragged(with event: NSEvent) { inputState.mouseDragged(with: event) }
    override func mouseUp(with event: NSEvent) { inputState.mouseUp(with: event) }
    override func rightMouseUp(with event: NSEvent) { inputState.rightMouseUp(with: event) }
	override func rightMouseDown(with event: NSEvent) { inputState.rightMouseDown(with: event) }
}

