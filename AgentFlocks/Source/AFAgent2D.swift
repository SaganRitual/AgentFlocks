//
//  AFAgent2D.swift
//  AgentFlocks
//
//  Created by Rob Bishop on 12/18/17.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import GameplayKit

class AFAgent2D: GKAgent2D {
    var motivator: AFMotivatorCollection?
    let originalSize: CGSize
    let spriteContainer: SKNode
    let radiusIndicator: SKShapeNode
    let radiusIndicatorRadius: CGFloat = 100.0
    let sprite: SKSpriteNode
    
    var walls = [GKPolygonObstacle]()
    
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
    
    init(scene: GameScene, image: NSImage, position: CGPoint) {
        scale = 1
        
        spriteContainer = SKNode()
        spriteContainer.position = position
        
        let texture = SKTexture(image: image)
        sprite = SKSpriteNode(texture: texture)
        sprite.name = AFAgent2D.makeUniqueName()
        sprite.zPosition = 0
        spriteContainer.addChild(sprite)
        
        // 0.5 is the default radius for agents
        radiusIndicator = SKShapeNode(circleOfRadius: 25)
        radiusIndicator.fillColor = .red
        radiusIndicator.alpha = 0.5
        radiusIndicator.zPosition = 1
        spriteContainer.addChild(radiusIndicator)
        
        scene.addChild(spriteContainer)
        
        originalSize = sprite.size
        
        super.init()

        let c = AFCompositeBehavior(agent: self)
        motivator = c
        
        let b = AFBehavior(agent: self)
        c.addBehavior(b)
        
        walls = SKNode.obstacles(fromNodeBounds: scene.corral)
        let g = AFGoal(toAvoidObstacles: walls, maxPredictionTime: 2, weight: 1000)
        
        b.addGoal(g)

        applyMotivator()
        
        mass = 0.1
        maxAcceleration = 1000
        maxSpeed = 1000
        radius = 25
        scale = 1
    }
    
    deinit {
        spriteContainer.removeFromParent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        spriteContainer.position = CGPoint(x: Double(position.x), y: Double(position.y))
        spriteContainer.zRotation = CGFloat(Double(rotation) - Double.pi / 2.0)
    }
}

extension AFAgent2D {
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
            composite.setWeight(100/*mvBehavior.weight*/, for: gkBehavior)
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
        case .radius: radius = v; break
        case .scale: scale = v; break
        }
    }
}

