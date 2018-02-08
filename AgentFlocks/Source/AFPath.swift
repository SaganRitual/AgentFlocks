//
// Created by Rob Bishop on 1/4/18
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

class AFPath: Equatable {
    private var core: AFCore
    private var finalized = false
    private unowned let gameScene: SKScene
    private var gkPath: GKPath! = nil
    private var graphNodes = AFOrderedMap<String, AFGraphNode2D>()
    private static let handleOffset = CGPoint(x: 0, y: 15)
    let name: String
    private unowned let notifications: NotificationCenter
    private let spriteSet: SpriteSet
    
    init(core: AFCore, editor: AFPathEditor, gameScene: SKScene) {
        let name = NSUUID().uuidString
        
        self.core = core
        self.name = name
        self.notifications = coreData.notifications
        self.gameScene = gameScene
        self.spriteSet = SpriteSet(name: name, gameScene: gameScene)

        let newGraphNode = NSNotification.Name(rawValue: AFCoreData.NotificationType.NewGraphNode.rawValue)
        let aSelector = #selector(newGraphNodeHasBeenCreated(_:))
        self.notifications.addObserver(self, selector: aSelector, name: newGraphNode, object: coreData)

        let select = NSNotification.Name(rawValue: AFSceneController.NotificationType.Selected.rawValue)
        let bSelector = #selector(hasBeenSelected(_:primary:))
        self.notifications.addObserver(self, selector: bSelector, name: select, object: coreData)

        let deleteGraphNode = NSNotification.Name(rawValue: AFCoreData.NotificationType.DeletedGraphNode.rawValue)
        let cSelector = #selector(graphNodeHasBeenDeleted(_:))
        self.notifications.addObserver(self, selector: cSelector, name: deleteGraphNode, object: coreData)
    }

    static func ==(lhs: AFPath, rhs: AFPath) -> Bool {
        return lhs.name == rhs.name
    }

    func addGraphNode(at point: CGPoint) {
//        coreData.newGraphNode(for: self.name)
    }
  
    func getLastHandlePosition() -> CGPoint? {
        if let last = graphNodes.last { return CGPoint(last.position) } else { return nil }
    }
    
    @objc func graphNodeHasBeenDeleted(_ name: String) { _ = graphNodes.remove(name) }
    
    @objc func hasBeenDeselected(_ node: SKNode) {
        // The gameScene controller just calls out the name of the
        // node who's been deselected. It's up to the node to
        // respond only to its own name.
        guard node.name! == self.name else { return }
        graphNodes.forEach { $0.hasBeenDeselected(node.name!) }
    }
    
    @objc func hasBeenSelected(_ node: SKNode, primary: Bool) {
        // The gameScene controller just calls out the name of the
        // node who's been selected. It's up to the node to
        // respond only to its own name.
        guard node.name! == self.name else { return }
        graphNodes.forEach { $0.hasBeenSelected(node.name!, primary: primary) }
    }
    
    func move(to position: CGPoint) { spriteSet.move(to: position) }
    
    @objc func newGraphNodeHasBeenCreated(_ name: String) {
//        let embryo = coreData.getGraphNode(name, parentPath: self.name)
//        let afNode = AFGraphNode2D(core: core, embryo: embryo, position: CGPoint.zero, gameScene: self.gameScene)
//        self.graphNodes.append(key: name, value: afNode)
//        spriteSet.refresh(self)
    }

}

extension AFPath {
    class SpriteContainerNode: SKNode {
        var pathConnector: NSMutableDictionary { return super.userData! }
        
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
        var isSelected = false
        private var name: String
        private var pathHandle: SKShapeNode!
        private var primaryContainer: AFPath.SpriteContainerNode
        private unowned let gameScene: SKScene
        private var visualPathNode: SKShapeNode!

        init(name: String, gameScene: SKScene) {
            self.name = name
            self.gameScene = gameScene
            self.visualPathNode = nil

            primaryContainer = AFPath.SpriteContainerNode(name: name)
            pathHandle = SKShapeNode(circleOfRadius: 15)
            
            primaryContainer.addChild(pathHandle)
            gameScene.addChild(primaryContainer)
        }
        
        deinit {
            primaryContainer.removeFromParent()
        }
        
        func getImageData(size: CGSize) -> NSImage {
            let texture = gameScene.view!.texture(from: visualPathNode!)!
            let cgImage = texture.cgImage()
            let nsImage = NSImage(cgImage: cgImage, size: size)
            
            return nsImage
        }

        func hasBeenDeselected(_ name: String?) {
            if name == nil || name! == self.name {
                isSelected = false
                pathHandle.strokeColor = .clear
            }
        }
        
        func hasBeenSelected(_ name: String, primary: Bool) {
            guard name == self.name else { return }
            isSelected = true
            pathHandle.strokeColor = .green
        }
        
        func move(to position: CGPoint) {

        }

        func refresh(_ owningPath: AFPath) {
            // GKPath constructor will totally crash the app such
            // that XCode can't catch the error
            guard owningPath.graphNodes.count > 1 else { return }
            
            reset()
            
            var visualDotsArray = [CGPoint]()
            
            for node in owningPath.graphNodes {
                let cgPoint = CGPoint(node.position)
                visualDotsArray.append(cgPoint)
            }
            
            var startPoint: CGPoint!
            let visualPath = CGMutablePath()
            for dot in visualDotsArray {
                let point = dot
                if startPoint == nil {
                    startPoint = point
                    visualPath.move(to: point)
                } else {
                    visualPath.addLine(to: point)
                }
            }
            
            visualPathNode = SKShapeNode(path: visualPath)
            visualPathNode!.name = name
            
            primaryContainer.addChild(visualPathNode!)
            gameScene.addChild(primaryContainer)
        }
        
        func reset() {
            primaryContainer.removeFromParent()
            primaryContainer = AFPath.SpriteContainerNode(name: self.name)
        }
    }
}

extension CGPoint {
    init(_ position: vector_float2) { self.x = CGFloat(position.x); self.y = CGFloat(position.y) }

    func as_vector_float2() -> vector_float2 { return [Float(x), Float(y)] }
    
    static func +=(lhs : inout CGPoint, rhs : CGPoint) { lhs.x += rhs.x; lhs.y += rhs.y }
    static func +(lhs : CGPoint, rhs : CGPoint) -> CGPoint { return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func -(lhs : CGPoint, rhs : CGPoint) -> CGPoint { return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
}

