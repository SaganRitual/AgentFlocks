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

    var top: SKShapeNode!
    var bottom: SKShapeNode!
    var left: SKShapeNode!
    var right: SKShapeNode!

    private var lastUpdateTime : TimeInterval = 0
    
    private var draggedNodeIndex: Int? = nil
    private var draggedNodeMouseOffset = CGPoint.zero
    
    override func didMove(to view: SKView) {
        GameScene.selfScene = self
//        agentControls = AgentControls(view: view)
//        motivatorControls = MotivatorControls(view: view)

        top = SKShapeNode(rect: CGRect(origin: CGPoint(x: -512, y: 384 - (50 + 40)), size: CGSize(width: 1024, height: 50)))
        top.fillColor = .blue
        top.strokeColor = .black
        self.addChild(top)
        
        bottom = SKShapeNode(rect: CGRect(origin: CGPoint(x: -512, y: -384 - -40), size: CGSize(width: 1024, height: 50)))
        bottom.fillColor = .green
        bottom.strokeColor = .black
        self.addChild(bottom)
        
        left = SKShapeNode(rect: CGRect(origin: CGPoint(x: -512 - 40, y: -384), size: CGSize(width: 50, height: 768)))
        left.fillColor = .blue
        left.strokeColor = .black
        self.addChild(left)
        
        right = SKShapeNode(rect: CGRect(origin: CGPoint(x: 512 - (50 - 40), y: -384), size: CGSize(width: 50, height: 768)))
        right.fillColor = .green
        right.strokeColor = .black
        self.addChild(right)
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
    }

    override func mouseUp(with event: NSEvent) {
        if let draggedIndex = draggedNodeIndex {
            if let entity = self.entities[draggedIndex] as? AFEntity {
                let c = entity.agent
                let p = event.location(in: self)
                c.position = vector_float2(Float(p.x), Float(p.y))
                c.position.x += Float(draggedNodeMouseOffset.x)
                c.position.y += Float(draggedNodeMouseOffset.y)
            }
        
            draggedNodeIndex = nil
            draggedNodeMouseOffset = CGPoint.zero
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if let draggedIndex = draggedNodeIndex {
            if let entity = self.entities[draggedIndex] as? AFEntity {
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
        topBarController.delegate = self
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

