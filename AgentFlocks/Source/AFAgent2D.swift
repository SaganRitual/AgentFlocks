//
//  AFAgent2D.swift
//  AgentFlocks
//
//  Created by Rob Bishop on 12/18/17.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import GameplayKit

protocol AFScenoid {
    func select(primary: Bool)
}

class AFAgent2D_Script: Codable {
    let motivator: AFCompositeBehavior_Script!
    let imageFile: String
    let position: CGPoint
    let mass: Float
    let maxSpeed: Float
    let maxAcceleration: Float
    let name: String
    let radius: Float
    
    init(agent: AFAgent2D) {
        position = CGPoint(x: CGFloat(agent.position.x), y: CGFloat(agent.position.y))
        mass = agent.mass
        maxSpeed = agent.maxSpeed
        maxAcceleration = agent.maxAcceleration
        radius = agent.radius
        name = agent.name
        
        motivator = AFCompositeBehavior_Script(composite: agent.behavior! as! AFCompositeBehavior)
        
        imageFile = ""
    }
}

class AFAgent2D: GKAgent2D, AFScenoid {
    var isPlaying = true
    let originalSize: CGSize
    var radiusIndicator: SKNode?
    let radiusIndicatorRadius: CGFloat = 100.0
    var savedBehaviorState: AFCompositeBehavior?
    var selected = false
    var selectionIndicator: SKNode?
    var showingRadius = false
    let sprite: SKSpriteNode
    let spriteContainer: SKNode

    static var once: Bool = false

    var name: String { get { return sprite.name! } set { return } }
    
    var scale: Float {
        willSet(newValue) {
            let v = CGFloat(newValue)
            sprite.scale(to: CGSize(width: originalSize.width * v, height: originalSize.height * v))
        }
    }
    
    init(scene: GameScene, prototype: AFAgent2D_Script) {
        scale = 1
        
        let (cc, ss) = AFAgent2D.makeSpriteContainer(imageFile: prototype.imageFile, position: prototype.position)
        spriteContainer = cc
        sprite = ss
        
        sprite.name = prototype.name
        
        scene.addChild(spriteContainer)

        originalSize = sprite.size

        super.init()
        
        behavior = AFCompositeBehavior(prototype: prototype.motivator, agent: self)
        
        mass = prototype.mass
        maxSpeed = prototype.maxSpeed
        maxAcceleration = prototype.maxAcceleration
        radius = prototype.radius
    }
    
    init(scene: GameScene, copyFrom: AFAgent2D, position: CGPoint) {
        scale = copyFrom.scale
        
        let (cc, ss) = AFAgent2D.makeSpriteContainer(copyFrom: copyFrom, position: position)
        spriteContainer = cc
        sprite = ss

        spriteContainer.position = position
        scene.addChild(spriteContainer)

        originalSize = sprite.size
        
        super.init()
        
        self.position.x = Float(position.x)
        self.position.y = Float(position.y)

        behavior = AFCompositeBehavior(copyFrom: (copyFrom.behavior as! AFCompositeBehavior), agent: self)
        
        //
        // This is the first data source for agent attributes
        //
        let ac = AFCore.ui.agentEditorController.attributesController
        
        mass = Float(ac.defaultMass)
        maxSpeed = Float(ac.defaultMaxAcceleration)
        maxAcceleration = Float(ac.defaultMaxSpeed)
        radius = Float(ac.defaultRadius)
        scale = Float(ac.defaultScale)
    }

    init(scene: GameScene, image: NSImage, position: CGPoint) {
        scale = 1
        
        let (cc, ss) = AFAgent2D.makeSpriteContainer(image: image, position: position)
        spriteContainer = cc
        sprite = ss
        
        spriteContainer.position = position
        scene.addChild(spriteContainer)

        originalSize = sprite.size
        
        super.init()
        
        behavior = AFCompositeBehavior(agent: self)
        
        let b = AFBehavior(agent: self)
        b.weight = 100
        (behavior as! AFCompositeBehavior).setWeight(100, for: b)

        //
        // This is the first data source for agent attributes
        //
        let ac = AFCore.ui.agentEditorController.attributesController
        
        mass = Float(ac.defaultMass)
        maxSpeed = Float(ac.defaultMaxAcceleration)
        maxAcceleration = Float(ac.defaultMaxSpeed)
        radius = Float(ac.defaultRadius)
        scale = Float(ac.defaultScale)
    }
    
    deinit {
        spriteContainer.removeFromParent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addGoal(_ goal: AFGoal) {
        // The guys who aren't selected have no control over where their
        // new group goal goes. Just put everyone's in a new behavior.
        let b = AFBehavior(agent: self)
        b.setWeightage(goal.weight, for: goal)
        (behavior as! AFCompositeBehavior).setWeight(goal.weight, for: b)
    }

    func deselect() {
        selected = false;
        clearSelectionIndicator()
    }
    
    static func makeSpriteContainer(copyFrom: AFAgent2D, position: CGPoint) -> (SKNode, SKSpriteNode) {
        let texture = SKTexture(imageNamed: "Herman")
        let cgImage = texture.cgImage()
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 50, height: 50))
        
        return makeSpriteContainer(image: nsImage, position: position)
    }
    
    static func makeSpriteContainer(image: NSImage, position: CGPoint, _ name: String? = nil) -> (SKNode, SKSpriteNode) {
        let container = SKNode()
        container.position = position + AFCore.sceneUI.nodeToMouseOffset
        
        container.userData = NSMutableDictionary()
        container.userData!["clickable"] = true
        container.userData!["selectable"] = true
        container.zPosition = CGFloat(AFCore.sceneUI.getNextZPosition())

        var texture: SKTexture!
        
        if image.isValid {
            texture = SKTexture(image: image)
        } else {
            texture = SKTexture(imageNamed: "Herman")
        }
        
        let sprite = SKSpriteNode(texture: texture)

        if let n = name {
            sprite.name = n
        } else {
            sprite.name = NSUUID().uuidString
        }

        container.name = sprite.name
        container.addChild(sprite)
        return (container, sprite)
    }

    static func makeSpriteContainer(imageFile: String, position: CGPoint, _ name: String? = nil) -> (SKNode, SKSpriteNode) {
        let path = Bundle.main.resourcePath!
        let image = NSImage(byReferencingFile: "\(path)/\(imageFile)")!
        return makeSpriteContainer(image: image, position: position, name)
    }

    func select(primary: Bool = true) {
        if let si = selectionIndicator {
            si.removeFromParent()
        }
        
        setSelectionIndicator(primary: primary)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        guard isPlaying else { return }

        super.update(deltaTime: seconds)
        spriteContainer.position = CGPoint(x: Double(position.x), y: Double(position.y))
        spriteContainer.zRotation = CGFloat(Double(rotation) - Double.pi / 2.0)
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
    
    func setSelectionIndicator(primary: Bool = true) {
        selected = true;

        // 40 is just a number that makes the rings look about right to me
        selectionIndicator = AFAgent2D.makeRing(radius: 40, isForSelector: true, primary: primary)
        spriteContainer.addChild(selectionIndicator!)
        
        radiusIndicator = AFAgent2D.makeRing(radius: radius, isForSelector: false, primary: primary)
        spriteContainer.addChild(radiusIndicator!)
    }

    func clearSelectionIndicator() {
        if let si = selectionIndicator {
            si.removeFromParent()
            selectionIndicator = nil
        }
        
        if let ri = radiusIndicator {
            ri.removeFromParent()
            radiusIndicator = nil
        }
    }
}

// MARK : Behaviors & goals

extension AFAgent2D {
    func enableMotivators(_ on: Bool = true) {
        if on {
            behavior = savedBehaviorState
            savedBehaviorState = nil
        } else {
            savedBehaviorState = behavior as? AFCompositeBehavior
            behavior = nil
        }
    }
}

// MARK: Basic agent attributes


extension AFAgent2D: AgentAttributesDelegate {
    func agent(_ controller: AgentAttributesController, newValue value: Double, ofAttribute: AgentAttributesController.Attribute) {
        // This is where we come when the slider is moved around
        let v = Float(value)
        switch ofAttribute {
        case .mass:            mass = v
        case .maxAcceleration: maxAcceleration = v
        case .maxSpeed:        maxSpeed = v
        case .scale:           scale = v

        case .radius:
            radius = v

            if let r = radiusIndicator { r.removeFromParent() }

            radiusIndicator = AFAgent2D.makeRing(radius: radius, isForSelector: false, primary: false)
            spriteContainer.addChild(radiusIndicator!)
            break
        }
    }
    
    func getPrimarySelectedAgent() -> AFAgent2D {
        let name = AFCore.sceneUI.primarySelection!
        return AFCore.data.entities[name].agent
    }
}

