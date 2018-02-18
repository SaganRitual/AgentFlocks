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

class AFMotivatorsController {
    unowned let core: AFCore
    unowned let afSceneController: AFSceneController
    
    init(_ injector: AFCore.AFDependencyInjector) {
        self.core = injector.core!
        self.afSceneController = injector.afSceneController!
        injector.motivatorsController = self
    }
    
    private func buildGoalFromScratch(attributes: MotivatorAttributes) {
        // If it has a new item type, it's a goal. What an ugly kludge.
        // Especially with a totally different field saying whether we're
        // creating a new item or editing an existing one.
        let targetCategory = AFGoalEditor.getTargetCategory(for: attributes.newItemType!)
        switch targetCategory {
        case .allSelectedAgents:   fallthrough
        case .singleAgent:
            let tuple = afSceneController.selectionController.getSelection()
            let primarySelection = tuple.1!

            // Exclude myself from the target agents if the new goal isn't an "all agents" goal
            let targetAgents = (targetCategory == .allSelectedAgents) ? (tuple.0!) : tuple.0!.filter { $0 != primarySelection }
            
            // The "all agents" category is for the flocking goals, so everyone involved needs to
            // be assigned the same goal. The other categories require only that the primary
            // selection guy get the goal.
            let subjectAgents = (targetCategory == .allSelectedAgents) ? (tuple.0!) : [primarySelection]
            
            // This holds onto all the NodeWriters so no notifications will happen until we get
            // all the pieces in place.
            var toDeferNotifications = [NodeWriter]()
            for name in subjectAgents {
                // Index is for when I figure out a good way to assign new goals to subjects
                // that aren't the primary selection
                // let index = core.ui.agentEditorController.goalsController.outlineView!.selectedRow
                let subjectAgent = AFEditor(name, core: core)
                let behaviorEditor = subjectAgent.getCompositeEditor().getBehaviorEditor(0)
                
                let nodeWriterDeferrer = NodeWriterDeferrer()
                let goalEditor = behaviorEditor.createGoal(nodeWriterDeferrer: nodeWriterDeferrer)
                
                toDeferNotifications.append(nodeWriterDeferrer.nodeWriter!) // Defer notifications until we're finished
                
                goalEditor.weight = Float(attributes.weight.value)
                
                let targetAgentsSansMe = targetAgents.filter { $0 != name }
                goalEditor.composeGoal(attributes: attributes, targetAgents: targetAgentsSansMe)
            }
            
            print("pre notification", core.bigData.data)
            
        case .none:      break
        case .obstacles: fatalError()
        case .path:      fatalError()
        }   // Now the node writers go out of scope. I wonder if we'll survive the barrage of notifications.
    }
    
    func commit(_ attributes: MotivatorAttributes) {
        let agentName = afSceneController.selectionController.primarySelection!
        let agentEditor = afSceneController.getAgentEditor(agentName)
        let compositeEditor = agentEditor.getComposite()

        let (targetAgents, _) = afSceneController.selectionController.getSelection()

        if attributes.newItemType == nil {
            // If it doesn't have a new item type, it's a behavior. See above.
            if attributes.isNewItem {
                let behaviorEditor = compositeEditor.createBehavior()
                behaviorEditor.weight = Float(attributes.weight.value)
            } else {
                
            }
        } else {
            if attributes.isNewItem { buildGoalFromScratch(attributes: attributes) }
            else { /*updateGoal(attributes)*/ }
            
            print("post(?) notification", core.bigData.data)
        }
    }
    
    func inject(_ injector: AFCore.AFDependencyInjector) {
        
    }

    func itemEditorActivated(goalType: AFGoalEditor.AFGoalType?) {
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
    
    func sliderChanged(_ state: MotivatorAttributes) {
        let (_, selectedAgent) = afSceneController.selectionController.getSelection()

        if selectedAgent != nil {
            let coreEditor = AFMotivatorEditor.getSpecificEditor(state.editedItem as! String, core: core)

            if state.angle!.didChange    { coreEditor.setOptionalScalar("angle", to: Float(state.angle!.value))  }
            if state.distance!.didChange { coreEditor.setOptionalScalar("distance", to: Float(state.distance!.value))  }
            if state.speed!.didChange    { coreEditor.setOptionalScalar("speed", to: Float(state.speed!.value))  }
            if state.time!.didChange     { coreEditor.setOptionalScalar("time", to: Float(state.time!.value))  }

            if state.weight.didChange {
                coreEditor.weight = Float(state.weight.value)
            }

        } else { fatalError() }
    }
}
