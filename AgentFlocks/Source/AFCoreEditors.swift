//
// Created by Rob Bishop on 1/30/18
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

class AFAgentEditor {
    var compositeEditor: AFCompositeEditor!
    private let coreData: AFCoreData
    private let fullPath: [JSONSubscriptType]
    var name = String()
    
    init(coreData: AFCoreData, fullPath toHere: [JSONSubscriptType]) {
        self.coreData = coreData
        self.fullPath = toHere
    }
    
    init(coreData: AFCoreData, name: String) {
        self.coreData = coreData
        self.fullPath = coreData.getPathTo(name)!
        self.name = name
    }
    
    fileprivate func announceNewCompositeEditor(agentName: String) { coreData.announce(event: .NewBehavior, subjectName: agentName) }
    
    func asJsonString() -> String {
        return ""//coreData.rawString()!
    }
    
    func createCompositeEditor() -> AFCompositeEditor {
        let hisFullPath = self.fullPath + ["composite"]
        let editor = AFCompositeEditor(coreData: coreData, fullPath: hisFullPath)
        
        let newCompositeNode: JSON = []
        let short = Array(hisFullPath.prefix(hisFullPath.count - 1))
        coreData.data[short].dictionaryObject!["composite"] = newCompositeNode
        
        announceNewCompositeEditor(agentName: name)
        
        return editor
    }
}

extension AFAgentEditor {
    var isPaused: Bool {
        get { return JSON(coreData.data[fullPath]["isPaused"]).boolValue }
        set { coreData.data[fullPath]["isPaused"] = JSON(newValue) }
    }
    
    var mass: Float {
        get { return JSON(coreData.data[fullPath]["mass"]).floatValue }
        set { coreData.data[fullPath]["mass"] = JSON(newValue) }
    }
    
    var maxAcceleration: Float {
        get { return JSON(coreData.data[fullPath]["maxAcceleration"]).floatValue }
        set { coreData.data[fullPath]["maxAcceleration"] = JSON(newValue) }
    }
    
    var maxSpeed: Float {
        get { return JSON(coreData.data[fullPath]["maxSpeed"]).floatValue }
        set { coreData.data[fullPath]["maxSpeed"] = JSON(newValue) }
    }
    
    var radius: Float {
        get { return JSON(coreData.data[fullPath]["radius"]).floatValue }
        set { coreData.data[fullPath]["radius"] = JSON(newValue) }
    }
    
    var scale: Float {
        get { return JSON(coreData.data[fullPath]["scale"]).floatValue }
        set { coreData.data[fullPath]["scale"] = JSON(newValue) }
    }
}

enum AFAgentAttributeType: String { case isPaused, mass, maxAcceleration, maxSpeed, radius, scale }

class AFBehaviorEditor {
    let coreData: AFCoreData
    let fullPath: [JSONSubscriptType]
    var goals = [(AFGoalEditor, Float)]()
    var name = String()
    
    init(coreData: AFCoreData, fullPath toHere: [JSONSubscriptType]) {
        self.coreData = coreData
        self.fullPath = toHere
    }
    
    fileprivate func announceNewGoal(goalName: String) { coreData.announce(event: .NewGoal, subjectName: goalName) }
    
    func createGoal(type: AFGoalEditor.AFGoalType, weight: Float,
                    objectAgents: [String]? = nil, angle: Float? = nil, distance: Float? = nil,
                    speed: Float? = nil, time: TimeInterval? = nil, forward: Bool? = nil) -> AFGoalEditor {
        let arrayPath = self.fullPath + ["goals"]
        
        let index = coreData.data[arrayPath].count
        let newGoalNode: JSON = [:]
        
        coreData.data[arrayPath].arrayObject!.append(newGoalNode)
        let goalPath = arrayPath + [index]
        let editor = AFGoalEditor(coreData: coreData, fullPath: self.fullPath, type: type, objectAgents: objectAgents,
                                  angle: angle, distance: distance, speed: speed, time: time, forward: forward)
        
        editor.name = NSUUID().uuidString
        
        let newArrayNode: JSON = []
        coreData.data[goalPath]["objectAgents"] = newArrayNode
        
        if let objectAgents = objectAgents {
            objectAgents.forEach { coreData.data[goalPath]["objectAgents"].arrayObject!.append($0) }
        }
        
        coreData.data[goalPath]["angle"].float = angle
        coreData.data[goalPath]["distance"].float = distance
        coreData.data[goalPath]["speed"].float = speed
        coreData.data[goalPath]["time"].double = time
        coreData.data[goalPath]["forward"].bool = forward
        coreData.data[goalPath]["weight"].float = weight
        coreData.data[goalPath]["name"].string = editor.name
        coreData.data[goalPath]["type"].string = type.rawValue
        
        announceNewGoal(goalName: self.name)
        
        return editor
    }
    
    func getGoal(name: String) -> (goal: AFGoalEditor, weight: Float) {
        let goals_ = JSON(coreData.data[fullPath]["goals"]).arrayObject!
        let goals = goals_ as! [(AFGoalEditor, Float)]
        for (goal, weight) in goals {
            if goal.name == name { return (goal, weight) }
        }
        
        fatalError()
    }
    
    func getIsEnabled(goal: String) -> Bool {
        return true
    }
    
    func getWeight(forGoal name: String) -> Float {
        return getGoal(name: name).weight
    }
    
    func setWeight(forGoal name: String, to: Float) {
        let goals_ = JSON(coreData.data[fullPath]["goals"]).arrayObject!
        let goals = goals_ as! [(goal: AFGoalEditor, weight: Float)]
        let ix = goals.filter { $0.goal.name == name }.count - 1
        coreData.data[fullPath]["goals"][ix]["weight"] = JSON(to)
    }
}

class AFCompositeEditor {
    let coreData: AFCoreData
    var behaviors = [(behavior: AFBehaviorEditor, weight: Float)]()
    let fullPath: [JSONSubscriptType]
    var name = String()
    
    init(coreData: AFCoreData, fullPath toHere: [JSONSubscriptType]) {
        self.coreData = coreData
        self.fullPath = toHere
    }
    
    func asJsonString() -> String {
        return ""//String(describing: coreData[fullPath])
    }
    
    fileprivate func announceNewBehavior(behaviorName: String) { coreData.announce(event: .NewBehavior, subjectName: behaviorName) }
    
    func createBehavior(weight: Float) -> AFBehaviorEditor {
        let index = coreData.data[self.fullPath].count
        let arrayPath = self.fullPath + [index]
        let newBehaviorNode: JSON = [:]
        
        coreData.data[self.fullPath].arrayObject!.append(newBehaviorNode)
        let editor = AFBehaviorEditor(coreData: coreData, fullPath: arrayPath)
        
        editor.name = NSUUID().uuidString
        
        let behaviorPath = arrayPath
        coreData.data[behaviorPath]["name"] = JSON(editor.name)
        coreData.data[behaviorPath]["weight"] = JSON(weight)
        
        let newGoalsArrayNode: JSON = []
        coreData.data[behaviorPath]["goals"] = newGoalsArrayNode
        
        announceNewBehavior(behaviorName: editor.name)
        
        return editor
    }
    
    func getBehavior(name: String) -> (behavior: AFBehaviorEditor, weight: Float) {
        let behaviors_ = JSON(coreData.data[fullPath]["behaviors"]).arrayObject!
        let behaviors = behaviors_ as! [(AFBehaviorEditor, Float)]
        for (behavior, weight) in behaviors {
            if behavior.name == name { return (behavior, weight) }
        }
        
        fatalError()
    }
    
    func getIsEnabled(behavior: String) -> Bool {
        return true
    }
    
    func getWeight(forBehavior name: String) -> Float {
        return getBehavior(name: name).weight
    }
    
    func setWeight(forBehavior name: String, to: Float) {
        let behaviors_ = JSON(coreData.data[fullPath]["behaviors"]).arrayObject!
        let behaviors = behaviors_ as! [(behavior: AFBehaviorEditor, weight: Float)]
        let ix = behaviors.filter { $0.behavior.name == name }.count - 1
        coreData.data[fullPath]["behaviors"][ix]["weight"] = JSON(to)
    }
}

class AFGoalEditor {
    var angle: Float?
    let coreData: AFCoreData
    var distance: Float?
    var forward: Bool?
    var fullPath: [JSONSubscriptType]
    var name = String()
    var obstacles: [String]?
    var path: String?
    var speed: Float?
    var objectAgents: [String]?
    var time: TimeInterval?
    
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
    
    init(coreData: AFCoreData, fullPath toHere: [JSONSubscriptType]) {
        self.coreData = coreData
        self.fullPath = toHere
    }
    
    init(coreData: AFCoreData, editor: AFGoalEditor, gameScene: SKScene) {
        self.coreData = coreData
        self.fullPath = []
    }
    
    init(coreData: AFCoreData, fullPath toHere: [JSONSubscriptType], type: AFGoalType,
         objectAgents: [String]? = nil, path: String? = nil,
         angle: Float? = nil, distance: Float? = nil, speed: Float? = nil, time: TimeInterval? = nil,
         forward: Bool? = nil) {
        self.fullPath = toHere
        self.coreData = coreData
    }
    
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

class AFPathEditor {
    
}

class AFGraphNodeEditor {
    
}
