//
//  AFEntity.swift
//  AgentFlocks
//
//  Created by Rob Bishop on 12/18/17.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import GameplayKit

protocol AgentGoalsDelegate {
    func agentGoalsPlayClicked(_ agentGoalsController: AgentGoalsController)
    func agentGoals(_ agentGoalsController: AgentGoalsController, newBehaviorShowForRect rect: NSRect)
    func agentGoals(_ agentGoalsController: AgentGoalsController, newGoalShowForRect rect: NSRect, goalType type:AgentGoalsController.GoalType)
    func agentGoals(_ agentGoalsController: AgentGoalsController, itemDoubleClicked item: Any, inRect rect: NSRect)
    func agentGoals(_ agentGoalsController: AgentGoalsController, item: Any, setState state: NSControl.StateValue )
    // Drag & Drop
    func agentGoals(_ agentGoalsController: AgentGoalsController, dragIdentifierForItem item: Any) -> String?
    func agentGoals(_ agentGoalsController: AgentGoalsController, validateDrop info: NSDraggingInfo, toParentItem parentItem: Any?, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation
    func agentGoals(_ agentGoalsController: AgentGoalsController, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool
}

protocol AgentGoalsDataSource {
    func agentGoals(_ agentGoalsController: AgentGoalsController, numberOfChildrenOfItem item: Any?) -> Int
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemExpandable item: Any) -> Bool
    func agentGoals(_ agentGoalsController: AgentGoalsController, child index: Int, ofItem item: Any?) -> Any
    func agentGoals(_ agentGoalsController: AgentGoalsController, labelOfItem item: Any) -> String
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemEnabled item: Any) -> Bool
}

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

// MARK: - AgentGoalsDataSource

extension AFEntity: AgentGoalsDataSource {
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, numberOfChildrenOfItem item: Any?) -> Int {
        if let behaviorItem = item as? AppDelegate.AgentBehaviorType {
            // Child item: behavior
            return behaviorItem.goals.count
        }
        // Root item
        return (UglyGlobals.editedAgentIndex == nil) ? 0 : UglyGlobals.agents[UglyGlobals.editedAgentIndex!].behaviors.count
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemExpandable item: Any) -> Bool {
        if item is AppDelegate.AgentBehaviorType {
            return true
        }
        return false
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, child index: Int, ofItem item: Any?) -> Any {
        if let behaviorItem = item as? AppDelegate.AgentBehaviorType {
            // Child item: AppDelegate.AgentGoalType
            return behaviorItem.goals[index]
        }
        // Root item
        if let agentIndex = UglyGlobals.editedAgentIndex {
            // Child item: AppDelegate.AgentBehaviorType
            return UglyGlobals.agents[agentIndex].behaviors[index]
        }
        // Child item: AppDelegate.AgentBehaviorType
        return UglyGlobals.agents[0].behaviors[0]
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, labelOfItem item: Any) -> String {
        if let behaviorItem = item as? AppDelegate.AgentBehaviorType {
            return behaviorItem.name
        }
        else if let goalItem = item as? AppDelegate.AgentGoalType {
            return goalItem.name
        }
        return ""
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemEnabled item: Any) -> Bool {
        if let behaviorItem = item as? AppDelegate.AgentBehaviorType {
            return behaviorItem.enabled
        }
        else if let goalItem = item as? AppDelegate.AgentGoalType {
            return goalItem.enabled
        }
        return false
    }
    
}

// MARK: - AgentGoalsDelegate

extension AFEntity: AgentGoalsDelegate {
    
    func agentGoalsPlayClicked(_ agentGoalsController: AgentGoalsController) {
//        guard let agentIndex = UglyGlobals.editedAgentIndex else { return }
//
//        UglyGlobals.appDelegate.sceneController.addNode(image: UglyGlobals.agents[agentIndex].image)
//        UglyGlobals.appDelegate.removeAgentFrames()
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, itemDoubleClicked item: Any, inRect rect: NSRect) {
        guard let mainView = UglyGlobals.appDelegate.window.contentView else { return }
        if item is AppDelegate.AgentBehaviorType {
            
            let editorController = ItemEditorController(withAttributes: ["Weight"])
//            editorController.delegate = self
            fatalError("Fix this")
            editorController.editedItem = item
            
            // TODO: Set behavior values
            editorController.setValue(ofSlider: "Weight", to: 5.6)
            editorController.preview = true
            
            let itemRect = mainView.convert(rect, from: agentGoalsController.view)
            UglyGlobals.appDelegate.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
        }
        else if item is AppDelegate.AgentGoalType {
            // TODO: Get Goal's type (Wander, Align, Cohere or Avoid) from item
            // based on that information create ItemEditorController with type's specific attributes
            let editorController = ItemEditorController(withAttributes: ["Distance", "Angle", "Weight"])
//            editorController.delegate = self
            editorController.editedItem = item
            
            // TODO: Set goal values
            editorController.setValue(ofSlider: "Distance", to: 3.2)
            editorController.setValue(ofSlider: "Angle", to: 4.8)
            editorController.setValue(ofSlider: "Weight", to: 5.6)
            editorController.preview = true
            
            let itemRect = mainView.convert(rect, from: agentGoalsController.view)
            UglyGlobals.appDelegate.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, item: Any, setState state: NSControl.StateValue) {
        if let behaviorItem = item as? AppDelegate.AgentBehaviorType {
            let enabled = (state == .on) ? true : false
            NSLog("Behavior '\(behaviorItem.name)' " + (enabled ? "enabled" : "disabled"))
        }
        else if let goalItem = item as? AppDelegate.AgentGoalType {
            let enabled = (state == .on) ? true : false
            NSLog("Goal '\(goalItem.name)' " + (enabled ? "enabled" : "disabled"))
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, newBehaviorShowForRect rect: NSRect) {
        guard let mainView = UglyGlobals.appDelegate.window.contentView else { return }
        
        let editorController = ItemEditorController(withAttributes: ["Weight"])
//        editorController.delegate = self
        
        let itemRect = mainView.convert(rect, from: agentGoalsController.view)
        UglyGlobals.appDelegate.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, newGoalShowForRect rect: NSRect, goalType type: AgentGoalsController.GoalType) {
        guard let mainView = UglyGlobals.appDelegate.window.contentView else { return }
        
        var attributeList = ["Weight"]
        switch type {
        case .Wander:
            attributeList = ["Speed"] + attributeList
        case .Align:
            attributeList = ["Distance", "Angle"] + attributeList
        case .Cohere:
            attributeList = ["Cohere"] + attributeList
        case .Avoid:
            attributeList = ["Avoid"] + attributeList
        }
        
        let editorController = ItemEditorController(withAttributes: attributeList)
//        editorController.delegate = self
        
        let itemRect = mainView.convert(rect, from: agentGoalsController.view)
        UglyGlobals.appDelegate.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, dragIdentifierForItem item: Any) -> String? {
        if let behaviorItem = item as? AppDelegate.AgentBehaviorType {
            return behaviorItem.name
        }
        else if let goalItem = item as? AppDelegate.AgentGoalType {
            return goalItem.name
        }
        return nil
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, validateDrop info: NSDraggingInfo, toParentItem parentItem: Any?, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if index == NSOutlineViewDropOnItemIndex {
            // Don't allow to drop on item
            return NSDragOperation.init(rawValue: 0)
        }
        return NSDragOperation.move
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        return false
    }
    
}
