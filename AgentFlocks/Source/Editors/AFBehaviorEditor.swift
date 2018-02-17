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
    
    var goalsCount: Int { return core.bigData.data[pathToHere]["goals"].count }
    override var motivatorCategory: JSONSubscriptType { return "goals" }

    override var parentEditor: AFMotivatorEditor {
        let pathToParent = AFData.getPathToParent(pathToHere)
        return AFCompositeEditor(pathToParent, core: core)
    }
    
    func createGoal(nodeWriterDeferrer: NodeWriterDeferrer? = nil) -> AFGoalEditor {
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
        
        // Caller wants to defer notifications, which are driven by NodeWriter's deinit.
        // So we store the nodeWriter here so we don't hit deinit until caller decides
        // it's a more fortuitous time.
        if let nwd = nodeWriterDeferrer { nwd.nodeWriter = nw }

        return AFGoalEditor(pathToNewGoal, core: core)
    }
    
    func getGoalEditor(_ index: Int) -> AFGoalEditor {
        let goals: JSONSubscriptType = "goals"
        let pathToGoal = pathToHere + [goals, self[index]]
        return AFGoalEditor(pathToGoal, core: core)
    }

    override func setOptionalScalar(_ nodeName: String, to value: Float) {
        switch nodeName {
        case "angle":    break
        case "distance": break
        case "speed":    break
        case "time":     break
        default:
            fatalError()
        }
    }

    // Our underlying json has no arrays in it. I made it all dictionaries, mostly because
    // it makes the json easier to read when debugging. But behaviors and goals, in
    // the GameplayKit architecture, are arrays. So here, a bit of a hack to get them
    // to be somewhat array-like (in particular, to remember the order in which elements
    // are added to them). There's some corresponding hackery in the motivators reader,
    // to assign these serial numbers to motivators as they're created. If I ever get to
    // the point where I feel like saving and loading files again, I'll have to read the
    // highest serial number in the incoming data and start the new serial numbers from there.
    subscript(_ ix: Int) -> String {
        let motivators = core.bigData.data[pathToHere][motivatorCategory].sorted(by: {
            $0.1["serialNumber"].intValue < $1.1["serialNumber"].intValue
        })
        
        return motivators[ix].0  // .0 is the name of the motivator node
    }
}

