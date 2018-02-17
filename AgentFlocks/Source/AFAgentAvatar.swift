//
// Created by Rob Bishop on 2/13/18
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

class AFAgentAvatar {
    private let spriteSet: SpriteSet

    init(_ name: String, core: AFCore, image: NSImage, position: CGPoint) {
        self.spriteSet = SpriteSet(name, core: core, image: image, position: position)
    }
    
    func handoffToSprite() { spriteSet.handoffToSprite(self) }
    
    func makeNodeComponent() -> GKSKNodeComponent {
        return GKSKNodeComponent(node: spriteSet.primaryContainer)
    }
}

extension AFAgentAvatar {
    class SpriteContainerNode: SKNode {
        init(_ name: String) {
            super.init()
            super.name = name

            userData = NSMutableDictionary()
            
            // Set these fields directly rather than using an adapter, because
            // in the adapter, these fields are read-only.
            backdoorSet(.isClickable, to: true)
            backdoorSet(.isPath, to: false)
            backdoorSet(.isPathHandle, to: false)
            backdoorSet(.isPrimarySelection, to: false)
            backdoorSet(.isSelected, to: false)
            backdoorSet(.isShowingRadius, to: false)
            
            backdoorSet(.scale, to: CGFloat(1.0))
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
        
private extension AFAgentAvatar.SpriteContainerNode {
    func backdoorSet(_ field: State, to: Any) { setField(field, to: to) }
    
    func getBool(_ field: State) -> Bool { return getField(field) as! Bool }
    func setBool(_ field: State, to: Bool) { setField(field, to: to) }
    
    func getCGFloat(_ field: State) -> CGFloat { return getField(field) as! CGFloat }
    func setCGFloat(_ field: State, to: CGFloat) { setField(field, to: to) }

    func getField(_ field: State) -> Any { return userData![field]! }
    func setField(_ field: State, to: Any) { userData![field] = to }
}

// MARK: Public functions for the sprite container node

extension AFAgentAvatar.SpriteContainerNode {
    public enum State {
        case isClickable, isPath, isPathHandle, isPrimarySelection, isSelected, isShowingRadius, scale
    }

    var isClickable: Bool { return getBool(.isClickable) }
    var isPath: Bool { return getBool(.isPath) }
    var isPathHandle: Bool { return getBool(.isPathHandle) }
    var isPrimarySelection: Bool { get { return getBool(.isPrimarySelection) } set { setBool(.isPrimarySelection, to: newValue) } }
    var isSelected: Bool { get { return getBool(.isSelected) }  set { setBool(.isSelected, to: newValue) } }
    var isShowingRadius: Bool { get { return getBool(.isShowingRadius) } set { setBool(.isShowingRadius, to: newValue) } }
    
    var scale: CGFloat { get { return getCGFloat(.scale) } set { setCGFloat(.scale, to: newValue) } }
}

private extension AFAgentAvatar {
    
    class SpriteSet {
        unowned let core: AFCore
        unowned let gameScene: SKScene
        let primaryContainer: AFAgentAvatar.SpriteContainerNode
        var radiusIndicator: SKNode!
        let radiusIndicatorLength: Float = 100
        var selectionIndicator: SKNode!
        unowned let uiNotifications: Foundation.NotificationCenter

        init(_ name: String, core: AFCore, image: NSImage, position: CGPoint) {
            self.core = core
            self.gameScene = core.sceneController.gameScene
            self.uiNotifications = core.ui.uiNotifications
            
            primaryContainer = SpriteContainerNode(name)
            primaryContainer.position = position
            
            let texture = SKTexture(image: image)
            let theSprite = SKSpriteNode(texture: texture)
            theSprite.name = name
            
            gameScene.addChild(primaryContainer)
            primaryContainer.addChild(theSprite)

            // These notifications come from the selection controller
            let s1 = #selector(hasBeenDeselected(notification:))
            self.uiNotifications.addObserver(self, selector: s1, name: .Deselected, object: nil)
            
            let s2 = #selector(hasBeenSelected(notification:))
            self.uiNotifications.addObserver(self, selector: s2, name: .Selected, object: nil)
        }

        deinit {
            primaryContainer.removeFromParent()
            uiNotifications.removeObserver(self)
        }
        
        func handoffToSprite(_ agent: AFAgentAvatar) {
            primaryContainer.userData!["agent"] = agent
        }
        
        @objc func hasBeenDeselected(notification: Foundation.Notification) {
            let decoded = AFSceneController.Notification.Decode(notification)
            hasBeenDeselected(decoded.name)
        }

        func hasBeenDeselected(_ name: String?) {
            // nil means everyone has been deselected. Otherwise
            // it might be someone else being deselected, so I
            // have to check whose name is being called.
            if name == nil || name! == primaryContainer.name! {
                primaryContainer.isPrimarySelection = false
                primaryContainer.isSelected = false
                primaryContainer.isShowingRadius = false
                if let r = radiusIndicator { r.removeFromParent(); radiusIndicator = nil }
                if let s = selectionIndicator { s.removeFromParent(); selectionIndicator = nil }
            }
        }
        
        @objc func hasBeenSelected(notification: Foundation.Notification) {
            let decoded = AFSceneController.Notification.Decode(notification)
            guard decoded.name == primaryContainer.name! else { return }

            hasBeenSelected(primary: decoded.isPrimarySelection!)
        }

        func hasBeenSelected(primary: Bool) {
            // If we're already in the desired selection state,
            // then there's nothing to do here. The notifier blasts out selection state
            // indiscriminately, so we have to check whether we've already taken care of it.
            guard !(primaryContainer.isSelected && primaryContainer.isPrimarySelection == primary) else { return }
            
            primaryContainer.isPrimarySelection = primary
            primaryContainer.isSelected = true
            primaryContainer.isShowingRadius = true
            
            // 40 is just a number that makes the rings look about right to me
            selectionIndicator = AFAgentAvatar.makeRing(radius: 40, isForSelector: true, primary: primary)
            primaryContainer.addChild(selectionIndicator)
            
            radiusIndicator = AFAgentAvatar.makeRing(radius: radiusIndicatorLength, isForSelector: false, primary: primary)
            primaryContainer.addChild(radiusIndicator)
        }
        
        func move(to position: CGPoint) {
            primaryContainer.position = position
        }
    }
}

extension AFAgentAvatar {
    static func makeRing(radius: Float, isForSelector: Bool, primary: Bool) -> SKNode {
        let ring = SKNode()
        
        var firstPosition: CGPoint!
        var lastPosition: CGPoint!
        let path = CGMutablePath()
        for theta in stride(from: 0, to: Float.pi * 2, by: Float.pi / 16) {
            let r = CGFloat(radius)
            let x = r * CGFloat(cos(theta)); let y = r * CGFloat(sin(theta))
            
            if firstPosition == nil {
                firstPosition = CGPoint(x: x, y: y)
            }
            
            if theta > 0 {
                path.addLine(to: CGPoint(x: x, y: y))
                let line = SKShapeNode(path: path)
                ring.addChild(line)
                line.strokeColor = primary ? .green : .yellow
            }
            
            lastPosition = CGPoint(x: x, y: y)
            path.move(to: lastPosition)
        }
        
        path.addLine(to: firstPosition)
        let line = SKShapeNode(path: path)
        ring.addChild(line)
        
        if isForSelector {
            line.strokeColor = primary ? .green : .yellow
        } else {
            line.strokeColor = .red
        }
        
        return ring
    }
}
