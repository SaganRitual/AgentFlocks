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

class AFAgentEditor: AFEditor {
    override init(_ pathToHere: [JSONSubscriptType], core: AFCore) {
        super.init(pathToHere, core: core)

        // Hack in some defaults for now. Still haven't worked out
        // a good way to set defaults.
        if !core.bigData.data[pathToHere]["mass"].exists() {
            isPaused = false
            mass = 0.1
            maxAcceleration = 100
            maxSpeed = 100
            radius = 25
            scale = 1
        }
    }
    
    func createComposite() -> AFCompositeEditor {
        let newCompositeName: JSONSubscriptType = "behaviors"
        let pathToNewComposite = pathToHere + [newCompositeName]
        
        getNodeWriter(pathToHere).write(this: JSON([:]), to: newCompositeName)
        
        return AFCompositeEditor(pathToNewComposite, core: core)
    }
}

enum AFAgentAttribute: String { case isPaused, mass, maxAcceleration, maxSpeed, radius, scale }

extension AFAgentEditor {
    var isPaused: Bool {
        get {
            let i: JSONSubscriptType = AFAgentAttribute.isPaused.rawValue
            return JSON(core.bigData.data[pathToHere][i]).boolValue
        }
        set {
            let i: JSONSubscriptType = AFAgentAttribute.isPaused.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: i)
        }
    }
    
    var mass: Float {
        get {
            let m: JSONSubscriptType = AFAgentAttribute.mass.rawValue
            return JSON(core.bigData.data[pathToHere][m]).floatValue
        }
        set {
            let m: JSONSubscriptType = AFAgentAttribute.mass.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: m)
        }
    }
    
    var maxAcceleration: Float {
        get {
            let m: JSONSubscriptType = AFAgentAttribute.maxAcceleration.rawValue
            return JSON(core.bigData.data[pathToHere][m]).floatValue
        }
        set {
            let m: JSONSubscriptType = AFAgentAttribute.maxAcceleration.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: m)
        }
    }
    
    var maxSpeed: Float {
        get {
            let m: JSONSubscriptType = AFAgentAttribute.maxSpeed.rawValue
            return JSON(core.bigData.data[pathToHere][m]).floatValue
        }
        set {
            let m: JSONSubscriptType = AFAgentAttribute.maxSpeed.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: m)
        }
    }

    var radius: Float {
        get {
            let r: JSONSubscriptType = AFAgentAttribute.radius.rawValue
            return JSON(core.bigData.data[pathToHere][r]).floatValue
        }
        set {
            let r: JSONSubscriptType = AFAgentAttribute.radius.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: r)
        }
    }
    
    var scale: Float {
        get {
            let s: JSONSubscriptType = AFAgentAttribute.scale.rawValue
            return JSON(core.bigData.data[pathToHere][s]).floatValue
        }
        set {
            let s: JSONSubscriptType = AFAgentAttribute.scale.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: s)
        }
    }
}
