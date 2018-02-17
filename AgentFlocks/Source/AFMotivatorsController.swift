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
            // If it has a new item type, it's a goal. What an ugly kludge.
            // Especially with a totally different field saying whether we're
            // creating a new item or editing an existing one.
            if attributes.isNewItem {
                let index = core.ui.agentEditorController.goalsController.outlineView!.selectedRow
                let behaviorEditor = compositeEditor.getBehaviorEditor(index)
                
                // Hold the notifications until we go out of scope; we don't want anyone to
                // start processing the new data until we get the goal fully committed to the agent.
                let nodeWriterDeferrer = NodeWriterDeferrer()
                let goalEditor = behaviorEditor.createGoal(nodeWriterDeferrer: nodeWriterDeferrer)
                
                goalEditor.weight = Float(attributes.weight.value)
                goalEditor.composeGoal(attributes: attributes, targetAgents: targetAgents)
            } else {
                
            }
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
