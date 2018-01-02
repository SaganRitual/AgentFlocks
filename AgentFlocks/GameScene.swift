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

class GameScene: SKScene, SKViewDelegate {
    static var me: GameScene?

    var entities = [AFEntity]()
    var graphs = [String : GKGraph]()
    var inputMode = AFSelectionState_Primary.InputMode.primary
    var pathHandles = [SKShapeNode]()

    var lastUpdateTime : TimeInterval = 0
    var selectionDelegate: AFSelectionState!
    var selectionDelegateDraw: AFSelectionState_Draw!
    var selectionDelegatePrimary: AFSelectionState_Primary!
    var selectionIndicator: SKShapeNode!
    var multiSelectionIndicator: SKShapeNode!

    var corral = [SKShapeNode]()
    
    override func didMove(to view: SKView) {
        GameScene.me = self
    }

    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let w = 1500, h = 740/*frame.size.height*/
        let x = -w / 2/*frame.origin.x*/, y = -h / 2/*frame.origin.y*/
        
        selectionIndicator = SKShapeNode(circleOfRadius: 15)
        selectionIndicator.fillColor = .red
        
        multiSelectionIndicator = SKShapeNode(circleOfRadius: 15)
        multiSelectionIndicator.fillColor = .blue

        let adjustedOrigin = self.convertPoint(toView: CGPoint.zero)
        print(adjustedOrigin)
        
        let thickness = 50
        let offset = 0
        var specs: [(CGPoint, CGSize, NSColor)] = [
            (CGPoint(x: x, y: -y + thickness - offset), CGSize(width: w, height: thickness), .red),
            (CGPoint(x: -x - offset, y: y), CGSize(width: thickness, height: h), .yellow),
            (CGPoint(x: x, y: y + offset - 100), CGSize(width: w, height: thickness), .blue),
            (CGPoint(x: x - thickness + offset, y: y), CGSize(width: thickness, height: h), .green)
        ]
        
        func drawShape(_ ss: Int) {
            let shapeNode = SKShapeNode(rect: CGRect(origin: specs[ss].0, size: specs[ss].1))
            shapeNode.fillColor = specs[ss].2
            shapeNode.strokeColor = .black
            self.addChild(shapeNode)
            corral.append(shapeNode)
        }
        
        for i in 0..<4 { drawShape(i) }
        
        selectionDelegatePrimary = AFSelectionState_Primary(gameScene: self)
        selectionDelegateDraw = AFSelectionState_Draw(gameScene: self)
        selectionDelegate = selectionDelegatePrimary
    }
    
    func toggleRadii() {
        let state = entities[0].agent.showingRadius
        for entity in entities {
            entity.agent.showRadius(!state)
        }
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
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}

extension GameScene {
    func getSelectedAgents() -> [GKAgent2D] { return selectionDelegate.getSelectedAgents() }
    func getSelectedIndexes() -> Set<Int> { return selectionDelegate.getSelectedIndexes() }
    func getPrimarySelectionIndex() -> Int? { return selectionDelegate.getPrimarySelectionIndex() }
    override func mouseDown(with event: NSEvent) { selectionDelegate.mouseDown(with: event) }
    override func mouseDragged(with event: NSEvent) { selectionDelegate.mouseDragged(with: event) }
    override func mouseUp(with event: NSEvent) { selectionDelegate.mouseUp(with: event) }
    func newAgent(_ nodeIndex: Int) { selectionDelegate.newAgent(nodeIndex) }
    func toggleMultiSelectMode() { selectionDelegate.toggleMultiSelectMode() }
}

