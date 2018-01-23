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

class AFAgent2D: GKAgent2D {
    var selected = false
    
    private unowned let appData: AFDataModel
    private let compositeBehaviorData: AFCompositeBehaviorData
    private let name: String
    private unowned let notifications: NotificationCenter
    private var scale: Float
    private let scene: SKScene
    private var savedBehaviorState: AFCompositeBehavior?
    private var sprites: AFAgent2D.SpriteSet

    var isPaused: Bool {
        get { return sprites.isPaused }
        set { sprites.isPaused = newValue }
    }

    override var position: vector_float2 {
        get { return super.position }
        set { sprites.primaryContainer.position = CGPoint(newValue); super.position = newValue }
    }
    
    init(appData: AFDataModel, embryo: AFAgentData, image: NSImage, position: CGPoint, scene: SKScene) {
        self.appData = appData
        self.compositeBehaviorData = embryo.compositeBehaviorData
        self.name = embryo.name
        self.notifications = appData.notifications
        self.scale = embryo.scale
        self.scene = scene
        self.sprites = AFAgent2D.SpriteSet(image: image, name: embryo.name, scale: embryo.scale, scene: scene)
        
        super.init()
        
        let newBehavior = NSNotification.Name(rawValue: AFDataModel.NotificationType.NewBehavior.rawValue)
        self.notifications.addObserver(self, selector: #selector(newBehavior(_:for:)), name: newBehavior, object: appData)
        
        let newGoal = NSNotification.Name(rawValue: AFDataModel.NotificationType.NewGoal.rawValue)
        self.notifications.addObserver(self, selector: #selector(newGoal(_:parentBehavior:for:)), name: newGoal, object: appData)
        
        let setAttribute = NSNotification.Name(rawValue: AFDataModel.NotificationType.SetAttribute.rawValue)
        self.notifications.addObserver(self, selector: #selector(setAttribute(_:to:for:)), name: setAttribute, object: appData)

        // Use self here, because we want to set the container position too.
        // But it has to happen after superclass init, because it talks to the superclass.
        self.position = position.as_vector_float2()
        
        // Talk directly to super for this initial setting; it serves as our
        // backing store for the agent attributes.
        super.mass = embryo.attributes[.Mass]!
        super.maxAcceleration = embryo.attributes[.MaxAcceleration]!
        super.maxSpeed = embryo.attributes[.MaxSpeed]!
        super.radius = embryo.attributes[.Radius]!
    }
    
    deinit {
        self.notifications.removeObserver(self)
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK - Sprite central for the agent

extension AFAgent2D {
    class SpriteContainerNode: SKNode {
        var agentConnector: NSMutableDictionary { return super.userData! }
        
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

        init(image: NSImage, name: String, scale: Float, scene: SKScene) {
            primaryContainer = AFAgent2D.SpriteContainerNode(name: name)
            self.scale_ = scale
            self.scene = scene
            theSprite = SKSpriteNode(fileNamed: "Barfolama")!
            
            scene.addChild(primaryContainer)
            primaryContainer.addChild(theSprite)
        }
        
        deinit {
            primaryContainer.removeFromParent()
        }

        func hasBeenDeselected() {
            isSelected = false
            isShowingRadius = false
            radiusIndicator.removeFromParent()
            selectionIndicator.removeFromParent()
        }
        
        func hasBeenSelected(primary: Bool) {        // 40 is just a number that makes the rings look about right to me
            isSelected = true
            isShowingRadius = true
            
            selectionIndicator = AFAgent2D.makeRing(radius: 40, isForSelector: true, primary: primary)
            primaryContainer.addChild(selectionIndicator)
            
            radiusIndicator = AFAgent2D.makeRing(radius: radiusIndicatorLength, isForSelector: false, primary: primary)
            primaryContainer.addChild(radiusIndicator)
        }
    }
}

// MARK - Callbacks from the core data manager

extension AFAgent2D: AFDataModelDelegate {
    // We don't register for newagent notifications, but we need this
    // in order to conform to the delegate protocol.
    func newAgent(_ name: String) {}

    func newBehavior(object: Any?) {
        if let (behavior, agent) = object as? (String, String) {
            newBehavior(behavior, for: agent)
        }
    }

    @objc func newBehavior(_ name: String, for agent: String) {
        guard agent == self.name else { return }    // Notifier blasts to everyone
        
        let (behaviorData, weight) = appData.getBehavior(name, from: agent)
        
        (self.behavior as! AFCompositeBehavior).addBehavior(data: behaviorData, scene: self.scene, weight: weight)
    }
    
    func newGoal(object: Any?) {
        if let (goal, behavior, agent) = object as? (String, String, String) {
            newGoal(goal, parentBehavior: behavior, for: agent)
        }
    }
    
    @objc func newGoal(_ name: String, parentBehavior: String, for agent: String) {
        guard agent == self.name else { return }    // Notifier blasts to everyone

        let (goalData, weight) = appData.getGoal(name, parentBehavior: parentBehavior, agent: agent)
        
        let behavior = getBehavior(parentBehavior)
        behavior.aGoalWasCreated(embryo: goalData, weight: weight)
    }
    
    func setAttribute(object: Any?) {
        if let (attribute, value, agent) = object as? (Int, Float, String) {
            setAttribute(attribute, to: value, for: agent)
        }
    }
    
    @objc func setAttribute(_ asInt: Int, to value: Float, for agent: String) {
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

// MARK - most agent attributes talk directly to appData

extension AFAgent2D {
    override var mass: Float {
        get { return super.mass }
        set { appData.setAttribute(.Mass, to: newValue, for: self.name); super.mass = newValue }
    }
    
    override var maxAcceleration: Float {
        get { return super.maxAcceleration }
        set { appData.setAttribute(.MaxAcceleration, to: newValue, for: self.name); super.maxAcceleration = newValue }
    }
    
    override var maxSpeed: Float {
        get { return super.maxSpeed }
        set { appData.setAttribute(.MaxSpeed, to: newValue, for: self.name); super.maxSpeed = newValue }
    }
    
    override var radius: Float {
        get { return super.radius }
        set { appData.setAttribute(.Radius, to: newValue, for: self.name); super.radius = newValue }
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

