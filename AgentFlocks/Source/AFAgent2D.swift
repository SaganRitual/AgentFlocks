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
}

class AFAgent2D: GKAgent2D {
    var motivator: AFMotivatorCollection?
    let originalSize: CGSize
    let radiusIndicator: SKShapeNode
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
    
    init(prototype: AFAgent2D_) {
        scale = 1
        
        let (cc, ss, rr) = AFAgent2D.makeSpriteContainer(imageFile: prototype.imageFile, position: prototype.position)
        spriteContainer = cc
        sprite = ss
        radiusIndicator = rr
        
        GameScene.me!.addChild(spriteContainer)
        
        originalSize = sprite.size

        super.init()
        
        motivator = AFCompositeBehavior(prototype: prototype.motivator, agent: self)
        
        mass = 0.01
        maxSpeed = 1000
        maxAcceleration = 1000
        radius = 50

        applyMotivator()
    }
    
    init(scene: GameScene, image: NSImage, position: CGPoint) {
        scale = 1
        
        let (cc, ss, rr) = AFAgent2D.makeSpriteContainer(image: image, position: position)
        spriteContainer = cc
        sprite = ss
        radiusIndicator = rr
        
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
    
    static func makeSpriteContainer(image: NSImage, position: CGPoint) -> (SKNode, SKSpriteNode, SKShapeNode) {
        let node = SKNode()
        node.position = position
        
        let texture = SKTexture(image: image)
        let sprite = SKSpriteNode(texture: texture)
        sprite.name = AFAgent2D.makeUniqueName()
        sprite.zPosition = 0
        node.addChild(sprite)
        
        // 0.5 is the default radius for agents
        let radiusIndicator = SKShapeNode(circleOfRadius: 25)
        radiusIndicator.fillColor = .red
        radiusIndicator.alpha = 0
        radiusIndicator.zPosition = -1
        node.addChild(radiusIndicator)
        
        return (node, sprite, radiusIndicator)
    }

    static func makeSpriteContainer(imageFile: String, position: CGPoint) -> (SKNode, SKSpriteNode, SKShapeNode) {
        let image = NSImage(byReferencingFile: imageFile)
        return makeSpriteContainer(image: image!, position: position)
    }

    func select(primary: Bool = true) {
        if let si = selectionIndicator {
            si.removeFromParent()
        }
        
        setSelectionIndicator(primary: primary)
    }
    
    func showRadius(_ show: Bool) {
        radiusIndicator.alpha = (show ? 0.5 : 0)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        spriteContainer.position = CGPoint(x: Double(position.x), y: Double(position.y))
        spriteContainer.zRotation = CGFloat(Double(rotation) - Double.pi / 2.0)
        print(spriteContainer.position, spriteContainer.zRotation)
    }
}

// MARK: selection indicator show/hide

extension AFAgent2D {
    func setSelectionIndicator(primary: Bool = true) {
        selectionIndicator = SKNode()
        
        var firstPosition: CGPoint!
        var lastPosition: CGPoint!
        let path = CGMutablePath()
        for theta in stride(from: 0, to: Float.pi * 2, by: Float.pi / 8) {
            let x = 40 * Double(cos(theta)); let y = 40 * Double(sin(theta))
            
            if firstPosition == nil {
                firstPosition = CGPoint(x: x, y: y)
            }

            if theta > 0 {
                path.addLine(to: CGPoint(x: x, y: y))
                let line = SKShapeNode(path: path)
                selectionIndicator!.addChild(line)
                line.strokeColor = primary ? .green : .yellow
            }
            
            lastPosition = CGPoint(x: x, y: y)
            path.move(to: lastPosition)
        }
        
        path.addLine(to: firstPosition)
        let line = SKShapeNode(path: path)
        selectionIndicator!.addChild(line)
        line.strokeColor = primary ? .green : .yellow
        
        selected = true;
        spriteContainer.addChild(selectionIndicator!)
    }

    func clearSelectionIndicator() {
        if let si = selectionIndicator {
            si.removeFromParent()
            selectionIndicator = nil
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
        case .radius: radius = v; break
        case .scale: scale = v; break
        }
    }
}

