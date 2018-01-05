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
    var agentNames = [String]()
    var enabled = true
    var forward = true
    let goalType: AFGoalType
    let name: String
    let pathname: String
    var weight: Float
    
    var angle: Float = 0
    var distance: Float = 0
    var speed: Float = 0
    var time: Float = 0
    
    init(goal: AFGoal) {
        agentNames = goal.agentNames
        enabled = goal.enabled
        forward = goal.forward
        goalType = goal.goalType
        pathname = goal.pathname ?? ""
        weight = goal.weight
        angle = goal.angle
        distance = goal.distance
        speed = goal.speed
        time = goal.time
        name = goal.name
    }
}

class AFGoal {
    var agentNames = [String]()
    var agents = [GKAgent]()
    var enabled = true
    var forward = true
    var gkGoal: GKGoal!
    let goalType: AFGoalType
    var obstacles = [GKObstacle]()
    let name: String
    var path = GKPath()
    var pathname: String?
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
        
        agentNames = prototype.agentNames
        angle = prototype.angle
        distance = prototype.distance
        goalType = prototype.goalType
        speed = prototype.speed
        time = prototype.time
        weight = prototype.weight
        
        name = prototype.name
        pathname = prototype.pathname
        
        switch goalType {
        case .toAlignWith:
            var gkAgents = [GKAgent]()
            for aligneeName in agentNames {
                for entity in GameScene.me!.entities {
                    if entity.name == aligneeName {
                        gkAgents.append(entity.agent)
                    }
                }
            }
            gkGoal = GKGoal(toAlignWith: gkAgents, maxDistance: distance, maxAngle: angle)

        case .toAvoidAgents:
            var gkAgents = [GKAgent]()
            for avoideeName in agentNames {
                for entity in GameScene.me!.entities {
                    if entity.name == avoideeName {
                        gkAgents.append(entity.agent)
                    }
                }
            }
            gkGoal = GKGoal(toAvoid: gkAgents, maxPredictionTime: TimeInterval(time))
            
        case .toAvoidObstacles:
            if let p = pathname {
                if p == "" {
                    // This is the special boundary we draw around the scene. We don't
                    // include it in the path map.
                    gkGoal = GKGoal(toAvoid: GameScene.me!.corral, maxPredictionTime: 10)
                } else {
                    print(p, GameScene.me!.paths)
                    let afPath = GameScene.me!.paths[p]!
                    let obstacle = afPath.makeObstacle()

                    gkGoal = GKGoal(toAvoid: [obstacle], maxPredictionTime: TimeInterval(time))
                }
            } else {
                fatalError()
            }
        

        case .toCohereWith:       break
        case .toFleeAgent:        break
            
        case .toFollow:
            let afPath = GameScene.me!.paths[pathname!]!
            gkGoal = GKGoal(toFollow: afPath.gkPath, maxPredictionTime: TimeInterval(time), forward: forward)

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

        self.agentNames = copyFrom.agentNames
        self.angle = copyFrom.angle
        self.distance = copyFrom.distance
        self.time = copyFrom.time
        self.speed = copyFrom.speed
        self.weight = copyFrom.weight
        self.name = copyFrom.name
        self.pathname = copyFrom.pathname
    }
    
    init(toAlignWith agentNames: [String], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toAlignWith
        
        var gkAgents = [GKAgent]()
        for entity in GameScene.me!.entities {
            if agentNames.contains(entity.name) {
                gkAgents.append(entity.agent)
            }
        }
        
        self.agentNames = agentNames
        self.agents = gkAgents
        self.angle = maxAngle
        self.distance = maxDistance
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toAlignWith: gkAgents, maxDistance: maxDistance, maxAngle: maxAngle)
    }
    
    init(toAvoidAgents agentNames: [String], time: TimeInterval, weight: Float) {
        goalType = .toAvoidAgents
        
        var gkAgents = [GKAgent]()
        for entity in GameScene.me!.entities {
            if agentNames.contains(entity.name) {
                gkAgents.append(entity.agent)
            }
        }

        self.agentNames = agentNames
        self.agents = gkAgents
        self.name = NSUUID().uuidString
        self.time = Float(time)
        self.weight = weight
        
        gkGoal = GKGoal(toAvoid: agents, maxPredictionTime: time)
    }
    
    init(toAvoidObstacles obstacles: [GKObstacle], time: TimeInterval, weight: Float) {
        goalType = .toAvoidObstacles
        
        self.name = NSUUID().uuidString
        self.obstacles = obstacles
        self.time = Float(time)
        self.weight = weight
        
        gkGoal = GKGoal(toAvoid: obstacles, maxPredictionTime: time)
    }
    
    init(toCohereWith agentNames: [String], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toCohereWith
        
        var gkAgents = [GKAgent]()
        for entity in GameScene.me!.entities {
            if agentNames.contains(entity.name) {
                gkAgents.append(entity.agent)
            }
        }
        
        self.agents = gkAgents
        self.agentNames = agentNames
        self.angle = maxAngle
        self.distance = maxDistance
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toCohereWith: gkAgents, maxDistance: maxDistance, maxAngle: maxAngle)
    }
    
    init(toInterceptAgent agentName: String, time: TimeInterval, weight: Float) {
        goalType = .toInterceptAgent
        
        var gkAgents = [GKAgent]()
        for entity in GameScene.me!.entities {
            if agentName == entity.name {
                gkAgents.append(entity.agent)
            }
        }

        self.agentNames = [agentName]
        self.agents = gkAgents
        self.time = Float(time)
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toInterceptAgent: self.agents[0], maxPredictionTime: time)
    }
    
    init(toFleeAgent agentName: String, weight: Float) {
        goalType = .toFleeAgent
        
        var gkAgents = [GKAgent]()
        for entity in GameScene.me!.entities {
            if agentName == entity.name {
                gkAgents.append(entity.agent)
            }
        }

        self.agentNames = [agentName]
        self.agents = gkAgents
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toFleeAgent: self.agents[0])
    }

    init(toFollow path: GKPath, time t: Float, forward: Bool, weight: Float) {
        goalType = .toFollow
        
        self.name = NSUUID().uuidString
        self.time = t
        self.weight = weight
        
        gkGoal = GKGoal(toFollow: path, maxPredictionTime: TimeInterval(t), forward: true)
    }
    
    init(toReachTargetSpeed speed: Float, weight: Float) {
        goalType = .toReachTargetSpeed
        
        self.name = NSUUID().uuidString
        self.speed = speed
        self.weight = weight
        
        gkGoal = GKGoal(toReachTargetSpeed: speed)
    }
    
    init(toSeekAgent agentName: String, weight: Float) {
        goalType = .toSeekAgent
        
        var gkAgents = [GKAgent]()
        for entity in GameScene.me!.entities {
            if agentName == entity.name {
                gkAgents.append(entity.agent)
            }
        }

        self.agentNames = [agentName]
        self.agents = gkAgents
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toSeekAgent: self.agents[0])
    }
    
    init(toSeparateFrom agentNames: [String], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toSeparateFrom
        
        var gkAgents = [GKAgent]()
        for entity in GameScene.me!.entities {
            if agentNames.contains(entity.name) {
                gkAgents.append(entity.agent)
            }
        }
        
        self.agentNames = agentNames
        self.agents = gkAgents
        self.angle = maxAngle
        self.distance = maxDistance
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toSeparateFrom: gkAgents, maxDistance: maxDistance, maxAngle: maxAngle)
    }
    
    init(toStayOn path: GKPath, time t: Float, weight: Float) {
        goalType = .toStayOn
        
        self.name = NSUUID().uuidString
        self.time = t
        self.weight = weight
        
        gkGoal = GKGoal(toStayOn: path, maxPredictionTime: TimeInterval(t))
    }
    
    init(toWander speed: Float, weight: Float) {
        goalType = .toWander

        self.name = NSUUID().uuidString
        self.speed = speed
        self.weight = weight
        
        gkGoal = GKGoal(toWander: speed)
    }
    
    init(goal: GKGoal, type: AFGoalType, weight: Float) {
        self.gkGoal = goal
        self.goalType = type
        self.name = NSUUID().uuidString
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
        case .toFleeAgent:        return makeGoal(copyFrom.goalType, agent: copyFrom.agentNames[0])

        case .toReachTargetSpeed: fallthrough
        case .toWander:           return makeGoal(copyFrom.goalType, speed: copyFrom.speed)

        case .toAvoidAgents:      return makeGoal(copyFrom.goalType, agents: copyFrom.agentNames, time: copyFrom.time)
        case .toAvoidObstacles:   return makeGoal(copyFrom.goalType, obstacles: copyFrom.obstacles, time: copyFrom.time)
        case .toInterceptAgent:   return makeGoal(copyFrom.goalType, agent: copyFrom.agentNames[0], time: copyFrom.time)

        case .toAlignWith:        fallthrough
        case .toCohereWith:       fallthrough
        case .toSeparateFrom:
            return makeGoal(copyFrom.goalType, agentNames: copyFrom.agentNames, distance: copyFrom.distance, angle: copyFrom.angle)

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
    
    static func makeGoal(_ type: AFGoalType, agentNames: [String], distance: Float, angle: Float) -> AFGoal {
        switch type {
        case .toAlignWith:    return AFGoal(toAlignWith: agentNames, maxDistance: distance, maxAngle: angle, weight: -1)
        case .toCohereWith:   return AFGoal(toCohereWith: agentNames, maxDistance: distance, maxAngle: angle, weight: -1)
        case .toSeparateFrom: return AFGoal(toSeparateFrom: agentNames, maxDistance: distance, maxAngle: angle, weight: -1)
            
        default: fatalError()
        }
    }
    
    static func makeGoal(_ type: AFGoalType, obstacles: [GKObstacle], time: Float) -> AFGoal {
        switch type {
        case .toAvoidObstacles: return AFGoal(toAvoidObstacles: obstacles, time: TimeInterval(time), weight: -1)
            
        default: fatalError()
        }
    }

    static func makeGoal(_ type: AFGoalType, agents: [String], time: Float) -> AFGoal {
        switch type {
        case .toAvoidAgents: return AFGoal(toAvoidAgents: agents, time: TimeInterval(time), weight: -1)
            
        default: fatalError()
        }
    }
    
    static func makeGoal(_ type: AFGoalType, agent: String, time: Float? = nil) -> AFGoal {
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

