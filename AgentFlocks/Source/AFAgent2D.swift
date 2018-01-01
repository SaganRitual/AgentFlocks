//
//  AFAgent2D.swift
//  AgentFlocks
//
//  Created by Rob Bishop on 12/18/17.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import GameplayKit

extension Date {
    var millisecondsSince1970:Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}

class AFAgent2D: GKAgent2D {
    var motivator: AFMotivatorCollection?
    let originalSize: CGSize
    let radiusIndicator: SKShapeNode
    let radiusIndicatorRadius: CGFloat = 100.0
    var selected = false
    let selectionIndicator: SKShapeNode
    var showingRadius = true
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
        radiusIndicator.zPosition = -1
        spriteContainer.addChild(radiusIndicator)
        
        selectionIndicator = SKShapeNode(circleOfRadius: 15)
        selectionIndicator.fillColor = .blue
        selectionIndicator.zPosition = 2
        selectionIndicator.alpha  = 0
        spriteContainer.addChild(selectionIndicator)

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

//        let points = [
//            GKGraphNode2D(point: vector_float2(0, 800)),
//            GKGraphNode2D(point: vector_float2(800, 800)),
//            GKGraphNode2D(point: vector_float2(800, 0)),
//            GKGraphNode2D(point: vector_float2(0, 0))
//        ]
//        
//        let path = GKPath(graphNodes: points, radius: 1)
//        let date = Date()
//        let tf = (date.millisecondsSince1970 & 1) == 1
//        let pathGoal = AFGoal(toFollow: path, maxPredictionTime: 1, forward: tf, weight: 100)
//        
//        if !AFAgent2D.once {
//            b.addGoal(pathGoal)
//            AFAgent2D.once = true
//        }
        
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
    
    func deselect() { selected = false; selectionIndicator.alpha = 0 }
    func select(primary: Bool = true) {
        selected = true;
        selectionIndicator.alpha = 1

        selectionIndicator.fillColor = primary ? .blue : .green
    }
    
    func showRadius(_ show: Bool) {
        radiusIndicator.alpha = (show ? 0.5 : 0)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        spriteContainer.position = CGPoint(x: Double(position.x), y: Double(position.y))
        spriteContainer.zRotation = CGFloat(Double(rotation) - Double.pi / 2.0)
    }
}

// MARK: selection indicator show/hide

extension AFAgent2D {
    func setSelectionIndicator() { selectionIndicator.alpha = 1 }
    func clearSelectionIndicator() { selectionIndicator.alpha = 0 }
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
        case .radius: radius = v; break
        case .scale: scale = v; break
        }
    }
}

