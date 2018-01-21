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

class AFGraphNode2D_Script: Codable, Equatable {
    let drawable: Bool
    let name: String
    let position: CGPoint

    init(afGraphNode: AFGraphNode2D) {
        drawable = afGraphNode.drawable
        name = afGraphNode.name
        position = CGPoint(afGraphNode.position)
    }

    static func ==(lhs: AFGraphNode2D_Script, rhs: AFGraphNode2D_Script) -> Bool {
        return lhs.name == rhs.name
    }
}

class AFGraphNode2D: GKGraphNode2D, AFScenoid {
    let drawable: Bool
    let gameScene: GameScene
    unowned let pathOwner: AFPath
    let radius: CGFloat = 5
    var selected = false
    let selectionIndicator: SKNode
    let selectionIndicatorRadius: CGFloat = 10
    let sprite: SKShapeNode
    
    var name: String { return sprite.name! }
    override var position: vector_float2 {
        set { super.position = newValue; sprite.position = CGPoint(newValue) }
        get { return vector_float2(Float(sprite.position.x), Float(sprite.position.y)) }
    }
    
    init(pathOwner: AFPath, copyFrom: AFGraphNode2D, gameScene: GameScene, drawable: Bool = true) {
        let (ss, se) = AFGraphNode2D.makeMarkerSprite(radius: radius, position: CGPoint(copyFrom.position), selectionIndicatorRadius: selectionIndicatorRadius)
        sprite = ss
        selectionIndicator = se

        self.gameScene = gameScene
        self.pathOwner = copyFrom.pathOwner
        
        if drawable { gameScene.addChild(sprite) }
        self.drawable = drawable

        super.init(point: copyFrom.position)
        applyMarkerUserData(to: sprite)
        applySelectionIndicatorUserData(to: selectionIndicator)
    }

    init(pathOwner: AFPath, float2Point: vector_float2, gameScene: GameScene, drawable: Bool = true) {
        let (ss, se) = AFGraphNode2D.makeMarkerSprite(radius: radius, position: CGPoint(float2Point), selectionIndicatorRadius: selectionIndicatorRadius)
        sprite = ss
        selectionIndicator = se

        self.gameScene = gameScene
        self.pathOwner = pathOwner

        if drawable { gameScene.addChild(sprite) }
        self.drawable = drawable

        super.init(point: float2Point)
        applyMarkerUserData(to: sprite)
        applySelectionIndicatorUserData(to: selectionIndicator)
    }
    
    init(pathOwner: AFPath, point: CGPoint, gameScene: GameScene, drawable: Bool = true) {
        let (ss, se) = AFGraphNode2D.makeMarkerSprite(radius: radius, position: point, selectionIndicatorRadius: selectionIndicatorRadius)
        sprite = ss
        selectionIndicator = se

        self.gameScene = gameScene
        self.pathOwner = pathOwner

        if drawable { gameScene.addChild(sprite) }
        self.drawable = drawable
        
        super.init(point: vector_float2(Float(point.x), Float(point.y)))
        applyMarkerUserData(to: sprite)
        applySelectionIndicatorUserData(to: selectionIndicator)
    }
    
    init(pathOwner: AFPath, prototype: AFGraphNode2D_Script, gameScene: GameScene) {
        let (ss, se) = AFGraphNode2D.makeMarkerSprite(radius: CGFloat(radius), position: prototype.position, selectionIndicatorRadius: selectionIndicatorRadius)
        sprite = ss
        selectionIndicator = se
        
        self.gameScene = gameScene

        if prototype.drawable { gameScene.addChild(sprite) }
        self.drawable = prototype.drawable
        self.pathOwner = pathOwner

        super.init(point: vector_float2(Float(prototype.position.x), Float(prototype.position.y)))
        applyMarkerUserData(to: sprite)
        applySelectionIndicatorUserData(to: selectionIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        showNode(false)
    }
    
    func applySelectionIndicatorUserData(to: SKNode) {
        to.userData = NSMutableDictionary()
        to.userData!["clickable"] = false
        to.userData!["selectable"] = false
        to.userData!["nodeOwner"] = self
        to.userData!["pathOwner"] = pathOwner
        to.userData!["nodeType"] = "Marker selection indicator"
    }
    
    func applyMarkerUserData(to: SKNode) {
        to.userData = NSMutableDictionary()
        to.userData!["clickable"] = true
        to.userData!["selectable"] = true
        to.userData!["nodeOwner"] = self
        to.userData!["pathOwner"] = pathOwner
        to.userData!["nodeType"] = "Graph node"
    }

    func deselect() {
        selected = false
        selectionIndicator.removeFromParent()
    }

    static func makeMarkerSprite(radius: CGFloat, position: CGPoint, selectionIndicatorRadius: CGFloat) -> (SKShapeNode, SKNode) {
        let sprite = SKShapeNode(circleOfRadius: radius)
        sprite.fillColor = .yellow
        sprite.name = NSUUID().uuidString
        sprite.position = position
        sprite.zPosition = CGFloat(AFCore.sceneUI.getNextZPosition())
        
        let selectionIndicator = AFAgent2D.makeRing(radius: Float(selectionIndicatorRadius), isForSelector: true, primary: true)
        
        return (sprite, selectionIndicator)
    }
    
    func move(to position: CGPoint) {
        sprite.position = position
    }
    
    func select(primary: Bool) {
        selected = true
        sprite.addChild(selectionIndicator)
    }
    
    func showNode(_ show: Bool = true) {
        guard drawable else { return }

        if show {
            gameScene.addChild(sprite)
            sprite.fillColor = (self.selected ? .yellow : .white)
        } else {
            sprite.removeFromParent()
            selectionIndicator.removeFromParent()
        }
    }
}

