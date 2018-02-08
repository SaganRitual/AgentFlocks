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

class AFBehaviorEditor {
    unowned var core: AFCore
    var pathToHere: [JSONSubscriptType]
    
    // Create a new, empty behavior slot in the data tree.
    init(_ pathToHere: [JSONSubscriptType], core: AFCore) {
        self.core  = core
        self.pathToHere = pathToHere
    }
    
    func createGoal() -> AFGoalEditor {
        let goals: JSONSubscriptType = "goals"
        let newGoalName: JSONSubscriptType = NSUUID().uuidString
        let pathToGoals = pathToHere + [goals]
        let pathToNewGoal = pathToGoals + [newGoalName]
        
        getNodeWriter(pathToGoals).write(this: JSON([:]), to: newGoalName)

        return AFGoalEditor(pathToNewGoal, core: core)
    }

    func getNodeWriter(_ pathToParent: [JSONSubscriptType]) -> NodeWriter {
        return NodeWriter(pathToParent, core: core)
    }

    /*
    init(pathToComposite: [JSONSubscriptType], core: AFCore) {
        self.core = core
        
        let nextSlot: JSONSubscriptType = core.bigData.data[pathToComposite].count
        self.fullPath = pathToComposite + [nextSlot]

        core.bigData.getNodeWriter(for: fullPath).write { core.bigData.data[pathToComposite].arrayObject?.append(JSON([:])) }
        print("special", pathToComposite, self.fullPath, core.bigData.data)
    }
    
    init(_ behaviorName: String, pathToComposite: [JSONSubscriptType], core: AFCore) {
        self.core = core
        self.fullPath = pathToComposite + ["behavior"]
        self.name = behaviorName
        
//        for (key, _) in core.bigData.data[self.fullPath] {
//            let node: JSONSubscriptType = key
//            let goal = AFGoalEditor(core: core, loadFrom: self.fullPath + [node])
//            goals.append((goal, 42))
//        }
    }*/
    /*
    func createGoal() -> AFGoalEditor {
        return AFGoalEditor(pathToBehavior: fullPath, core: core)
    }
    *//*
    func createGoal() -> AFGoalEditor {
        let nextSlot: JSONSubscriptType = core.bigData.data[fullPath].count
        
        let name = NSUUID().uuidString
        let editor = AFGoalEditor(pathToBehavior: fullPath, core: core)
        editor.name = name
        
        let writePath: [JSONSubscriptType] = Array(fullPath) + [nextSlot] + ["name"]
        core.bigData.getNodeWriter(for: writePath).write {
            core.bigData.data[fullPath].arrayObject?.append(JSON([:]))
            core.bigData.data[writePath] = JSON(name)      // Fill in the name; other objects will fill it out further
        }

        print("After createGoal()", core.bigData.data)
        return editor
    }*/
/*
    func createGoal(_ name: String, pathToComposite: [JSONSubscriptType], core: AFCore) -> AFGoalEditor {
        return AFGoalEditor(name, pathToComposite: self.fullPath, core: core)
    }
    
//    func createGoal(type: AFGoalEditor.AFGoalType, weight: Float,
//                    objectAgents: [String]? = nil, angle: Float? = nil, distance: Float? = nil,
//                    speed: Float? = nil, time: TimeInterval? = nil, forward: Bool? = nil) -> AFGoalEditor {
//        let arrayPath = self.fullPath + ["goals"]
//
//        let index = coreData.data[arrayPath].count
//        let newGoalNode: JSON = [:]
//
//        coreData.data[arrayPath].arrayObject!.append(newGoalNode)
//        let goalPath = arrayPath + [index]
//        let editor = AFGoalEditor(core: core, fullPath: self.fullPath, type: type, objectAgents: objectAgents,
//                                  angle: angle, distance: distance, speed: speed, time: time, forward: forward)
//
//        editor.name = NSUUID().uuidString
//
//        let newArrayNode: JSON = []
//        coreData.data[goalPath]["objectAgents"] = newArrayNode
//
//        if let objectAgents = objectAgents {
//            objectAgents.forEach { coreData.data[goalPath]["objectAgents"].arrayObject!.append($0) }
//        }
//
//        coreData.data[goalPath]["angle"].float = angle
//        coreData.data[goalPath]["distance"].float = distance
//        coreData.data[goalPath]["speed"].float = speed
//        coreData.data[goalPath]["time"].double = time
//        coreData.data[goalPath]["forward"].bool = forward
//        coreData.data[goalPath]["weight"].float = weight
//        coreData.data[goalPath]["name"].string = editor.name
//        coreData.data[goalPath]["type"].string = type.rawValue
//
//        announceNewGoal(goalName: self.name)
//
//        return editor
//    }
//
//    func getGoal(name: String) -> (goal: AFGoalEditor, weight: Float) {
//        let goals_ = JSON(coreData.data[fullPath]["goals"]).arrayObject!
//        let goals = goals_ as! [(AFGoalEditor, Float)]
//        for (goal, weight) in goals {
//            if goal.name == name { return (goal, weight) }
//        }
//
//        fatalError()
//    }
//
//    func getIsEnabled(goal: String) -> Bool {
//        return true
//    }
//
//    func getWeight(forGoal name: String) -> Float {
//        return getGoal(name: name).weight
//    }
//
//    func setWeight(forGoal name: String, to: Float) {
//        let goals_ = JSON(coreData.data[fullPath]["goals"]).arrayObject!
//        let goals = goals_ as! [(goal: AFGoalEditor, weight: Float)]
//        let ix = goals.filter { $0.goal.name == name }.count - 1
//        coreData.data[fullPath]["goals"][ix]["weight"] = JSON(to)
//    }*/
}

