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

class AFAgentGoalsDelegate {
    unowned let data: AFData
    unowned let inputState: AFInputState
    
    init(data: AFData, inputState: AFInputState) {
        self.data = data
        self.inputState = inputState
    }
    
    func deleteItem(_ protoItem: Any) {
        let name = inputState.getPrimarySelectionName()!
        let agent = data.getAgent(name)
        let composite = agent.behavior as! AFCompositeBehavior
        
        if let hotBehavior = protoItem as? AFBehavior {
            composite.remove(hotBehavior)
        } else if let hotGoal = protoItem as? GKGoal {
            let hotBehavior = composite.findParent(ofGoal: hotGoal)!
            hotBehavior.remove(hotGoal)
        } else {
            fatalError()
        }
    }
    
    func itemClicked(_ item: Any) {
        if let motivator = item as? AFBehavior {
            inputState.parentOfNewMotivator = motivator
        } else if let motivator = item as? GKGoal {
            let name = inputState.getPrimarySelectionName()!
            let agent = data.getAgent(name)
            let composite = agent.behavior as! AFCompositeBehavior
            
            inputState.parentOfNewMotivator = composite.findParent(ofGoal: motivator)
        }
    }
    
    func play(_ yesno: Bool) {
        let name = inputState.getPrimarySelectionName()!
        let agent = data.entities[name].agent
        
        agent.isPlaying = yesno
    }
}
