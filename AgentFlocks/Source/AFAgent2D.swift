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

import GameplayKit

enum AFAgentAttribute: Int { case Mass, MaxAcceleration, MaxSpeed, Radius, Scale }

protocol AFAgentDelegate {
    func newBehavior(for agent: String, weight: Float)
    func newGoal(for agent: String, parentBehavior: String, weight: Float)
    func setAttribute(_ attribute: AFAgentAttribute, for agent: String, to value: Float)
}

class AFAgent2D: GKAgent2D, AFSceneControllerDelegate {
    
    var selected = false
    
    private unowned let coreData: AFCoreData
    let name: String
    private unowned let coreNotifier: NotificationCenter
    private var scale: Float
    private let scene: SKScene
    private var savedBehaviorState: AFCompositeBehavior?
    private var spriteSet: AFAgent2D.SpriteSet!
    private unowned let uiNotifier: NotificationCenter

    var isPaused: Bool {
        get { return spriteSet.isPaused }
        set { spriteSet.isPaused = newValue }
    }

    override var position: vector_float2 {
        get { return super.position }
        set { spriteSet.primaryContainer.position = CGPoint(newValue); super.position = newValue }
    }
    
    init(coreData: AFCoreData, editor: AFAgentEditor, image: NSImage, position: CGPoint, scene: SKScene) {
        self.coreData = coreData
        self.name = editor.name
        self.coreNotifier = coreData.notifier
        self.uiNotifier = coreData.core.sceneUI.notificationsSender
        self.scale = editor.scale
        self.scene = scene
        
        super.init()

        self.spriteSet = AFAgent2D.SpriteSet(owningAgent: self, image: image, name: editor.name, scale: editor.scale, scene: scene)

        // These notifications come from the data; notice we're listening on dataNotifications
        let newBehavior = NSNotification.Name(rawValue: AFCoreData.NotificationType.NewBehavior.rawValue)
        self.coreNotifier.addObserver(self, selector: #selector(newBehavior(notification:)), name: newBehavior, object: coreData)
        
        let newGoal = NSNotification.Name(rawValue: AFCoreData.NotificationType.NewGoal.rawValue)
        self.coreNotifier.addObserver(self, selector: #selector(newGoal(notification:)), name: newGoal, object: coreData)
        
        let setAttribute = NSNotification.Name(rawValue: AFCoreData.NotificationType.SetAttribute.rawValue)
        self.coreNotifier.addObserver(self, selector: #selector(setAttribute(notification:)), name: setAttribute, object: coreData)
        
        // These notifications come from the UI; notice we're listening on uiNotifications
        let select = NSNotification.Name(rawValue: AFSceneController.NotificationType.Selected.rawValue)
        self.uiNotifier.addObserver(self, selector: #selector(hasBeenSelected(notification:)), name: select, object: nil)
        
        let deselect = NSNotification.Name(rawValue: AFSceneController.NotificationType.Deselected.rawValue)
        self.uiNotifier.addObserver(self, selector: #selector(hasBeenDeselected(notification:)), name: deselect, object: nil)

        // Use self here, because we want to set the container position too.
        // But it has to happen after superclass init, because it talks to the superclass.
        self.position = position.as_vector_float2()
        
        // Attach myself to the primary sprite. That's where I'll live;
        // no one but the sprite has a reference to me.
        self.spriteSet.attachToSprite(self)

        let agentAdapter = AFNodeAdapter(scene: self.scene, name: self.name)
    }
    
    deinit {
        self.coreNotifier.removeObserver(self)
        self.uiNotifier.removeObserver(self)
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
    
    @objc func hasBeenDeselected(notification: Notification) {
        let name = notification.object as? String
        hasBeenDeselected(name)
    }
    
    // name == nil means everyone
    func hasBeenDeselected(_ name: String?) {
        if name == nil || name! == self.name {
            spriteSet.hasBeenDeselected(name)
        }
    }

    @objc func hasBeenSelected(notification: Notification) {
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
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class SpriteSet {
        var isSelected = false
        var isShowingRadius = false
        let primaryContainer: AFAgent2D.SpriteContainerNode
        var radiusIndicator: SKNode!
        let radiusIndicatorLength: Float = 100
        unowned let scene: SKScene
        var selectionIndicator: SKNode!
        let theSprite: SKSpriteNode
        
        var isPaused: Bool {
            get { return primaryContainer.isPaused }
            set { primaryContainer.isPaused = newValue }
        }
        
        var scale_: Float = 1
        var scale: Float {
            get { return scale_ }
            set { primaryContainer.setScale(CGFloat(newValue)) ; scale_ = newValue }
        }

        init(owningAgent: AFAgent2D, image: NSImage, name: String, scale: Float, scene: SKScene) {
            self.scale_ = scale
            self.scene = scene

            primaryContainer = AFAgent2D.SpriteContainerNode(name: name)

            let texture = SKTexture(image: image)
            theSprite = SKSpriteNode(texture: texture)
            theSprite.name = name
            print("Another name for theSprite: ", Nickname(name))
            
            primaryContainer.userData = NSMutableDictionary()
            
            primaryContainer.userData!["isClickable"] = true
            primaryContainer.userData!["isAgent"] = true
            primaryContainer.userData!["isPath"] = false
            primaryContainer.userData!["isPathHandle"] = false
            primaryContainer.userData!["isPrimarySelection"] = false
            primaryContainer.userData!["isSelected"] = false

            primaryContainer.userData!["barf"] = "chunks"
            print(primaryContainer.userData!["barf"]!)

            scene.addChild(primaryContainer)
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
                isSelected = false
                isShowingRadius = false
                radiusIndicator.removeFromParent()
                selectionIndicator.removeFromParent()
            }
        }
        
        func hasBeenSelected(primary: Bool) {
            isSelected = true
            isShowingRadius = true
            
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

    @objc func newBehavior(notification: Notification) {
        let (behavior, agent) = notification.object as! (String, String)
        newBehavior(behavior, weight: 1)
    }

    func newBehavior(_ name: String, weight: Float) {
        guard name == self.name else { return }    // Notifier blasts to everyone
        
//        let (behaviorEditor, _) = composite.createBehavior(weight: weight)
        
//        (self.compositeEditor as! AFCompositeEditor).addBehavior(editor: behaviorEditor, scene: self.scene, weight: weight)
    }
    
    @objc func newGoal(notification: Notification) {
        if let (goal, _, _) = notification.object as? (String, String, String) {
            newGoal(goal, weight: 1)
        }
    }
    
    func newGoal(_ name: String, weight: Float) {
//        guard name == self.name else { return }    // Notifier blasts to everyone
//
//        let (goalEditor, _) = coreData.core.createGoal(name, weight: weight)
//        let behavior = getBehavior(goalEditor)
//        behavior.aGoalWasCreated(editor: goalEditor, weight: weight)
    }
    
    @objc func setAttribute(notification: Notification) {
        if let (attribute, value, agent) = notification.object as? (Int, Float, String) {
            setAttribute(attribute, to: value, for: agent)
        }
    }
    
    func setAttribute(_ asInt: Int, to value: Float, for agent: String) {
        guard agent == self.name else { return }    // Notifier blasts to everyone

        switch AFAgentAttribute(rawValue: asInt)! {
        case .Mass:            self.mass = value
        case .MaxAcceleration: self.maxAcceleration = value
        case .MaxSpeed:        self.maxSpeed = value
        case .Radius:          self.radius = value
        case .Scale:           self.scale = value
        }
    }
}

// MARK - most agent attributes talk directly to coreData

extension AFAgent2D {
    override var mass: Float {
        get { return super.mass }
        set { setAttribute(AFAgentAttribute.Mass.rawValue, to: newValue, for: self.name); super.mass = newValue }
    }
    
    override var maxAcceleration: Float { set { super.maxAcceleration = newValue }
        get { return super.maxAcceleration }
//        set { coreData.core.setAttribute(AFAgentAttribute.MaxAcceleration.rawValue, to: newValue, for: self.name); super.maxAcceleration = newValue }
    }
    
    override var maxSpeed: Float { set { super.maxSpeed = newValue }
        get { return super.maxSpeed }
//        set { coreData.core.setAttribute(AFAgentAttribute.MaxSpeed.rawValue, to: newValue, for: self.name); super.maxSpeed = newValue }
    }
    
    override var radius: Float { set { super.radius = newValue }
        get { return super.radius }
//        set { coreData.core.setAttribute(AFAgentAttribute.Radius.rawValue, to: newValue, for: self.name); super.radius = newValue }
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

