//
//  GameScene.swift
//  barf
//
//  Created by Rob Bishop on 12/17/17.
//  Copyright © 2017 Rob Bishop. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
//    var agentControls: AgentControls!
//    var motivatorControls: MotivatorControls!

    var top: SKShapeNode!
    var bottom: SKShapeNode!
    var left: SKShapeNode!
    var right: SKShapeNode!

    private var lastUpdateTime : TimeInterval = 0
    
    var draggedNodeIndex: Int? = nil
    
    override func didMove(to view: SKView) {
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
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
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
