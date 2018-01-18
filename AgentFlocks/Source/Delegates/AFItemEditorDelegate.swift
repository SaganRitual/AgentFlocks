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
        var group = sceneUI.selectedNames
        let names = Array(group)
        
        let angle = Float(state.angle?.value ?? 0)
        let distance = Float(state.distance?.value ?? 0)
        let speed = Float(state.speed?.value ?? 0)
        let time = TimeInterval(state.time?.value ?? 0)
        let weight = Float(state.weight.value)

        switch type {
        case .toAlignWith:
            let primarySelection = sceneUI.primarySelection!
            let primarySelected = data.entities[primarySelection] as AFEntity
            
            goal = AFGoal(toAlignWith: names, maxDistance: distance, maxAngle: angle, weight: weight)

            for agentName in group {
                let afAgent = data.entities[agentName].agent
                
                // Hijacking the fwd checkbox; it's otherwise unused for this kind of goal
                let includePrimary = state.forward
                
                // User can select whether to give this alignment goal to the
                // primary selected, in addition to all the others in the selection.
                if includePrimary || afAgent.name != primarySelected.name {
                    afAgent.addGoal(goal!)
                }
            }
            
            goal = nil
            
        case .toAvoidObstacles:
            goal = AFGoal(toAvoidObstacles: Array(data.obstacles.keys), time: time, weight: weight)
            
        case .toAvoidAgents:
            let primarySelection = sceneUI.primarySelection
            let primarySelected = data.entities[primarySelection!] as AFEntity
            
            let agentNames = Array(group)
            
            if let ix = group.index(of: primarySelected.agent.name) {
                group.remove(at: ix)
            }
            
            goal = AFGoal(toAvoidAgents: agentNames, time: time, weight: weight)
            primarySelected.agent.addGoal(goal!)
            
            goal = nil
            
        case .toCohereWith:
            goal = AFGoal(toCohereWith: names, maxDistance: distance, maxAngle: angle, weight: weight)
            for agentName in group {
                data.entities[agentName].agent.addGoal(goal!)
            }
            
            goal = nil
            
        case .toFleeAgent:
            let selectedNames = sceneUI.selectedNames
            guard selectedNames.count == 2 else { return }
            
            var si = selectedNames.union(Set<String>())
            si.remove(sceneUI.primarySelection!)
            
            let nameOfAgentToFlee = si.first!
            goal = AFGoal(toFleeAgent: nameOfAgentToFlee, weight: weight)
            
        case .toFollow:
            let pathIndex = AFCore.sceneUI.pathForNextPathGoal
            let pathname = data.paths[pathIndex].name
            goal = AFGoal(toFollow: pathname, time: Float(time), forward: state.forward, weight: weight)
            
            goal!.pathname = pathname
            
        case .toInterceptAgent:
            let selectedNames = sceneUI.selectedNames
            guard selectedNames.count == 2 else { return }
            
            let namesAsArray = Array(selectedNames)
            let secondaryAgentName = namesAsArray[1]
            goal = AFGoal(toInterceptAgent: secondaryAgentName, time: time, weight: weight)
            
        case .toSeekAgent:
            var selectedNames = sceneUI.selectedNames
            guard selectedNames.count == 2 else { return }
            
            let p = selectedNames.remove(sceneUI.primarySelection!)
            selectedNames.remove(p!)
            
            let secondaryAgentName = selectedNames.first!
            goal = AFGoal(toSeekAgent: secondaryAgentName, weight: weight)
            
        case .toSeparateFrom:
            goal = AFGoal(toSeparateFrom: names, maxDistance: distance, maxAngle: angle, weight: weight)
            for agentName in group {
                data.entities[agentName].agent.addGoal(goal!)
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
        let selectedNames = sceneUI.selectedNames
        guard selectedNames.count > 0 else { return }
        
        let agentName = sceneUI.primarySelection!
        let entity = data.entities[agentName]
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
