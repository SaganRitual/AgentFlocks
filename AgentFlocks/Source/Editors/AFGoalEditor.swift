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

class AFGoalEditor: AFEditor {
//    var angle: Float?
//    var distance: Float?
//    var forward: Bool?
    var pathToHere: [JSONSubscriptType]
//    var name: JSONSubscriptType
//    var obstacles: [String]?
//    var path: String?
//    var speed: Float?
//    var objectAgents: [String]?
//    var time: TimeInterval?
    
    enum AFGoalType: String {
        case toAlignWith, toAvoidAgents, toAvoidObstacles, toCohereWith, toFleeAgent, toFollow,
        toInterceptAgent, toReachTargetSpeed, toSeekAgent, toSeparateFrom, toStayOn, toWander
    }
    
    let stringToType: [String : AFGoalType] =
        ["toAlignWith" : .toAlignWith, "toAvoidAgents": .toAvoidAgents, "toAvoidObstacles": .toAvoidObstacles,
         "toCohereWith": .toCohereWith, "toFleeAgent": .toFleeAgent, "toFollow": .toFollow,
         "toInterceptAgent": .toInterceptAgent, "toReachTargetSpeed": .toReachTargetSpeed,
         "toSeekAgent": .toSeekAgent, "toSeparateFrom": .toSeparateFrom, "toStayOn": .toStayOn, "toWander": .toWander]
    
    let typeToString: [AFGoalType : String] =
        [.toAlignWith: "toAlignWith", .toAvoidAgents: "toAvoidAgents", .toAvoidObstacles: "toAvoidObstacles",
         .toCohereWith: "toCohereWith", .toFleeAgent: "toFleeAgent", .toFollow: "toFollow",
         .toInterceptAgent: "toInterceptAgent", .toReachTargetSpeed: "toReachTargetSpeed",
         .toSeekAgent: "toSeekAgent", .toSeparateFrom: "toSeparateFrom", .toStayOn: "toStayOn", .toWander: "toWander"]

    unowned var core: AFCore
    
    // Create a new, empty goal slot in the data tree.
    init(_ pathToHere: [JSONSubscriptType], core: AFCore) {
        self.core  = core
        self.pathToHere = pathToHere
    }

//    init(pathToBehavior: [JSONSubscriptType], core: AFCore) {
//        self.core = core
//        self.fullPath = pathToBehavior
//        core.bigData.getNodeWriter(for: fullPath).write { core.bigData.data[pathToBehavior].arrayObject?.append(JSON([:])) }
//        print("heckle", self.fullPath, core.bigData.data)
//    }
//
//    init(_ goalName: String, pathToComposite: [JSONSubscriptType], core: AFCore) {
//        self.core = core
//        self.fullPath = pathToComposite + ["behavior"]
//        self.name = goalName
//    }
//
    /*
     func makeGKGoal(theGoalType: AFGoalType) -> GKGoal {
     switch theGoalType {
     case .toFleeAgent: return GKGoal(toFleeAgent: objectAgents![0])
     case .toSeekAgent: return GKGoal(toSeekAgent: objectAgents![0])
     
     case .toReachTargetSpeed: return GKGoal(toReachTargetSpeed: speed!)
     case .toWander:           return GKGoal(toWander: speed!)
     
     case .toAvoidAgents:    return GKGoal(toAvoid: objectAgents!, maxPredictionTime: time!)
     case .toInterceptAgent: return GKGoal(toInterceptAgent: objectAgents![0], maxPredictionTime: time!)
     
     case .toSeparateFrom: return GKGoal(toSeparateFrom: objectAgents!, maxDistance: distance!, maxAngle: angle!)
     case .toAlignWith:    return GKGoal(toAlignWith: objectAgents!, maxDistance: distance!, maxAngle: angle!)
     case .toCohereWith:   return GKGoal(toSeparateFrom: objectAgents!, maxDistance: distance!, maxAngle: angle!)
     
     case .toFollow: return GKGoal(toFollow: path!, maxPredictionTime: time!, forward: forward!)
     case .toStayOn: return GKGoal(toStayOn: path!, maxPredictionTime: time!)
     
     default: fatalError()
     }
     }*/
}

