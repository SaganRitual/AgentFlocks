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
    
    init(scene: GameScene, image: NSImage, position: CGPoint) {
        agent = AFAgent2D(scene: scene, image: image, position: position)
        
        super.init()
        
        addComponent(agent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AFEntity: AgentGoalsDataSource {
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, numberOfChildrenOfItem item: Any?) -> Int {
        if let collection = item as? AFMotivatorCollection {
            return collection.howManyChildren()
        } else {
            var reportThisIndex: Int?
            if let check = GameScene.selfScene!.uiInputState.touchedNodeIndex {
                reportThisIndex = check
            } else if let check = GameScene.selfScene!.uiInputState.selectedNodeIndex {
                reportThisIndex = check
            }
            
            if reportThisIndex != nil {
                if let entity = GameScene.selfScene!.entities[reportThisIndex!] as? AFEntity {
                    if let motivator = entity.agent.motivator as? AFBehavior {
                        return motivator.howManyChildren()
                    } else if let motivator = entity.agent.motivator as? AFCompositeBehavior {
                        return motivator.howManyChildren()
                    }
                }
            }
        }
        
        return 0
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemExpandable item: Any) -> Bool {
        return item is AFMotivatorCollection
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, child index: Int, ofItem item: Any?) -> Any {
        if let collection = item as? AFMotivatorCollection {
            // Child goal
            return collection.getChild(at: index)
        } else {
            var agentIndex: Int?
            if let check = GameScene.selfScene!.uiInputState.touchedNodeIndex {
                agentIndex = check
            } else if let check = GameScene.selfScene!.uiInputState.selectedNodeIndex {
                agentIndex = check
            }
            
            if agentIndex != nil {
                let entity = GameScene.selfScene!.entities[agentIndex!] as! AFEntity
                return entity.agent.motivator!.getChild(at: index)
            }
        }
        
        fatalError()
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, labelOfItem item: Any) -> String {
        if let collection = item as? AFCompositeBehavior {
            return collection.toString()
        } else if let behavior = item as? AFBehavior {
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

