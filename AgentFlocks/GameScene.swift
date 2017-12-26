//
//  GameScene.swift
//  barf
//
//  Created by Rob Bishop on 12/17/17.
//  Copyright © 2017 Rob Bishop. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKViewDelegate {
    static var selfScene: GameScene?
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
//    var agentControls: AgentControls!
//    var motivatorControls: MotivatorControls!

    private var lastUpdateTime : TimeInterval = 0
    
    private var draggedNodeIndex: Int? = nil
    private var draggedNodeMouseOffset = CGPoint.zero
    
    var selectionIndicator: SKShapeNode!
    var mouseWasDragged = false
    var showingSelection = false
    
    var corral = [SKShapeNode]()
    
    override func didMove(to view: SKView) {
        GameScene.selfScene = self
//        agentControls = AgentControls(view: view)
//        motivatorControls = MotivatorControls(view: view)
    }
    
    // MARK: - Mouse handling
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let touchedNodes = self.nodes(at: location)
        
        for (index, entity_) in self.entities.enumerated() {
            let entity = entity_ as! AFEntity
            if touchedNodes.contains(entity.agent.spriteContainer) {
                draggedNodeIndex = index
                
                let e = event.location(in: self)
                draggedNodeMouseOffset.x = entity.agent.spriteContainer.position.x - e.x
                draggedNodeMouseOffset.y = entity.agent.spriteContainer.position.y - e.y
                break
            }
        }

        mouseWasDragged = false
    }

    override func mouseUp(with event: NSEvent) {
        if let draggedIndex = draggedNodeIndex {
            if let entity = self.entities[draggedIndex] as? AFEntity {
                let c = entity.agent
                let p = event.location(in: self)
                c.position = vector_float2(Float(p.x), Float(p.y))
                c.position.x += Float(draggedNodeMouseOffset.x)
                c.position.y += Float(draggedNodeMouseOffset.y)
            
                if !mouseWasDragged {
                    if showingSelection {
                        entity.agent.spriteContainer.addChild(selectionIndicator)
                        selectionIndicator.zPosition = 2
                    } else {
                        selectionIndicator.removeFromParent()
                    }
                    
                    showingSelection = !showingSelection
                }
            }

            mouseWasDragged = false
            draggedNodeIndex = nil
            draggedNodeMouseOffset = CGPoint.zero
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if let draggedIndex = draggedNodeIndex {
            if let entity = self.entities[draggedIndex] as? AFEntity {
                mouseWasDragged = true
                
                let c = entity.agent.spriteContainer
                c.position = event.location(in: self)
                c.position.x += draggedNodeMouseOffset.x
                c.position.y += draggedNodeMouseOffset.y
            }
        }
    }
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        let w = 1400/*frame.size.width*/, h = 700/*frame.size.height*/
        let x = -w / 2/*frame.origin.x*/, y = -h / 2/*frame.origin.y*/
        
        selectionIndicator = SKShapeNode(circleOfRadius: 15)
        selectionIndicator.fillColor = .red
        
        var specs: [(CGPoint, CGSize, NSColor)] = [
            (CGPoint(x: x, y: -y), CGSize(width: w, height: 5), .red),
            (CGPoint(x: -x, y: y), CGSize(width: 5, height: h), .yellow),
            (CGPoint(x: x, y: y), CGSize(width: w, height: 5), .blue),
            (CGPoint(x: x - 1, y: y), CGSize(width: 5, height: h), .green)
        ]
        
        func drawShape(_ ss: Int) {
            let shapeNode = SKShapeNode(rect: CGRect(origin: specs[ss].0, size: specs[ss].1))
            shapeNode.fillColor = specs[ss].2
            shapeNode.strokeColor = .black
            self.addChild(shapeNode)
            corral.append(shapeNode)
        }
        
        for i in 0..<4 { drawShape(i) }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for (index, entity) in self.entities.enumerated() {
            if draggedNodeIndex != index {
                entity.update(deltaTime: dt)
            }
        }
        
        self.lastUpdateTime = currentTime
    }
}

