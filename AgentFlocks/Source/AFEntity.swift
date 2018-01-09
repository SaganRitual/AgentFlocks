//
//  AFEntity.swift
//  AgentFlocks
//
//  Created by Rob Bishop on 12/18/17.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import GameplayKit

class AFEntities: Codable {
    let entities = [AFEntity_Script]()
}

class AFPaths: Codable {
    let paths = [AFPath_Script]()
}

class AFEntity_Script: Codable {
    let agent: AFAgent2D_Script
    let name: String
    
    init(entity: AFEntity) {
        agent = AFAgent2D_Script(agent: entity.agent)
        name = entity.name
    }
}

class AFEntity: GKEntity {
    let agent: AFAgent2D
    
    var name: String { return agent.sprite.name! }
    
    init(scene: GameScene, image: NSImage, position: CGPoint) {
        agent = AFAgent2D(scene: scene, image: image, position: position)
        agent.position.x = Float(position.x)
        agent.position.y = Float(position.y)
        
        super.init()
        
        addComponent(agent)
    }
    
    init(prototype: AFEntity_Script) {
        agent = AFAgent2D(prototype: prototype.agent)
        
        super.init()
        
        addComponent(agent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AFEntity {
    static func makeEntities(from entities_: [AFEntity_Script]) -> [AFEntity] {
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
        if let c = item as? AFCompositeBehavior {
            return c.behaviorCount
        } else if let b = item as? AFBehavior {
            return b.goalCount
        } else {
            let selected = GameScene.me!.getSelectedIndexes()
            
            if selected.count > 0 {
                let entity = GameScene.me!.entities[selected.first!]
                return (entity.agent.behavior as! GKCompositeBehavior).behaviorCount
            }
            
            return 0
        }
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
        } else if let gkGoal = item as? GKGoal {
            let parent = agentGoalsController.outlineView.parent(forItem: item) as! AFBehavior
            
            return parent.goalsMap[gkGoal]!.toString()
        } else {
            return "<Rob broke something>"
        }
    }
	
	func agentGoals(_ agentGoalsController: AgentGoalsController, weightOfItem item: Any) -> Double {
		if let behavior = item as? AFBehavior {
			return Double(behavior.weight)
		} else if let gkGoal = item as? GKGoal {
			let parent = agentGoalsController.outlineView.parent(forItem: item) as! AFBehavior
			
			return Double(parent.goalsMap[gkGoal]!.weight)
		} else {
			return 0.0
		}
	}
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemEnabled item: Any) -> Bool {
        if let c = item as? AFCompositeBehavior {
            return c.enabled
        } else if let b = item as? AFBehavior {
            return b.enabled
        } else if let gkGoal = item as? GKGoal {
            let parent = agentGoalsController.outlineView.parent(forItem: item) as! AFBehavior

            return parent.goalsMap[gkGoal]!.enabled
        } else {
            return false
        }
    }
}

