//
//  AFEntity.swift
//  AgentFlocks
//
//  Created by Rob Bishop on 12/18/17.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import GameplayKit

class AFEntities: Codable {
    let entities: [AFEntity_]
}

class AFEntity_: Codable {
    let agent: AFAgent2D_
    let name: String
}

class AFEntity: GKEntity {
    let agent: AFAgent2D
    
    var name: String { return agent.sprite.name! }
    
    init(scene: GameScene, image: NSImage, position: CGPoint) {
        agent = AFAgent2D(scene: scene, image: image, position: position)
        
        super.init()
        
        addComponent(agent)
    }
    
    init(prototype: AFEntity_) {
        agent = AFAgent2D(prototype: prototype.agent, name: prototype.name)
        
        super.init()
        
        addComponent(agent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AFEntity {
    static func makeEntities(from entities_: [AFEntity_]) -> [AFEntity] {
        var result = [AFEntity]()
        
        for entity_ in entities_ {
            let entity = AFEntity(prototype: entity_)
            result.append(entity)
        }
        
        return result
    }
}

extension AFEntity: AgentGoalsDataSource {
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, numberOfChildrenOfItem item: Any?) -> Int {
        let selected = GameScene.me!.getSelectedIndexes()
        
        if selected.count > 0 {
            let entity = GameScene.me!.entities[selected.first!]
            
            if let b = entity.agent.behavior as? AFBehavior {
                return b.howManyChildren()
            } else if let c = entity.agent.behavior as? AFCompositeBehavior {
                return c.howManyChildren()
            }
        }
        
        return 0
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemExpandable item: Any) -> Bool {
        return item is AFBehavior
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, child index: Int, ofItem item: Any?) -> Any {
        if let motivator = item as? GKBehavior {
            // Note: composite is also a behavior, so we'll come here for either case
            return motivator[index]
        } else {
            let selected = GameScene.me!.getSelectedIndexes()
            if selected.count > 0 {
                let entity = GameScene.me!.entities[selected.first!]
                return (entity.agent.behavior as! GKCompositeBehavior)[index]
            }
        }
        
        fatalError()
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, labelOfItem item: Any) -> String {
        if let behavior = item as? AFBehavior {
            return behavior.toString()
        } else if let goal = item as? AFGoal {
            return goal.toString()
        } else {
            return "<no name>"
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemEnabled item: Any) -> Bool {
        if let c = item as? AFCompositeBehavior {
            return c.enabled
        } else if let b = item as? AFBehavior {
            return b.enabled
        } else if let g = item as? AFGoal {
            return g.enabled
        } else {
            return false
        }
    }
}

