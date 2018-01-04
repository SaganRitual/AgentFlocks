//
// Created by Rob Bishop on 1/3/18
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

enum AFGoalType: String, Codable {
    case toAlignWith, toAvoidAgents, toAvoidObstacles, toCohereWith, toFleeAgent, toFollow,
    toInterceptAgent, toReachTargetSpeed, toSeekAgent, toSeparateFrom, toStayOn, toWander
}

class AFGoal_Script: Codable {
    var enabled = true
    var forward = true
    let goalType: AFGoalType
    var weight: Float
    
    var angle: Float = 0
    var distance: Float = 0
    var speed: Float = 0
    var time: Float = 0
    
    init(goal: AFGoal) {
        enabled = goal.enabled
        forward = goal.forward
        goalType = goal.goalType
        weight = goal.weight
        angle = goal.angle
        distance = goal.distance
        speed = goal.speed
        time = goal.time
    }
}

class AFGoal {
    var agents = [GKAgent]()
    var enabled = true
    var forward = true
    var gkGoal: GKGoal!
    let goalType: AFGoalType
    var obstacles = [GKObstacle]()
    var path = GKPath()
    var weight: Float
    
    var angle: Float = 0
    var distance: Float = 0
    var time: Float = 0

    var speed: Float = 0 {
        willSet(newValue) {
            newGoal(newValue: newValue)
        }
    }

    init(prototype: AFGoal_Script) {
        enabled = prototype.enabled
        
        angle = prototype.angle
        distance = prototype.distance
        goalType = prototype.goalType
        speed = prototype.speed
        weight = prototype.weight
        
        switch goalType {
        case .toAlignWith:        break
        case .toAvoidAgents:      break
        case .toAvoidObstacles:   break
        case .toCohereWith:       break
        case .toFleeAgent:        break
        case .toFollow:           break
        case .toInterceptAgent:   break
        case .toReachTargetSpeed:
            newGoal(newValue: speed)
        case .toSeekAgent:        break
        case .toSeparateFrom:     break
        case .toStayOn:           break
        case .toWander:
            newGoal(newValue: speed)
        }
    }
    
    init(copyFrom: AFGoal) {
        goalType = copyFrom.goalType

        self.angle = copyFrom.angle
        self.distance = copyFrom.distance
        self.time = copyFrom.time
        self.speed = copyFrom.speed
        self.weight = copyFrom.weight
    }
    
    init(toAlignWith agents: [GKAgent], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toAlignWith
        
        self.agents = agents
        self.angle = maxAngle
        self.distance = maxDistance
        self.weight = weight
        
        gkGoal = GKGoal(toAlignWith: agents, maxDistance: maxDistance, maxAngle: maxAngle)
    }
    
    init(toAvoidAgents agents: [GKAgent], time: TimeInterval, weight: Float) {
        goalType = .toAvoidAgents
        
        self.agents = agents
        self.time = Float(time)
        self.weight = weight
        
        gkGoal = GKGoal(toAvoid: agents, maxPredictionTime: time)
    }
    
    init(toAvoidObstacles obstacles: [GKObstacle], time: TimeInterval, weight: Float) {
        goalType = .toAvoidObstacles
        
        self.obstacles = obstacles
        self.time = Float(time)
        self.weight = weight
        
        gkGoal = GKGoal(toAvoid: obstacles, maxPredictionTime: time)
    }
    
    init(toCohereWith agents: [GKAgent], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toCohereWith
        
        self.agents = agents
        self.angle = maxAngle
        self.distance = maxDistance
        self.weight = weight
        
        gkGoal = GKGoal(toCohereWith: agents, maxDistance: maxDistance, maxAngle: maxAngle)
    }
    
    init(toInterceptAgent agent: GKAgent, time: TimeInterval, weight: Float) {
        goalType = .toInterceptAgent
        
        self.time = Float(time)
        self.weight = weight
        
        gkGoal = GKGoal(toInterceptAgent: agent, maxPredictionTime: time)
    }
    
    init(toFleeAgent agent: GKAgent, weight: Float) {
        goalType = .toFleeAgent
        
        self.weight = weight
        
        gkGoal = GKGoal(toFleeAgent: agent)
    }

    init(toFollow path: GKPath, time t: Float, forward: Bool, weight: Float) {
        goalType = .toFollow
        
        self.time = t
        self.weight = weight
        
        gkGoal = GKGoal(toFollow: path, maxPredictionTime: TimeInterval(t), forward: true)
    }
    
    init(toReachTargetSpeed speed: Float, weight: Float) {
        goalType = .toReachTargetSpeed
        
        self.speed = speed
        self.weight = weight
        
        gkGoal = GKGoal(toReachTargetSpeed: speed)
    }
    
    init(toSeekAgent agent: GKAgent, weight: Float) {
        goalType = .toSeekAgent
        
        self.weight = weight
        
        gkGoal = GKGoal(toSeekAgent: agent)
    }
    
    init(toSeparateFrom agents: [GKAgent], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toSeparateFrom
        
        self.agents = agents
        self.angle = maxAngle
        self.distance = maxDistance
        self.weight = weight
        
        gkGoal = GKGoal(toSeparateFrom: agents, maxDistance: maxDistance, maxAngle: maxAngle)
    }
    
    init(toStayOn path: GKPath, time t: Float, weight: Float) {
        goalType = .toStayOn
        
        self.time = t
        self.weight = weight
        
        gkGoal = GKGoal(toStayOn: path, maxPredictionTime: TimeInterval(t))
    }
    
    init(toWander speed: Float, weight: Float) {
        goalType = .toWander
        self.speed = speed
        self.weight = weight
        
        gkGoal = GKGoal(toWander: speed)
    }
    
    init(goal: GKGoal, type: AFGoalType, weight: Float) {
        self.gkGoal = goal
        self.goalType = type
        self.weight = weight
    }
    
    func newGoal(newValue: Float) {
        switch goalType {
        case .toReachTargetSpeed: gkGoal = GKGoal(toReachTargetSpeed: newValue)
        case .toWander:           gkGoal = GKGoal(toWander: newValue)
        default: fatalError()
        }
    }
    
    func toString() -> String {
        let m: [AFGoalType: String] = [
            .toAlignWith: "Align: %.0f", .toAvoidAgents: "Avoid agents: %.0f", .toAvoidObstacles: "Avoid obstacles: %.0f",
            .toCohereWith: "Cohere: %.0f", .toFleeAgent: "Flee: %.0f", .toFollow: "Follow path: %.0f",
            .toInterceptAgent: "Intercept: %.0f", .toReachTargetSpeed: "Speed: %.0f", .toSeekAgent: "Seek: %.0f",
            .toSeparateFrom: "Separate from: %.0f", .toStayOn: "Stay on path: %.0f", .toWander: "Wander: %.0f"
        ]
        
        return String(format: m[goalType]!, weight)
    }
}

// MARK: Goal factory

extension AFGoal {
    static func makeGoal(copyFrom: AFGoal) -> AFGoal {
        switch copyFrom.goalType {
        case .toSeekAgent:        fallthrough
        case .toFleeAgent:        return makeGoal(copyFrom.goalType, agent: copyFrom.agents[0])

        case .toReachTargetSpeed: fallthrough
        case .toWander:           return makeGoal(copyFrom.goalType, speed: copyFrom.speed)

        case .toAvoidAgents:      return makeGoal(copyFrom.goalType, agents: copyFrom.agents, time: copyFrom.time)
        case .toAvoidObstacles:   return makeGoal(copyFrom.goalType, obstacles: copyFrom.obstacles, time: copyFrom.time)
        case .toInterceptAgent:   return makeGoal(copyFrom.goalType, agent: copyFrom.agents[0], time: copyFrom.time)

        case .toAlignWith:        fallthrough
        case .toCohereWith:       fallthrough
        case .toSeparateFrom:     return makeGoal(copyFrom.goalType, agents: copyFrom.agents, distance: copyFrom.distance, angle: copyFrom.angle)

        case .toFollow:           fallthrough
        case .toStayOn:           return makeGoal(copyFrom.goalType, path: copyFrom.path, time: copyFrom.time, forward: copyFrom.forward)
        }
    }
    
    static func makeGoal(_ type: AFGoalType, path: GKPath, time: Float, forward: Bool) -> AFGoal {
        switch type {
        case .toFollow: return AFGoal(toFollow: path, time: time, forward: forward, weight: -1)
        case .toStayOn: return AFGoal(toStayOn: path, time: time, weight: -1)
            
        default: fatalError()
        }
    }
    
    static func makeGoal(_ type: AFGoalType, agents: [GKAgent], distance: Float, angle: Float) -> AFGoal {
        switch type {
        case .toAlignWith:    return AFGoal(toAlignWith: agents, maxDistance: distance, maxAngle: angle, weight: -1)
        case .toCohereWith:   return AFGoal(toCohereWith: agents, maxDistance: distance, maxAngle: angle, weight: -1)
        case .toSeparateFrom: return AFGoal(toSeparateFrom: agents, maxDistance: distance, maxAngle: angle, weight: -1)
            
        default: fatalError()
        }
    }
    
    static func makeGoal(_ type: AFGoalType, obstacles: [GKObstacle], time: Float) -> AFGoal {
        switch type {
        case .toAvoidObstacles: return AFGoal(toAvoidObstacles: obstacles, time: TimeInterval(time), weight: -1)
            
        default: fatalError()
        }
    }

    static func makeGoal(_ type: AFGoalType, agents: [GKAgent], time: Float) -> AFGoal {
        switch type {
        case .toAvoidAgents: return AFGoal(toAvoidAgents: agents, time: TimeInterval(time), weight: -1)
            
        default: fatalError()
        }
    }
    
    static func makeGoal(_ type: AFGoalType, agent: GKAgent, time: Float? = nil) -> AFGoal {
        switch type {
        case .toFleeAgent: return AFGoal(toFleeAgent: agent, weight: -1)
        case .toSeekAgent: return AFGoal(toSeekAgent: agent, weight: -1)
            
        default: fatalError()
        }
    }

    static func makeGoal(_ type: AFGoalType, speed: Float) -> AFGoal {
        switch type {
        case .toReachTargetSpeed: return AFGoal(toReachTargetSpeed: speed, weight: -1)
        case .toWander:           return AFGoal(toWander: speed, weight: -1)
            
        default: fatalError()
        }
    }
}

