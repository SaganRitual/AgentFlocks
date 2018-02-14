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

private extension AFAgentAvatar {

    class SpriteContainerNode: SKNode {
        init(_ name: String) {
            super.init()
            super.name = name

            userData = NSMutableDictionary()
            
            // Set these fields directly rather than using an adapter, because
            // in the adapter, these fields are read-only.
            userData!["isAgent"] = true
            userData!["isClickable"] = true
            userData!["isPath"] = false
            userData!["isPathHandle"] = false
            userData!["isPrimarySelection"] = false
            userData!["isSelected"] = false
            userData!["isShowingRadius"] = false
            
            userData!["scale"] = CGFloat(1.0)
        }

        var isAgent: Bool { return userData!["isAgent"] as! Bool }
        var isClickable: Bool { return userData!["isClickable"] as! Bool }
        var isPath: Bool { return userData!["isPath"] as! Bool }
        var isPathHandle: Bool { return userData!["isPathHandle"] as! Bool }
        var isPrimarySelection: Bool { get { return userData!["isPrimarySelection"] as! Bool } set { userData!["isPrimarySelection"] = newValue } }
        var isSelected: Bool { get { return userData!["isSelected"] as! Bool }  set { userData!["isSelected"] = newValue } }
        var isShowingRadius: Bool { get { return userData!["isShowingRadius"] as! Bool } set { userData!["isShowingRadius"] = newValue } }
        
        var scale: CGFloat { get { return userData!["scale"] as! CGFloat} set { userData!["scale"] = newValue } }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
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
                primaryContainer.isSelected = false
                primaryContainer.isShowingRadius = false
                if let r = radiusIndicator { r.removeFromParent() }
                if let s = selectionIndicator { s.removeFromParent() }
            }
        }
        
        @objc func hasBeenSelected(notification: Foundation.Notification) {
            let decoded = AFSceneController.Notification.Decode(notification)
            guard decoded.name == primaryContainer.name! else { return }

            hasBeenSelected(primary: decoded.isPrimary!)
        }

        func hasBeenSelected(primary: Bool) {
            guard !primaryContainer.isSelected else { fatalError() }
            
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
