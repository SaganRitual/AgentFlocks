//
// Created by Rob Bishop on 1/15/18
//
// Copyright © 2018 Rob Bishop
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//

import GameplayKit

class AFItemEditorDelegate {
    unowned let data: AFData
    unowned let sceneUI: AFSceneUI
    
    init(data: AFData, sceneUI: AFSceneUI) {
        self.data = data
        self.sceneUI = sceneUI
    }
    
    private func addMotivator(entity: AFEntity, state: ItemEditorSlidersState) {
        if state.newItemType == nil {
            let newBehavior = AFBehavior(agent: entity.agent)
            newBehavior.weight = Float(state.weight.value)
            
            let hotComposite = entity.agent.behavior as! AFCompositeBehavior
            hotComposite.setWeight(newBehavior.weight, for: newBehavior)
            return
        }

        let type = state.newItemType!
        var goal: AFGoal?
        let group = sceneUI.selectedNodes
        let nodes = Array(group)
        
        let angle = Float(state.angle?.value ?? 0)
        let distance = Float(state.distance?.value ?? 0)
        let speed = Float(state.speed?.value ?? 0)
        let time = TimeInterval(state.time?.value ?? 0)
        let weight = Float(state.weight.value)

        switch type {
        case .toAlignWith:
            let primarySelection = sceneUI.primarySelection!
            let primarySelected = data.entities[primarySelection.name!]! as AFEntity
            
            goal = AFGoal(toAlignWith: nodes, maxDistance: distance, maxAngle: angle, weight: weight)

            for agentNode in group {
                let afAgent = data.entities[agentNode.name!]!.agent
                
                // Hijacking the fwd checkbox; it's otherwise unused for this kind of goal
                let includePrimary = state.forward
                
                // User can select whether to give this alignment goal to the
                // primary selected, in addition to all the others in the selection.
                if includePrimary || agentNode.name! != primarySelected.name {
                    afAgent.addGoal(goal!)
                }
            }
            
            goal = nil
            
        case .toAvoidObstacles:
            goal = AFGoal(toAvoidObstacles: Array(data.obstacles.keys), time: time, weight: weight)
            
        case .toAvoidAgents:
            let primarySelection = sceneUI.primarySelection!
            
            // Make sure we're not trying to avoid ourselves too
            let agentNodes = Array(group).filter {
                if let nodeName = $0.name, let primarySelectionName = primarySelection.name {
                    return nodeName != primarySelectionName
                }
                return true
            }
            
            goal = AFGoal(toAvoidAgents: agentNodes, time: time, weight: weight)
            
            if let agent = AFSceneUI.AFNodeAdapter(primarySelection).getOwningAgent() {
                agent.addGoal(goal!)
            }
            
            goal = nil
            
        case .toCohereWith:
            goal = AFGoal(toCohereWith: nodes, maxDistance: distance, maxAngle: angle, weight: weight)

            for node in nodes {
                if let agent = AFSceneUI.AFNodeAdapter(node).getOwningAgent() {
                    agent.addGoal(goal!)
                }
            }
            
            goal = nil
            
        case .toFleeAgent:
            let selectedNodes = sceneUI.selectedNodes
            guard selectedNodes.count == 2 else { return }
            
            var si = selectedNodes.union(Set<SKNode>())
            si.remove(sceneUI.primarySelection!)
            
            let agentToFlee = si.first!
            goal = AFGoal(toFleeAgent: agentToFlee, weight: weight)
            
        case .toFollow:
            let pathIndex = AFCore.sceneUI.pathForNextPathGoal
            let pathname = data.paths[pathIndex].name
            goal = AFGoal(toFollow: pathname, time: Float(time), forward: state.forward, weight: weight)
            
            goal!.pathname = pathname
            
        case .toInterceptAgent:
            let selectedNodes = sceneUI.selectedNodes
            guard selectedNodes.count == 2 else { return }
            
            let targetAgentNode = nodes.filter { $0 != sceneUI.primarySelection }.first!
            goal = AFGoal(toInterceptAgent: targetAgentNode, time: time, weight: weight)
            
        case .toSeekAgent:
            let selectedNodes = sceneUI.selectedNodes
            guard selectedNodes.count == 2 else { return }
            
            let targetAgentNode = nodes.filter { $0 != sceneUI.primarySelection }.first!
            goal = AFGoal(toSeekAgent: targetAgentNode, weight: weight)
            
        case .toSeparateFrom:
            goal = AFGoal(toSeparateFrom: nodes, maxDistance: distance, maxAngle: angle, weight: weight)

            if let agent = AFSceneUI.AFNodeAdapter(sceneUI.primarySelection).getOwningAgent() {
                agent.addGoal(goal!)
            }
            
            goal = nil
            
        case .toStayOn:
            let pathIndex = AFCore.sceneUI.pathForNextPathGoal
            let pathname = data.paths[pathIndex].name
            goal = AFGoal(toStayOn: pathname, time: Float(time), weight: weight)
            
            goal!.pathname = pathname
            
        case .toReachTargetSpeed:
            goal = AFGoal(toReachTargetSpeed: speed, weight: weight)
            
        case .toWander:
            goal = AFGoal(toWander: speed, weight: weight)
        }
        
        if goal != nil {
            sceneUI.getParentForNewMotivator().addGoal(goal!)
        }
    }
    
    func itemEditorActivated(goalType: AFGoalType?) {
        guard let goalType = goalType else { return }
        
        switch goalType {
        case .toAlignWith:        fallthrough
        case .toAvoidAgents:      fallthrough
        case .toCohereWith:       fallthrough
        case .toSeparateFrom:     sceneUI.setGoalSetupInputMode(.MultiSelectAgents)

        case .toAvoidObstacles:   sceneUI.setGoalSetupInputMode(.MultiSelectObstacles)
            
        case .toFleeAgent:        fallthrough
        case .toInterceptAgent:   fallthrough
        case .toSeekAgent:        sceneUI.setGoalSetupInputMode(.SingleSelectAgent)
            
        case .toFollow:           fallthrough
        case .toStayOn:           sceneUI.setGoalSetupInputMode(.SingleSelectPath)

        case .toReachTargetSpeed: fallthrough
        case .toWander:           sceneUI.setGoalSetupInputMode(.NoSelect)
        }
    }
    
    func itemEditorDeactivated() {
        
    }
    
    private func refreshBehavior(agent: AFAgent2D, behavior: AFBehavior, weight: Double) {
        behavior.weight = Float(weight)
        (agent.behavior! as! AFCompositeBehavior).setWeight(behavior.weight, for: behavior)
    }
    
    private func refreshGoal(gkGoal: GKGoal, state: ItemEditorSlidersState) {
        let afGoal = sceneUI.parentOfNewMotivator!.goalsMap[gkGoal]!
        
        // Edit existing goal -- note AFBehavior doesn't give us a way
        // to update the goal. If we want to assign any new values to
        // this goal, we just have to throw it away and make a new one.
        let replacementGoalRequired = (
            state.angle?.didChange ?? false ||
            state.distance?.didChange ?? false ||
            state.speed?.didChange ?? false ||
            state.time?.didChange ?? false
        )
        
        // However, the weight of the goal is managed by the behavior.
        // So if all we're updating is the weight, we can just change that
        // directly in the behavior, without creating a new goal.
        if replacementGoalRequired {
            retransmitGoal(afGoal: afGoal, state: state)
        } else {
            sceneUI.parentOfNewMotivator!.setWeightage(Float(state.weight.value), for: afGoal)
        }
    }
    
    func refreshMotivators(state: ItemEditorSlidersState) {
        let selectedNodes = sceneUI.selectedNodes
        guard selectedNodes.count > 0 else { return }
        
        let node = sceneUI.primarySelection!
        let entity = data.entities[node.name!]!
        let agent = entity.agent
        
        if let behavior = state.editedItem as? AFBehavior {
            refreshBehavior(agent: agent, behavior: behavior, weight: state.weight.value)
        } else if let gkGoal = state.editedItem as? GKGoal {
            refreshGoal(gkGoal: gkGoal, state: state)
        } else {
            addMotivator(entity: entity, state: state)
        }
    }
    
    func retransmitGoal(afGoal: AFGoal, state: ItemEditorSlidersState) {
        let newGoal = AFGoal.makeGoal(copyFrom: afGoal, weight: afGoal.weight)
        
        // Everyone has a weight
        let weight = Float(state.weight.value)
        
        if let angleState = state.angle { newGoal.angle = Float(angleState.value) }
        if let distanceState = state.distance { newGoal.distance = Float(distanceState.value) }
        if let speedState = state.speed { newGoal.speed = Float(speedState.value) }
        if let timeState = state.time { newGoal.time = Float(timeState.value) }
        
        newGoal.weight = weight
        
        sceneUI.parentOfNewMotivator!.remove(afGoal)
        sceneUI.parentOfNewMotivator!.setWeightage(weight, for: newGoal)
    }
    
    func sliderChanged(state: ItemEditorSlidersState) {
        refreshMotivators(state: state)
    }
}
