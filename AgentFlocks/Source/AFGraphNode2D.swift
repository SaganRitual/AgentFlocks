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

//class AFGraphNode2D_Script: Codable, Equatable {
//    let drawable: Bool
//    let name: String
//    let position: CGPoint
//
//    init(afGraphNode: AFGraphNode2D) {
//        drawable = afGraphNode.drawable
//        name = afGraphNode.name
//        position = CGPoint(afGraphNode.position)
//    }
//
//    static func ==(lhs: AFGraphNode2D_Script, rhs: AFGraphNode2D_Script) -> Bool {
//        return lhs.name == rhs.name
//    }
//}

class AFGraphNode2D: GKGraphNode2D {
    private let core: AFCore
    private let familyName: String
    private let name: String
    private let radius: CGFloat = 5
    private let gameScene: SKScene
    private var isSelected = false
    private var spriteSet: SpriteSet
    
    override var position: vector_float2 {
        set { super.position = newValue; spriteSet.position = CGPoint(newValue) }
        get { return vector_float2(Float(spriteSet.position.x), Float(spriteSet.position.y)) }
    }

    init(core: AFCore, editor: AFGraphNodeEditor, position: CGPoint, gameScene: SKScene) {
        let name = NSUUID().uuidString
        self.core = core
        self.familyName = String()//embryo.familyName
        self.name = name
        self.gameScene = gameScene
        self.spriteSet = SpriteSet(familyName: familyName, gameScene: gameScene, position: position)
        
        super.init(point: position.as_vector_float2())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hasBeenDeleted(_ name: String) {
    }
    
    func hasBeenDeselected(_ name: String) {
    }
    
    func hasBeenSelected(_ name: String, primary: Bool) {
    }
    
    func move(to position: CGPoint) {
        self.position = position.as_vector_float2()
    }
}

extension AFGraphNode2D {

    // MARK - Sprite central for the agent
    
    class SpriteContainerNode: SKNode {
        var graphNodeConnector: NSMutableDictionary { return super.userData! }
        
        init(name: String) {
            super.init()
            super.name = name
            super.userData = NSMutableDictionary()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class SpriteSet: AFSceneControllerDelegate {
        private let familyName: String
        private var isSelected = false
        private var primaryContainer: AFGraphNode2D.SpriteContainerNode!
        private unowned let gameScene: SKScene
        private var selectionIndicator: SKNode
        private let selectionIndicatorRadius: CGFloat = 30
        private let theSprite: SKShapeNode
        
        var name: String { return primaryContainer.name! }
        
        var position: CGPoint {
            get { return primaryContainer.position }
            set { primaryContainer.position = newValue }
        }
        
        init(familyName: String, gameScene: SKScene, position: CGPoint) {
            (theSprite, selectionIndicator) = SpriteSet.makeMarkerSprite(radius: 30, position: position, selectionIndicatorRadius: 40)
            
            self.familyName = familyName
            self.gameScene = gameScene
            
            primaryContainer = AFGraphNode2D.SpriteContainerNode(name: name)
            primaryContainer.position = position

            gameScene.addChild(primaryContainer)
            primaryContainer.addChild(theSprite)
        }
        
        deinit {
            primaryContainer.removeFromParent()
        }
        
        func hasBeenDeselected(_ name: String?) {
            if name == nil || name! == self.name {
                isSelected = false
                selectionIndicator.removeFromParent()
            }
        }
        
        func hasBeenSelected(_ name: String, primary: Bool) {        // 40 is just a number that makes the rings look about right to me
            guard name == self.name else { return }

            isSelected = true
            
            selectionIndicator = AFAgentAvatar.makeRing(radius: 40, isForSelector: true, primary: primary)
            primaryContainer.addChild(selectionIndicator)
        }
        
        static func makeMarkerSprite(radius: CGFloat, position: CGPoint, selectionIndicatorRadius: CGFloat) -> (SKShapeNode, SKNode) {
            let sprite = SKShapeNode(circleOfRadius: selectionIndicatorRadius)
            sprite.fillColor = .yellow
            sprite.name = NSUUID().uuidString
            sprite.position = position
//            sprite.zPosition = CGFloat(coreData.core.sceneController.getNextZPosition())
            
            let selectionIndicator = AFAgentAvatar.makeRing(radius: Float(selectionIndicatorRadius), isForSelector: true, primary: true)
            
            return (sprite, selectionIndicator)
        }
    }
}
