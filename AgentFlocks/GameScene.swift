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

    var entities = AFOrderedMap<String, AFEntity>()
    var inputMode = AFSelectionState_Primary.InputMode.primary
    var pathForNextPathGoal = 0
    var paths = AFOrderedMap<String, AFPath>()

    var lastUpdateTime : TimeInterval = 0
    var selectionDelegate: AFSelectionState!
    var selectionDelegateDraw: AFSelectionState_Draw!
    var selectionDelegatePrimary: AFSelectionState_Primary!

    override func didMove(to view: SKView) {
        GameScene.me = self
    }

    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        selectionDelegatePrimary = AFSelectionState_Primary(gameScene: self)
        selectionDelegateDraw = AFSelectionState_Draw(gameScene: self)
        selectionDelegate = selectionDelegatePrimary
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
        for i in 0 ..< entities.count {
            let entity = entities[i]
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}

extension GameScene {
    func getSelectedAgents() -> [AFScenoid] { return selectionDelegate.getSelectedScenoids() }
    func getSelectedNames() -> Set<String> { return selectionDelegate.getSelectedNames() }
    func getPrimarySelectionName() -> String? { return selectionDelegate.getPrimarySelectionName() }
    override func keyDown(with event: NSEvent) { selectionDelegate.keyDown(with: event) }
    override func keyUp(with event: NSEvent) { selectionDelegate.keyUp(with: event) }
    override func mouseDown(with event: NSEvent) { selectionDelegate.mouseDown(with: event) }
    override func mouseDragged(with event: NSEvent) { selectionDelegate.mouseDragged(with: event) }
    override func mouseUp(with event: NSEvent) { selectionDelegate.mouseUp(with: event) }
	override func rightMouseUp(with event: NSEvent) { selectionDelegate.rightMouseUp(with: event) }
	override func rightMouseDown(with event: NSEvent) { selectionDelegate.rightMouseDown(with: event) }
    func newAgent(_ name: String) { selectionDelegate.newAgent(name) }
}

