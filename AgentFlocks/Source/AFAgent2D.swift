//
// Created by Rob Bishop on 1/22/18
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

import Foundation
import GameplayKit

protocol AFAgentDelegate {
    func newBehavior(for agent: String, weight: Float)
    func newGoal(for agent: String, parentBehavior: String, weight: Float)
    func setAttribute(_ attribute: AFAgentAttribute, to value: Float, for agent: String)
}

extension Foundation.Notification.Name {
    static let CoreDataChanged = Foundation.Notification.Name("CoreDataChanged")
    static let SelectionChanged = Foundation.Notification.Name("SelectionChanged")
}

class AFAgent2D: GKAgent2D, AgentAttributesDelegate, AFSceneControllerDelegate {
    
    private unowned let core: AFCore
    private unowned let dataNotifications: Foundation.NotificationCenter
    private let gameScene: SKScene
    let name: String
    private var savedBehaviorState: AFCompositeBehavior?
    private var spriteSet: AFAgent2D.SpriteSet!
    private unowned let uiNotifications: Foundation.NotificationCenter

    var isPaused: Bool {
        get { return spriteSet.primaryContainer.isPaused }
        set { spriteSet.primaryContainer.isPaused = newValue }
    }

    override var position: vector_float2 {
        get { return super.position }
        set { spriteSet.primaryContainer.position = CGPoint(newValue); super.position = newValue }
    }
    
    init(core: AFCore, editor: AFAgentEditor, image: NSImage, position: CGPoint, gameScene: SKScene) {
        self.core = core
        self.name = editor.name
        self.dataNotifications = core.bigData.notifier
        self.uiNotifications = core.sceneController.uiNotifications
        self.gameScene = gameScene

        super.init()

        self.spriteSet = AFAgent2D.SpriteSet(owningAgent: self, image: image, name: editor.name, scale: editor.scale, gameScene: gameScene)

        // These notifications come from the data
        let n1 = Foundation.Notification.Name.CoreDataChanged
        let s1 = #selector(coreDataChanged(notification:))
        self.dataNotifications.addObserver(self, selector: s1, name: n1, object: nil)
        
        // These notifications come from the selection controller
        let n2 = Foundation.Notification.Name.SelectionChanged
        let s2 = #selector(coreDataChanged(notification:))
        self.uiNotifications.addObserver(self, selector: s2, name: n2, object: nil)

        // Use self here, because we want to set the container position too.
        // But it has to happen after superclass init, because it talks to the superclass.
        self.position = position.as_vector_float2()
        
        // Attach myself to the primary sprite. That's where I'll live;
        // no one but the sprite has a reference to me.
        self.spriteSet.attachToSprite(self)
        self.spriteSet.primaryContainer.scale = CGFloat(editor.scale)
    }
    
    deinit {
        self.dataNotifications.removeObserver(self)
        self.uiNotifications.removeObserver(self)
    }
    
    func enableMotivators(_ on: Bool = true) {
        if on { behavior = savedBehaviorState; savedBehaviorState = nil }
        else { savedBehaviorState = behavior as? AFCompositeBehavior; behavior = nil }
    }

    func getBehavior(_ name: String) -> AFBehavior {
        let composite = self.behavior as! AFCompositeBehavior
        for i in 0 ..< composite.behaviorCount {
            let behavior = composite[i] as! AFBehavior
            if behavior.name == name { return behavior }
        }
        
        fatalError()
    }
    
    @objc func hasBeenDeselected(notification: Foundation.Notification) {
        let name = notification.object as? String
        hasBeenDeselected(name)
    }
    
    // name == nil means everyone
    func hasBeenDeselected(_ name: String?) {
        if name == nil || name! == self.name {
            spriteSet.hasBeenDeselected(name)
        }
    }

    @objc func hasBeenSelected(notification: Foundation.Notification) {
        let (name, primary) = notification.object as! (String, Bool)
        hasBeenSelected(name, primary: primary)
    }
    
    func hasBeenSelected(_ name: String, primary: Bool) {
        if name == self.name {
            spriteSet.hasBeenSelected(primary: primary)
        }
    }
    
    func move(to position: CGPoint) {
        self.position = position.as_vector_float2()
        spriteSet.move(to: position)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK - Sprite central for the agent

extension AFAgent2D {
    class SpriteContainerNode: SKNode {
        init(name: String) {
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
        var isSelected: Bool { get { return userData!["isSelected"] as! Bool } set { userData!["isSelected"] = newValue } }
        var isShowingRadius: Bool { get { return userData!["isShowingRadius"] as! Bool } set { userData!["isShowingRadius"] = newValue } }
        
        var scale: CGFloat { get { return userData!["scale"] as! CGFloat} set { userData!["scale"] = newValue } }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class SpriteSet {
        let primaryContainer: AFAgent2D.SpriteContainerNode
        var radiusIndicator: SKNode!
        let radiusIndicatorLength: Float = 100
        unowned let gameScene: SKScene
        var selectionIndicator: SKNode!
        let theSprite: SKSpriteNode

        init(owningAgent: AFAgent2D, image: NSImage, name: String, scale: Float, gameScene: SKScene) {
            self.gameScene = gameScene

            primaryContainer = AFAgent2D.SpriteContainerNode(name: name)

            let texture = SKTexture(image: image)
            theSprite = SKSpriteNode(texture: texture)
            theSprite.name = name

            gameScene.addChild(primaryContainer)
            primaryContainer.addChild(theSprite)
        }
        
        deinit {
            primaryContainer.removeFromParent()
        }
        
        func attachToSprite(_ agent: AFAgent2D) {
            primaryContainer.userData!["agent"] = agent
        }

        func hasBeenDeselected(_ name: String?) {
            // nil means everyone has been deselected. Otherwise
            // it might be someone else being deselected, so I
            // have to check whose name is being called.
            if name == nil || name! == primaryContainer.name! {
                primaryContainer.isSelected = false
                primaryContainer.isShowingRadius = false
                radiusIndicator?.removeFromParent()
                selectionIndicator?.removeFromParent()
            }
        }
        
        func hasBeenSelected(primary: Bool) {
            primaryContainer.isSelected = true
            primaryContainer.isShowingRadius = true
            
            // 40 is just a number that makes the rings look about right to me
            selectionIndicator = AFAgent2D.makeRing(radius: 40, isForSelector: true, primary: primary)
            primaryContainer.addChild(selectionIndicator)
            
            radiusIndicator = AFAgent2D.makeRing(radius: radiusIndicatorLength, isForSelector: false, primary: primary)
            primaryContainer.addChild(radiusIndicator)
        }
        
        func move(to position: CGPoint) {
            primaryContainer.position = position
        }
    }
}

// MARK - Callbacks from the core data manager

extension AFAgent2D {
    // We don't register for newagent notifications, but we need this
    // in order to conform to the delegate protocol.
    func newAgent(_ name: String) {}

    @objc func coreDataChanged(notification: Foundation.Notification) {
    }
    
    func anAttributeHasChanged(_ asString: String, to value: Float, for agent: String) {
        guard agent == self.name else { return }    // Notifier blasts to everyone

        switch AFAgentAttribute(rawValue: asString)! {
        case .isPaused:        break
        case .mass:            self.mass = value
        case .maxAcceleration: self.maxAcceleration = value
        case .maxSpeed:        self.maxSpeed = value
        case .radius:          self.radius = value
        case .scale:           self.spriteSet.primaryContainer.setScale(CGFloat(value));
        }
    }
}

extension AFAgent2D {
    func agent(_ controller: AgentAttributesController, newValue value:Double, ofAttribute:AgentAttributesController.Attribute) {
        print("callback from AgentAttributesController")
    }
}

// MARK: selection indicator show/hide

extension AFAgent2D {
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

