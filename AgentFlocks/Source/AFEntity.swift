//
//  AFEntity.swift
//  AgentFlocks
//
//  Created by Rob Bishop on 12/18/17.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import GameplayKit

class AFEntity_Script: Codable, Equatable {
    let agent: AFAgent2D_Script
    let name: String
    
    init(entity: AFEntity) {
        agent = AFAgent2D_Script(agent: entity.agent)
        name = entity.name
    }

    static func ==(lhs: AFEntity_Script, rhs: AFEntity_Script) -> Bool {
        return lhs.name == rhs.name
    }
}

class AFEntity: GKEntity, AFCloneable {
    let agent: AFAgent2D
    
    var name: String { return agent.sprite.name! }
    
    init(scene: GameScene, image: NSImage, position: CGPoint) {
        agent = AFAgent2D(scene: scene, image: image, position: position)
        agent.position.x = Float(position.x)
        agent.position.y = Float(position.y)
        
        super.init()
        
        AFSceneUI.AFNodeAdapter(agent.sprite).setOwningEntity(self)
        addComponent(agent)
    }
    
    init(scene: GameScene, copyFrom: AFEntity, position: CGPoint) {
        agent = AFAgent2D(scene: scene, copyFrom: copyFrom.agent, position: position)
        super.init()
        
        AFSceneUI.AFNodeAdapter(agent.sprite).setOwningEntity(self)
        addComponent(agent)
    }
    
    init(scene: GameScene, prototype: AFEntity_Script) {
        agent = AFAgent2D(scene: scene, prototype: prototype.agent)
        
        super.init()
        
        AFSceneUI.AFNodeAdapter(agent.sprite).setOwningEntity(self)
        addComponent(agent)
    }
    
    func clone(position: CGPoint) -> AFEntity {
        return AFEntity(scene: AFCore.sceneUI.gameScene, copyFrom: self, position: position)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AFEntity: AgentGoalsDataSource {

    func agentGoals(_ agentGoalsController: AgentGoalsController, numberOfChildrenOfItem item: Any?) -> Int {
        if let c = item as? AFCompositeBehavior {
            return c.behaviorCount
        } else if let b = item as? AFBehavior {
            return b.goalCount
        } else {
            let selected = AFCore.sceneUI.selectedNodes
            
            if selected.count > 0 {
                let entity = AFCore.data.entities[selected.first!.name!]!
                return (entity.agent.behavior as! GKCompositeBehavior).behaviorCount
            }
            
            return 0
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemExpandable item: Any) -> Bool {
        return item is AFBehavior
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, child index: Int, ofItem item: Any?) -> Any {
        if let motivator = item as? AFBehavior {
            // Note: composite is also a behavior, so this works for both
            return motivator[index]
        } else {
            // I don't understand why we're called here sometimes with item == nil.
            // The best I can think to do is to grab the behavior at [index] in
            // the selected agent's composite. Look into this, find out why we
            // get a nil.
//            let selected = AFCore.sceneUI.selectedNodes
//            if selected.count > 0 {
//                let entity = AFCore.data.entities[selected.first!]!
//                return (entity.agent.behavior as! AFCompositeBehavior)[index]
//            }
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
        if item is AFCompositeBehavior {
            fatalError()    // We don't have composites in the outline yet
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

