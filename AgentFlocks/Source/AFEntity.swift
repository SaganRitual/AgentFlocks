//
//  AFEntity.swift
//  AgentFlocks
//
//  Created by Rob Bishop on 12/18/17.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import GameplayKit

class AFEntity: GKEntity {
    let agent: AFAgent2D
    
    var name: String { return agent.sprite.name! }
    
    init(scene: GameScene, position: CGPoint) {
        agent = AFAgent2D(scene: scene, position: position)
        
        super.init()
        
        addComponent(agent)

        //        let node = GKSKNodeComponent(node: agent.spriteContainer)
        //        addComponent(node)
        //        agent.delegate = node
        
//        scene.agentControls.setAgent(agent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
