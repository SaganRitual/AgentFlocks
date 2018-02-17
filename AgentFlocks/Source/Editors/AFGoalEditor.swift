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

class AFGoalEditor: AFMotivatorEditor {
    override var parentEditor: AFMotivatorEditor {
        let pathToParent = AFData.getPathToParent(pathToHere)
        return AFBehaviorEditor(pathToParent, core: core)
    }
    
    enum AFGoalType: String {
        case toAlignWith, toAvoidAgents, toAvoidObstacles, toCohereWith, toFleeAgent, toFollow,
        toInterceptAgent, toReachTargetSpeed, toSeekAgent, toSeparateFrom, toStayOn, toWander
    }
    
    override func setOptionalScalar(_ nodeName: String, to value: Float) {
        switch nodeName {
        case "angle":    angle = value
        case "distance": distance = value
        case "speed":    speed = value
        case "time":     time = TimeInterval(value)
        default:
            fatalError()
        }
    }
}

// MARK: Main entry point for composing goals

extension AFGoalEditor {
    func composeGoal(attributes: MotivatorAttributes, targetAgents: [String]?) {
        switch attributes.newItemType! {
        case .toAlignWith:    composeGoal_toAlignWith(targetAgents!, angle: Float(attributes.angle!.value), distance: Float(attributes.distance!.value))
        case .toCohereWith:   composeGoal_toCohereWith(targetAgents!, angle: Float(attributes.angle!.value), distance: Float(attributes.distance!.value))
        case .toSeparateFrom: composeGoal_toSeparateFrom(targetAgents!, angle: Float(attributes.angle!.value), distance: Float(attributes.distance!.value))

        case .toAvoidAgents:    composeGoal_toAvoidAgents(targetAgents!, time: attributes.time!.value)
        case .toInterceptAgent: composeGoal_toInterceptAgent(targetAgents![0], time: attributes.time!.value)

        case .toFleeAgent: composeGoal_toFleeAgent(targetAgents![0])
        case .toSeekAgent: composeGoal_toSeekAgent(targetAgents![0])

        case .toReachTargetSpeed: composeGoal_toReachTargetSpeed(Float(attributes.speed!.value))
        case .toWander:           composeGoal_toWander(speed: Float(attributes.speed!.value))

        case .toAvoidObstacles: fatalError("Not implemented")
        case .toFollow: fatalError("Not implmeentdd")
        case .toStayOn: fatalError("Not implemented")
        }
    }
}

// MARK: Goal-specific composition functions

private extension AFGoalEditor {

    func composeGoal_toWander(speed: Float)             { _composeGoal_speed(.toWander, speed: speed) }
    func composeGoal_toReachTargetSpeed(_ speed: Float) { _composeGoal_speed(.toReachTargetSpeed, speed: speed) }
    
    private func _composeGoal_speed(_ type: AFGoalType, speed: Float) {
        guard self.type == nil else { fatalError() }
        self.type = type
        self.speed = speed
    }
    
    func composeGoal_toFollow(_ path: String, forward: Bool, time: TimeInterval) {
        _composeGoal_path(.toFollow, path: path, time: time, forward: forward)
    }
    
    func composeGoal_toStayOn(_ path: String, time: TimeInterval) {
        _composeGoal_path(.toStayOn, path: path, time: time)
    }

    private func _composeGoal_path(_ type: AFGoalType, path: String, time: TimeInterval, forward: Bool? = nil) {
        guard self.type == nil else { fatalError() }
        self.type = type
        self.path = path
        self.time = time
        
        if let forward = forward { self.forward = forward }
    }
    
    func composeGoal_toFleeAgent(_ agent: String) { _composeGoal_agent(.toFleeAgent, agent: agent) }
    func composeGoal_toSeekAgent(_ agent: String) { _composeGoal_agent(.toSeekAgent, agent: agent) }
    
    func _composeGoal_agent(_ type: AFGoalType, agent: String) {
        guard self.type == nil else { fatalError() }
        self.type = type
        self.agent = agent
    }
    
    func composeGoal_toAlignWith(_ agents: [String], angle: Float, distance: Float) {
        _composeGoal_flock(.toAlignWith, agents: agents, angle: angle, distance: distance)
    }
    
    func composeGoal_toCohereWith(_ agents: [String], angle: Float, distance: Float) {
        _composeGoal_flock(.toCohereWith, agents: agents, angle: angle, distance: distance)
    }
    
    func composeGoal_toSeparateFrom(_ agents: [String], angle: Float, distance: Float) {
        _composeGoal_flock(.toSeparateFrom, agents: agents, angle: angle, distance: distance)
    }

    func _composeGoal_flock(_ type: AFGoalType, agents: [String], angle: Float, distance: Float) {
        guard self.type == nil else { fatalError() }
        self.type = type
        self.agents = agents
        self.angle = angle
        self.distance = distance
    }

    func composeGoal_toAvoidAgents(_ agents: [String], time: TimeInterval) {
        guard self.type == nil else { fatalError() }
        self.type = .toAvoidAgents
        
        self.agents = agents
        self.time = time
    }

    func composeGoal_toAvoidObstacles(_ obstacles: [String], time: TimeInterval) {
        guard self.type == nil else { fatalError() }
        self.type = .toAvoidObstacles
        
        self.obstacles = obstacles
        self.time = time
    }
    
    func composeGoal_toInterceptAgent(_ agent: String, time: TimeInterval) {
        guard self.type == nil else { fatalError() }
        self.type = .toInterceptAgent
        
        self.agent = agent
        self.time = time
    }
}

// MARK: getters & setters

extension AFGoalEditor {
    var agent: String {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.agent.rawValue
            return JSON(core.bigData.data[pathToHere][ix]).stringValue
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.agent.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: ix)
        }
    }
    
    var agents: [String] {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.agents.rawValue
            return JSON(core.bigData.data[pathToHere][ix]).arrayValue.map { $0.stringValue }
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.agents.rawValue
            let jsonArray = newValue.map { JSON($0) }
            getNodeWriter(pathToHere).write(this: JSON(jsonArray), to: ix)
        }
    }

    var angle: Float {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.angle.rawValue
            return JSON(core.bigData.data[pathToHere][ix]).floatValue
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.angle.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: ix)
        }
    }
    
    var distance: Float {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.distance.rawValue
            return JSON(core.bigData.data[pathToHere][ix]).floatValue
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.distance.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: ix)
        }
    }
    
    var forward: Bool {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.forward.rawValue
            return JSON(core.bigData.data[pathToHere][ix]).boolValue
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.forward.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: ix)
        }
    }

    var objectAgents: [JSON] {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.objectAgents.rawValue
            return JSON(core.bigData.data[pathToHere][ix]).arrayValue
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.objectAgents.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: ix)
        }
    }
    
    var obstacles: [String] {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.obstacles.rawValue
            return JSON(core.bigData.data[pathToHere][ix]).arrayValue.map { $0.stringValue }
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.obstacles.rawValue
            let jsonArray = newValue.map { JSON($0) }
            getNodeWriter(pathToHere).write(this: JSON(jsonArray), to: ix)
        }
    }

    var path: String {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.path.rawValue
            return JSON(core.bigData.data[pathToHere][ix]).stringValue
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.path.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: ix)
        }
    }
    
    var speed: Float {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.speed.rawValue
            return JSON(core.bigData.data[pathToHere][ix]).floatValue
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.speed.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: ix)
        }
    }
    
    var time: TimeInterval {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.time.rawValue
            return JSON(core.bigData.data[pathToHere][ix]).doubleValue
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.time.rawValue
            getNodeWriter(pathToHere).write(this: JSON(newValue), to: ix)
        }
    }
    
    // type = nil means it has not been set, ie, the upper layers have created
    // a skeletal goal structure that has not been filled out yet.
    var type: AFGoalType? {
        get {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.type.rawValue
            return AFGoalType(rawValue: JSON(core.bigData.data[pathToHere][ix]).stringValue)
        }
        set {
            let ix: JSONSubscriptType = AFMotivatorEditor.Attributes.type.rawValue
            if let newValue = newValue {
                getNodeWriter(pathToHere).write(this: JSON(newValue.rawValue), to: ix)
            } else {
                fatalError()
            }
        }
    }
}
