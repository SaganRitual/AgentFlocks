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

extension CGPoint {
    init(_ vf: vector_float2) {
        self = CGPoint(x: CGFloat(vf.x), y: CGFloat(vf.y))
    }
}

class AFGraphNode2D: GKGraphNode2D, AFScenoid {
    let radius: CGFloat = 5
    let selectionIndicator: SKNode!
    let selectionIndicatorRadius: CGFloat = 10
    let sprite: SKShapeNode!
    
    var name: String { return sprite.name! }
    override var position: vector_float2 {
        set { super.position = newValue; sprite.position = CGPoint(newValue) }
        get { return vector_float2(Float(sprite.position.x), Float(sprite.position.y)) }
    }

    init(float2Point: vector_float2) {
        let (ss, se) = AFGraphNode2D.makeMarkerSprite(radius: radius, position: CGPoint(float2Point), selectionIndicatorRadius: selectionIndicatorRadius)
        sprite = ss
        selectionIndicator = se
        super.init(point: float2Point)
    }
    
    init(point: CGPoint) {
        let (ss, se) = AFGraphNode2D.makeMarkerSprite(radius: radius, position: point, selectionIndicatorRadius: selectionIndicatorRadius)
        sprite = ss
        selectionIndicator = se
        super.init(point: vector_float2(Float(point.x), Float(point.y)))
    }
    
//    init(prototype: AFGraphNode2D_Script) {
//        super.init(point: vector_float2(Float(prototype.position.x), Float(prototype.position.y)))
//    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        sprite.removeFromParent()
        selectionIndicator.removeFromParent()
    }
    
    func deselect() {
        selectionIndicator?.removeFromParent()
    }

    static func makeMarkerSprite(radius: CGFloat, position: CGPoint, selectionIndicatorRadius: CGFloat) -> (SKShapeNode, SKNode) {
        let sprite = SKShapeNode(circleOfRadius: radius)
        sprite.fillColor = .yellow
        sprite.name = NSUUID().uuidString
        sprite.position = position
        
        let selectionIndicator = AFAgent2D.makeRing(radius: Float(selectionIndicatorRadius), isForSelector: true, primary: true)
        
        GameScene.me!.addChild(sprite)
        
        return (sprite, selectionIndicator)
    }
    
    func select(primary: Bool) {
        sprite.addChild(selectionIndicator)
    }
}
