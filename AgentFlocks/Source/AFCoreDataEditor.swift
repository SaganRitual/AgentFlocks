//
// Created by Rob Bishop on 1/25/18
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

protocol AFCoreDataEditor {
    func getChildCount() -> Int
}

protocol AFArrayOwner {
    
}

struct AFArrayEditor: AFCoreDataEditor {
    let generic: AFGenericEditor
    
    init(_ nodeName: String, appData: AFDataModel) {
        self.generic = AFGenericEditor(nodeName, appData: appData)
    }

    func getChildCount() -> Int {
        return 0
    }
}

protocol AFSchemaProtocol {
    
}

class AFGenericObject {
    var contents = [String : AFGenericObject]()
}

class AFSchema {
    var rootMap: [String : Any] = [ "Agents" : [String : AFAgentEditor](), "Paths" : [String : AFPathEditor]() ]
}

class AFAgentEditorAttributes {
    let isPaused: Bool
    let mass: Float
    let maxAcceleration: Float
    let maxSpeed: Float
    let radius: Float
    let scale: Float
    
    init(_ nodeName: String, appData: AFDataModel) {
        let data = appData.getAgent(nodeName)
        let attributes = data.attributes
        
        self.isPaused = attributes[.IsPaused]! != 0 // These are Floats, and we want a Bool here
        self.mass = attributes[.Mass]!
        self.maxAcceleration = attributes[.MaxAcceleration]!
        self.maxSpeed = attributes[.MaxSpeed]!
        self.radius = attributes[.Radius]!
        self.scale = attributes[.Scale]!
    }
}

class AFAgentEditor {
    var attributes: AFAgentEditorAttributes
    var composite: AFCompositeEditor
    
    init(_ nodeName: String, appData: AFDataModel) {
        attributes = AFAgentEditorAttributes(nodeName, appData: appData)
        composite = AFCompositeEditor(nodeName, appData: appData)
    }
    
    func getChildCount() -> Int {
        return composite.getChildCount()
    }
    
    func setAttribute(_ asInt: Int, to value: Float) {
        
    }
}

class AFCompositeEditor {
    let behaviors: [(AFBehaviorEditor, Float)]

    init(_ nodeName: String, appData: AFDataModel) {
        // Note: this is the name of the agent; the
        // composite itself doesn't have a name. Maybe. I can't remember.
        behaviors = appData.getBehaviors(for: nodeName)
    }
    
    func getChildCount() -> Int {
        return behaviors.count
    }
}

struct AFBehaviorEditor {
    var goals = [String : (AFGoalEditor, Float)]()
    
    init(_ nodeName: String, appData: AFDataModel) {
    }
}

struct AFGoalEditor {
    
    init(_ nodeName: String, appData: AFDataModel) {
    }
    
    func getChildCount() -> Int {
        return 0
    }
    
}

struct AFGenericEditor: AFCoreDataEditor {
    unowned let appData: AFDataModel
    let nodeName: String
    
    init(_ nodeName: String, appData: AFDataModel) {
        self.appData = appData
        self.nodeName = nodeName
    }
    
    func getArray(_ name: String) -> [(AFBehaviorData, Float)] {
        return appData.getArray(name, from: self.nodeName)
    }
    
    func getChildCount() -> Int { return 0 }
}

struct AFCompositeBehaviorEditor: AFCoreDataEditor {
    var behaviors = [AFBehaviorEditor]()
    let generic: AFGenericEditor
    
    init(_ nodeName: String, appData: AFDataModel) {
        self.generic = AFGenericEditor(nodeName, appData: appData)

        var behaviors = [(AFBehaviorData, Float)]()
        _ = generic.getArray("Behaviors").map { behaviors.append(($0.0, $0.1)) }
    }

    func getChildCount() -> Int {
        return 0
    }
}

class AFPathEditor: AFGenericObject {
    
}
