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

class AFCompositeEditor: AFEditor {
    var count: Int { get { return core.bigData.data[pathToHere].count } }

    func createBehavior() -> AFBehaviorEditor {
        let newBehaviorName: JSONSubscriptType = NSUUID().uuidString
        let pathToNewBehavior = pathToHere + [newBehaviorName]
        
        // Hold onto the nodeWriter until we're totally finished, so we
        // don't generate a second, useless notification about the same update.
        let nodeWriter = getNodeWriter(pathToHere)
        nodeWriter.write(this: JSON([:]), to: newBehaviorName)

        // This does nothing of any programmatic use. I set the goals aside
        // in their own object only to make the JSON more readable.
        let goals: JSONSubscriptType = "goals"
        nodeWriter.write(this: JSON([:]), to: newBehaviorName, under: goals)
        
        return AFBehaviorEditor(pathToNewBehavior, core: core)
    }

    // Set behavior weight from here, with a big ugly function rather than a nice
    // variable, as a reminder of the underlying GK architecture. I am the composite
    // setting a weight for one of my component behaviors. The behavior weight is an
    // external attribute, known by the composite but not by the child behavior. See
    // also the setWeight() for goals in AFBehaviorEditor.
    func setWeight(forBehavior name: String, to: Float) {
        getNodeWriter(pathToHere + [name]).write(this: JSON(to), to: "weight")
    }

    subscript(_ ix: Int) -> String {
        let behaviors = core.bigData.data[pathToHere].sorted(by: {
            $0.1["serialNumber"].intValue < $1.1["serialNumber"].intValue
        })
        
        return behaviors[ix].0  // .0 is the name of the behavior node
    }

    
/*
    func getBehaviorEditor(_ name: String, pathToComposite: [JSONSubscriptType], core: AFCore) -> AFBehaviorEditor {
        return AFBehaviorEditor(name, pathToComposite: pathToComposite, core: core)
    }*/
}

