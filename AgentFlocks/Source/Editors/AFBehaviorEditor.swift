//
// Created by Rob Bishop on 2/6/18
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

import Foundation

class AFBehaviorEditor: AFMotivatorEditor {
    func createGoal() -> AFGoalEditor {
        // Adding the "goals" dictionary does nothing of any programmatic use. I set the goals
        // aside in their own object only to make the JSON more readable when debugging. See
        // the setup in the composite editor's createBehavior() function.
        let goals: JSONSubscriptType = "goals"
        
        let newGoalName: JSONSubscriptType = NSUUID().uuidString
        let pathToGoals = pathToHere + [goals]
        let pathToNewGoal = pathToGoals + [newGoalName]
        
        let nw = getNodeWriter(pathToGoals)
        nw.write(this: JSON([:]), to: newGoalName)
        
        // Motivators are enabled by default
        let isEnabled: JSONSubscriptType = "isEnabled"
        nw.write(this: JSON(true), to: newGoalName, under: isEnabled)

        return AFGoalEditor(pathToNewGoal, core: core)
    }
}

