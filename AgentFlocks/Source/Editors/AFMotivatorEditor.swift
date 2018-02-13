//
// Created by Rob Bishop on 2/11/18
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

class AFMotivatorEditor: AFEditor {
    var count: Int { get { return core.bigData.data[pathToHere].count } }
    
    var motivatorCategory: JSONSubscriptType { fatalError("Required in child classes") }
    var parentEditor: AFMotivatorEditor { fatalError("Required in child classes") }
    
    // Different motivators have different sets of scalar attributes. The UI
    // can call down to get these by name; if this motivator doesn't have that
    // attribute, we return nil.
    func getOptionalScalar(_ name: String) -> Double? {
        let n = name.lowercased()
        if core.bigData.data[pathToHere][n].exists() { return core.bigData.data[pathToHere][n].doubleValue }
        else { return nil }
    }
    
    static func getSpecificEditor(_ nodeName: JSONSubscriptType, core: AFCore) -> AFMotivatorEditor {
        let path = core.getPathTo(JSON(nodeName).stringValue)!
        
        if AFData.isBehavior(path)  { return AFBehaviorEditor(path, core: core) }
        else if AFData.isGoal(path) { return AFGoalEditor(path, core: core) }
        else { fatalError() }
    }
    
    // Get/set motivator weight from here, with big ugly functions rather than nice
    // variables, as a reminder of the underlying GK architecture. I am the container
    // setting a weight for one of my component motivators. The motivator weight is
    // not known by the motivator itself.
    func getWeight(forMotivator name: String) -> Float {
        let ix: JSONSubscriptType = "weight"
        return JSON(core.bigData.data[pathToHere][ix]).floatValue
    }
    
    func setOptionalScalar(_ nodeName: String, to value: Float) {
        fatalError("Required in child classes")
    }

    func setWeight(forMotivator name: String, to: Float) { fatalError("Required in child classes") }
}

extension AFMotivatorEditor {
    enum Attributes: String {
        case agent = "agent", agents = "agents", angle = "angle", distance = "distance", forward = "forward", name = "name",
        obstacles = "obstacles", path = "path", speed = "speed", objectAgents = "objectAgents", time = "time", type = "type"
    }
    
    var isEnabled: Bool {
        get {
            let ix: JSONSubscriptType = "isEnabled"
            return JSON(core.bigData.data[pathToHere][ix]).boolValue
        }
        set {
            let ix: JSONSubscriptType = "isEnabled"
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: ix)
        }
    }
    
    // My own weight, not that of my children. Can't be set from here. Must be done from
    // my parent using setWeight().
    var weight: Float {
        get {
            let ix: JSONSubscriptType = "weight"
            return JSON(core.bigData.data[pathToHere][ix]).floatValue
        }
    }
}
