//
// Created by Rob Bishop on 1/3/18
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

class AFBehavior_Script: Codable {
    var enabled = true
    var goals: [AFGoal_Script]
    var weight: Float
}

class AFBehavior: GKBehavior {
    let agent: AFAgent2D
    var enabled = true
    var savedState: (weight: Float, goal: AFGoal)?
    var weight: Float

    init(prototype: AFBehavior_Script, agent: AFAgent2D) {
        self.agent = agent
        enabled = prototype.enabled
        weight = prototype.weight
        
        super.init()
        
        for goal_ in prototype.goals {
            let goal = AFGoal(prototype: goal_)
            setWeight(goal.weight, for: goal)
        }
    }
    
    init(agent: AFAgent2D) {
        self.agent = agent
        weight = 100
    }
    
    func addGoal(_ goal: AFGoal) {
        setWeight(goal.weight, for: goal)
    }
    
    func enableGoal(_ goal: AFGoal, on: Bool = true) {
        if on {
            enabled = true
            
            setWeight(savedState!.weight, for: goal)
            savedState = nil
        } else {
            enabled = false
            
            let weight = self.weight(for: goal)
            savedState = (weight: weight, goal: goal)
            
            remove(goal)
        }
    }

    func getChild(at index: Int) -> AFGoal {
        return self[index] as! AFGoal
    }
    
    func hasChildren() -> Bool {
        return goalCount > 0
    }
    
    func howManyChildren() -> Int {
        return goalCount
    }
    
    func toString() -> String {
        return String(format: "Behavior: %.0f", weight)
    }
}

