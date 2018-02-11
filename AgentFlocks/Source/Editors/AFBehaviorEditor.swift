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

class AFBehaviorEditor: AFEditor {
    func createGoal() -> AFGoalEditor {
        let goals: JSONSubscriptType = "goals"
        let newGoalName: JSONSubscriptType = NSUUID().uuidString
        let pathToGoals = pathToHere + [goals]
        let pathToNewGoal = pathToGoals + [newGoalName]
        
        getNodeWriter(pathToGoals).write(this: JSON([:]), to: newGoalName)

        return AFGoalEditor(pathToNewGoal, core: core)
    }

    // Why did I put this here? "Some of the UI views"? Then it should be done
    // in the UI, I should think. Revisit this and the one in the composite editor,
    // see if there's any good reason for the editors to be involved in this stuff.
    
    // Some of the UI views need us to preserve the order -- or at least appear
    // to preserve the order -- of behaviors & goals. Our data is all tree-oriented,
    // so we have to do some juggling to keep the UI's desired order.
    subscript(_ ix: Int) -> String {
        let goals = core.bigData.data[pathToHere].sorted(by: {
            $0.1["serialNumber"].intValue < $1.1["serialNumber"].intValue
        })
        
        return goals[ix].0  // .0 is the name of the goal node
    }

    // Set goal weight from here, with a big ugly function rather than a nice
    // variable, as a reminder of the underlying GK architecture. I am the behavior
    // setting a weight for one of my component goals. The goal weight is an external
    // attribute, known by the behavior but not by the goal. See also the setWeight()
    // for behavior in AFCompositeEditor.
    func setWeight(forGoal name: String, to: Float) {
        getNodeWriter(pathToHere + [name]).write(this: JSON(to), to: "weight")
    }
}

