//
// Created by Rob Bishop on 1/7/18
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

class AFVertex: AFScenoid {
    let gameScene: GameScene!
    let markerSize: CGFloat = 5
    let selectionIndicator: SKNode!
    let selectionIndicatorSize: Float = 10
    let sprite: SKShapeNode!
    
    var position: CGPoint { return sprite.position }
    
    init() {
        gameScene = nil
        selectionIndicator = nil
        
        // Turning into more and more of a kludge. I'm dummying this up so I can create
        // an AFVertex to hold the SKNode for the vertex sprite. Smells bad.
        sprite = SKShapeNode(circleOfRadius: 0)
    }
    
    init(scene: GameScene, position: CGPoint) {
        gameScene = scene
        
        sprite = SKShapeNode(circleOfRadius: markerSize)
        sprite.fillColor = .yellow
        sprite.position = position
        
        selectionIndicator = AFAgent2D.makeRing(radius: selectionIndicatorSize, isForSelector: true, primary: true)
        
        gameScene.addChild(sprite)
    }
    
    deinit {
        sprite.removeFromParent()
    }
    
    func deselect() {
        selectionIndicator?.removeFromParent()
    }
    
    func select(primary: Bool) {
        sprite.addChild(selectionIndicator)
    }
}
