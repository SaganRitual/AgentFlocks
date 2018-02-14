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
    unowned let core: AFCore
    unowned let afSceneController: AFSceneController
    
    init(_ injector: AFCore.AFDependencyInjector) {
        self.core = injector.core!
        self.afSceneController = injector.afSceneController!
        injector.itemEditorDelegate = self
    }
    
    private func addMotivator(to agent: String, state: ItemEditorSlidersState) {
        let weight = Float(state.weight.value)

//        if state.newItemType == nil { coreData.newBehavior(for: agent, weight: weight); return }

        let type = state.newItemType!
        var goal: AFGoal?
        let selectedNames = Array(afSceneController.selectedNodes)
        var primaryNode = afSceneController.primarySelection!
        
        let angle = Float(state.angle?.value ?? 0)
        let distance = Float(state.distance?.value ?? 0)
        let speed = Float(state.speed?.value ?? 0)
        let time = TimeInterval(state.time?.value ?? 0)

        switch type {
        case .toAlignWith:    fallthrough
        case .toCohereWith:   fallthrough
        case .toSeparateFrom: break
//            coreData.newGoal(type, for: [agent], parentBehavior: nil, weight: weight, targets: selectedNames,
//                            angle: angle, distance: distance, speed: speed, time: time, forward: true)
            
        case .toAvoidObstacles:break
//            coreData.newGoal(type, for: nodes, targets: Array(coreData.obstacles.keys), parentBehavior: nil, weight: weight)
//            goal = AFGoal(toAvoidObstacles: Array(data.obstacles.keys), time: time, weight: weight)
            
        case .toAvoidAgents:
            // Make sure we're not trying to avoid ourselves too
            let sansSelf = selectedNames.filter { $0 != afSceneController.primarySelection! }
            
//            coreData.newGoal(type, for: coreData.afSceneController.primarySelection!.name!, parentBehavior: nil, weight: weight,
//                            targets: sansSelf, angle: angle, distance: distance, speed: speed,
//                            time: time, forward: nil)

        case .toFleeAgent:      fallthrough
        case .toInterceptAgent: fallthrough
        case .toSeekAgent:
            // Ugly, come back to it. The UI is telling us a specific node he wants to
            // exclude from the selection. I think I was trying to prevent the subject
            // of the goal from being added to his own goal. But now I'm tired and it's
            // harder to think about it.
            let sansTarget = selectedNames.filter { $0 != afSceneController.primarySelection! }
//            coreData.newGoal(type, for: sansTarget, weight, weight, targets: [selectedNames.first!],
//                            angle: angle, distance: distance, speed: speed,time: time, forward: true)
            
        case .toFollow:  fallthrough
        case .toStayOn:/*
            coreData.newGoal(type, for: primaryNode.name!, targets: [pathName], parentBehavior: nil,
                            time: Float(time), angle: angle, distance: distance, speed: speed,
                            time: time, weight: weight, forward: state.forward)
            
            let pathIndex = AFCore.afSceneController.pathForNextPathGoal
            let pathname = coreData.paths[pathIndex].name
            goal = AFGoal(toStayOn: pathname, time: Float(time), weight: weight)
            
            goal!.pathname = pathname*/
            break
            
        case .toReachTargetSpeed:  fallthrough
        case .toWander: break
//            coreData.newGoal(type, for: primaryNode.name!, time: time, weight: weight,
//                            angle: angle, distance: distance, speed: speed, forward: true)
        }
    }
    
    func inject(_ injector: AFCore.AFDependencyInjector) {
        
    }

    func itemEditorActivated(goalType: AFGoalType?) {
        guard let goalType = goalType else { return }
        
        switch goalType {
        case .toAlignWith:        fallthrough
        case .toAvoidAgents:      fallthrough
        case .toCohereWith:       fallthrough
        case .toSeparateFrom:     afSceneController.setGoalSetupInputMode(.MultiSelectAgents)

        case .toAvoidObstacles:   afSceneController.setGoalSetupInputMode(.MultiSelectObstacles)
            
        case .toFleeAgent:        fallthrough
        case .toInterceptAgent:   fallthrough
        case .toSeekAgent:        afSceneController.setGoalSetupInputMode(.SingleSelectAgent)
            
        case .toFollow:           fallthrough
        case .toStayOn:           afSceneController.setGoalSetupInputMode(.SingleSelectPath)

        case .toReachTargetSpeed: fallthrough
        case .toWander:           afSceneController.setGoalSetupInputMode(.NoSelect)
        }
    }
    
    func itemEditorDeactivated() {
        
    }
    
    private func refreshBehavior(agent: AFAgent, behavior: AFBehavior, weight: Double) {
        print("i don't know")
//        (agent.behavior! as! AFCompositeBehavior).setWeight(behavior.weight, for: behavior)
    }
    
    private func refreshGoal(gkGoal: GKGoal, state: ItemEditorSlidersState) {
//        let afGoal = afSceneController.parentOfNewMotivator!.goalsMap[gkGoal]!
        
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
//        if replacementGoalRequired {
//            retransmitGoal(afGoal: afGoal, state: state)
//        } else {
//            afSceneController.parentOfNewMotivator!.setWeight(Float(state.weight.value), for: afGoal)
//        }
    }
    
    func refreshMotivators(state: ItemEditorSlidersState) {
//        let selectedNodes = afSceneController.selectedNodes
//        guard selectedNodes.count > 0 else { return }
//        
//        let name = afSceneController.primarySelection!
//        let agent = AFNodeAdapter(gameScene: afSceneController.gameScene, name: name).getAgent()!
//        
//        if let behavior = state.editedItem as? AFBehavior {
//            refreshBehavior(agent: agent, behavior: behavior, weight: state.weight.value)
//        } else if let gkGoal = state.editedItem as? GKGoal {
//            refreshGoal(gkGoal: gkGoal, state: state)
//        } else {
////            addMotivator(entity: entity, state: state)
//        }
    }
    
    func retransmitGoal(afGoal: AFGoal, state: ItemEditorSlidersState) {
//        let newGoal = AFGoal.makeGoal(copyFrom: afGoal, weight: afGoal.weight)
        
        // Everyone has a weight
        let weight = Float(state.weight.value)
        
//        if let angleState = state.angle { newGoal.angle = Float(angleState.value) }
//        if let distanceState = state.distance { newGoal.distance = Float(distanceState.value) }
//        if let speedState = state.speed { newGoal.speed = Float(speedState.value) }
//        if let timeState = state.time { newGoal.time = Float(timeState.value) }
//        
//        newGoal.weight = weight
//        
////        afSceneController.parentOfNewMotivator!.remove(afGoal)
//        afSceneController.parentOfNewMotivator!.setWeightage(weight, for: newGoal)
    }
    
    func sliderChanged(state: ItemEditorSlidersState) {
        let (_, selectedAgent) = afSceneController.selectionController.getSelection()

        if selectedAgent != nil {
            let coreEditor = AFMotivatorEditor.getSpecificEditor(state.editedItem as! String, core: core)

            if state.angle!.didChange    { coreEditor.setOptionalScalar("angle", to: Float(state.angle!.value))  }
            if state.distance!.didChange { coreEditor.setOptionalScalar("distance", to: Float(state.distance!.value))  }
            if state.speed!.didChange    { coreEditor.setOptionalScalar("speed", to: Float(state.speed!.value))  }
            if state.time!.didChange     { coreEditor.setOptionalScalar("time", to: Float(state.time!.value))  }

            if state.weight.didChange {
                coreEditor.parentEditor.setWeight(forMotivator: coreEditor.name, to: Float(state.weight.value))
            }

        } else { fatalError() }
    }
}
