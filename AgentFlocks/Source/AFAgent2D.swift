//
//  AFAgent2D.swift
//  AgentFlocks
//
//  Created by Rob Bishop on 12/18/17.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import GameplayKit

class AFAgent2D_: Codable {
    let motivator: AFCompositeBehavior_
    let imageFile: String
    let position: CGPoint
    let mass: Float
    let maxSpeed: Float
    let maxAcceleration: Float
    let radius: Float
}

class AFAgent2D: GKAgent2D {
    var motivator: AFMotivatorCollection?
    let originalSize: CGSize
    var radiusIndicator: SKNode?
    let radiusIndicatorRadius: CGFloat = 100.0
    var selected = false
    var selectionIndicator: SKNode?
    var showingRadius = false
    let sprite: SKSpriteNode
    let spriteContainer: SKNode

    var walls = [GKPolygonObstacle]()

    static var once: Bool = false

    var scale: Float {
        willSet(newValue) {
            let v = CGFloat(newValue)
            sprite.scale(to: CGSize(width: originalSize.width * v, height: originalSize.height * v))
        }
    }

    static var uniqueNameBase = 0
    
    class func makeUniqueName() -> String {
        AFAgent2D.uniqueNameBase += 1
        return String(format: "%5d", AFAgent2D.uniqueNameBase)
    }
    
    init(prototype: AFAgent2D_, name: String) {
        scale = 1
        
        let (cc, ss) = AFAgent2D.makeSpriteContainer(imageFile: prototype.imageFile, position: prototype.position, name)
        spriteContainer = cc
        sprite = ss
        
        GameScene.me!.addChild(spriteContainer)
        
        originalSize = sprite.size

        super.init()
        
        motivator = AFCompositeBehavior(prototype: prototype.motivator, agent: self)
        
        mass = prototype.mass
        maxSpeed = prototype.maxSpeed
        maxAcceleration = prototype.maxAcceleration
        radius = prototype.radius

        applyMotivator()
    }
    
    init(scene: GameScene, image: NSImage, position: CGPoint) {
        scale = 1
        
        let (cc, ss) = AFAgent2D.makeSpriteContainer(image: image, position: position)
        spriteContainer = cc
        sprite = ss
        
        scene.addChild(spriteContainer)
        
        originalSize = sprite.size
        
        super.init()

        let c = AFCompositeBehavior(agent: self)
        motivator = c
        
        let b = AFBehavior(agent: self)
        c.addBehavior(b)
        
        walls = SKNode.obstacles(fromNodeBounds: scene.corral)
        let g = AFGoal(toAvoidObstacles: walls, maxPredictionTime: 2, weight: 1)
        
        b.addGoal(g)
        
        mass = 0.01
        maxSpeed = 1000
        maxAcceleration = 1000
        radius = 50

        applyMotivator()
    }
    
    deinit {
        spriteContainer.removeFromParent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func deselect() {
        selected = false;
        clearSelectionIndicator()
    }
    
    static func makeSpriteContainer(image: NSImage, position: CGPoint, _ name: String? = nil) -> (SKNode, SKSpriteNode) {
        let node = SKNode()
        node.position = position
        
        let texture = SKTexture(image: image)
        let sprite = SKSpriteNode(texture: texture)
        sprite.zPosition = 0
        node.addChild(sprite)
        
        if let n = name {
            sprite.name = n
        } else {
            sprite.name = NSUUID().uuidString
        }
        
        return (node, sprite)
    }

    static func makeSpriteContainer(imageFile: String, position: CGPoint, _ name: String? = nil) -> (SKNode, SKSpriteNode) {
        let path = Bundle.main.resourcePath!
        let image = NSImage(byReferencingFile: "\(path)/\(imageFile)")
        return makeSpriteContainer(image: image!, position: position, name)
    }

    func select(primary: Bool = true) {
        if let si = selectionIndicator {
            si.removeFromParent()
        }
        
        setSelectionIndicator(primary: primary)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
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

extension AFAgent2D {
    func addGoal(_ goal: AFGoal) {
        let b = AFBehavior(agent: self)
        (motivator! as! AFCompositeBehavior).addBehavior(b)
        
        b.addGoal(goal)
        applyMotivator()
    }

    func applyMotivator() {
        guard motivator != nil else { return }

        switch motivator {
        case let m as AFBehavior:
            behavior = createBehavior(from: m)

        case let m as AFCompositeBehavior:
            behavior = createComposite(from: m)

        default: fatalError()
        }
    }
    
    func createBehavior(from: AFBehavior) -> GKBehavior {
        let behavior = GKBehavior()
        
        for goal in from.goals {
            behavior.setWeight(goal.weight, for: goal.goal)
        }
        
        return behavior
    }
    
    func createComposite(from: AFCompositeBehavior) -> GKCompositeBehavior {
        let composite = GKCompositeBehavior()
        
        for mvBehavior in from.behaviors {
            let gkBehavior = createBehavior(from: mvBehavior)
            composite.setWeight(mvBehavior.weight, for: gkBehavior)
        }
        
        return composite
    }
}

extension AFAgent2D: AgentAttributesDelegate {
    func agent(_ controller: AgentAttributesController, newValue value: Double, ofAttribute: AgentAttributesController.Attribute) {
        let v = Float(value)
        switch ofAttribute {
        case .mass: mass = v; break
        case .maxAcceleration: maxAcceleration = v; break
        case .maxSpeed: maxSpeed = v; break
        case .radius:
            radius = v

            if let r = radiusIndicator { r.removeFromParent() }

            radiusIndicator = AFAgent2D.makeRing(radius: radius, isForSelector: false, primary: false)
            spriteContainer.addChild(radiusIndicator!)
            break
        case .scale: scale = v; break
        }
    }
}

