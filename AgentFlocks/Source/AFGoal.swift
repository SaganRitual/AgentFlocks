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
    var obstacleNames = [String]()
    let pathname: String
    var weight: Float
    
    var angle: Float = 0
    var distance: Float = 0
    var speed: Float = 0
    var time: Float = 0
    
    init(goal: AFGoal) {
        name = goal.name

        enabled = goal.enabled
        forward = goal.forward
        goalType = goal.goalType
        obstacleNames = goal.obstacleNames
        pathname = goal.pathname ?? ""
        weight = goal.weight
        
        angle = goal.angle
        distance = goal.distance
        speed = goal.speed
        time = goal.time

        goal.agentNodes.forEach { agentNames.append($0.name!) }
    }
}

class AFGoal {
    var agentNodes = [SKNode]()
    var agents = [GKAgent]()
    var enabled = true
    var forward = true
    var gkGoal: GKGoal!
    let goalType: AFGoalType
    var obstacleNames = [String]()
    let name: String
    var path = GKPath()
    var pathname: String?
    var weight: Float
    
    var angle: Float = 0
    var distance: Float = 0
    var time: Float = 0
    var speed: Float = 0

    init(prototype: AFGoal_Script) {
        enabled = prototype.enabled
        
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
            for aligneeNode in agentNodes {
                for entity in AFCore.data.entities {
                    if entity.agent.sprite == aligneeNode {
                        gkAgents.append(entity.agent)
                    }
                }
            }
            gkGoal = GKGoal(toAlignWith: gkAgents, maxDistance: distance, maxAngle: angle)

        case .toAvoidAgents:
            var gkAgents = [GKAgent]()
            for avoideeNode in agentNodes {
                for entity in AFCore.data.entities {
                    if entity.agent.sprite == avoideeNode {
                        gkAgents.append(entity.agent)
                    }
                }
            }
            gkGoal = GKGoal(toAvoid: gkAgents, maxPredictionTime: TimeInterval(time))
            
        case .toAvoidObstacles:
            var obstacles = [GKPolygonObstacle]()

            AFCore.data!.obstacles.forEach { obstacles.append($1.asObstacle()!) }
            
            gkGoal = GKGoal(toAvoid: obstacles, maxPredictionTime: TimeInterval(time))

        case .toCohereWith:
            var gkAgents = [GKAgent]()
            for coheree in agentNodes {
                for entity in AFCore.data.entities {
                    if entity.agent.sprite == coheree {
                        gkAgents.append(entity.agent)
                    }
                }
            }
            
            gkGoal = GKGoal(toCohereWith: gkAgents, maxDistance: distance, maxAngle: angle)

        case .toFleeAgent:
            for agentNode in agentNodes {
                for entity in AFCore.data.entities {
                    if entity.agent.sprite == agentNode {
                        gkGoal = GKGoal(toFleeAgent: entity.agent)
                        break
                    }
                }
            }

        case .toFollow:
            let afPath = AFCore.data.paths[pathname!]!
            gkGoal = GKGoal(toFollow: afPath.gkPath, maxPredictionTime: TimeInterval(time), forward: forward)

        case .toInterceptAgent:
            for agentNode in agentNodes {
                for entity in AFCore.data.entities {
                    if entity.agent.sprite == agentNode {
                        gkGoal = GKGoal(toInterceptAgent: entity.agent, maxPredictionTime: TimeInterval(time))
                        break
                    }
                }
            }

        case .toReachTargetSpeed:
            gkGoal = GKGoal(toReachTargetSpeed: speed)
            
        case .toSeekAgent:
            for agentNode in agentNodes {
                for entity in AFCore.data.entities {
                    if entity.agent.sprite == agentNode {
                        gkGoal = GKGoal(toSeekAgent: entity.agent)
                        break
                    }
                }
            }

        case .toSeparateFrom:
            var gkAgents = [GKAgent]()
            for separatee in agentNodes {
                for entity in AFCore.data.entities {
                    if entity.agent.sprite == separatee {
                        gkAgents.append(entity.agent)
                    }
                }
            }
            
            gkGoal = GKGoal(toSeparateFrom: gkAgents, maxDistance: distance, maxAngle: angle)
            
        case .toStayOn:
            let afPath = AFCore.data.paths[pathname!]!
            gkGoal = GKGoal(toStayOn: afPath.gkPath, maxPredictionTime: TimeInterval(time))
            
        case .toWander:
            gkGoal = GKGoal(toWander: speed)
        }
    }
    
    init(copyFrom: AFGoal) {
        goalType = copyFrom.goalType

        self.agentNodes = copyFrom.agentNodes
        self.angle = copyFrom.angle
        self.distance = copyFrom.distance
        self.time = copyFrom.time
        self.speed = copyFrom.speed
        self.weight = copyFrom.weight
        self.name = copyFrom.name
        self.pathname = copyFrom.pathname
    }
    
    init(toAlignWith agentNodes: [SKNode], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toAlignWith
        
        var gkAgents = [GKAgent]()
        for entity in AFCore.data.entities {
            if agentNodes.contains(entity.agent.sprite) {
                gkAgents.append(entity.agent)
            }
        }
        
        self.agentNodes = agentNodes
        self.agents = gkAgents
        self.angle = maxAngle
        self.distance = maxDistance
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toAlignWith: gkAgents, maxDistance: maxDistance, maxAngle: maxAngle)
    }
    
    init(toAvoidAgents agentNodes: [SKNode], time: TimeInterval, weight: Float) {
        goalType = .toAvoidAgents
        
        var gkAgents = [GKAgent]()
        for entity in AFCore.data.entities {
            if agentNodes.contains(entity.agent.sprite) {
                gkAgents.append(entity.agent)
            }
        }

        self.agentNodes = agentNodes
        self.agents = gkAgents
        self.name = NSUUID().uuidString
        self.time = Float(time)
        self.weight = weight
        
        gkGoal = GKGoal(toAvoid: agents, maxPredictionTime: time)
    }
    
    init(toAvoidObstacles names: [String], time: TimeInterval, weight: Float) {
        goalType = .toAvoidObstacles
        
        self.name = NSUUID().uuidString
        self.time = Float(time)
        self.weight = weight
        self.obstacleNames = names
        
        var obstacles = [GKPolygonObstacle]()
        for name in names {
            let obstacle = AFCore.data.obstacles[name]!
            obstacles.append(obstacle.asObstacle()!)
        }
        
        gkGoal = GKGoal(toAvoid: obstacles, maxPredictionTime: time)
    }
    
    init(toCohereWith agentNodes: [SKNode], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toCohereWith
        
        var gkAgents = [GKAgent]()
        for entity in AFCore.data.entities {
            if agentNodes.contains(entity.agent.sprite) {
                gkAgents.append(entity.agent)
            }
        }
        
        self.agents = gkAgents
        self.agentNodes = agentNodes
        self.angle = maxAngle
        self.distance = maxDistance
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toCohereWith: gkAgents, maxDistance: maxDistance, maxAngle: maxAngle)
    }
    
    init(toFleeAgent agentNode: SKNode, weight: Float) {
        goalType = .toFleeAgent
        
        var gkAgents = [GKAgent]()
        for entity in AFCore.data.entities {
            if agentNode == entity.agent.sprite {
                gkAgents.append(entity.agent)
            }
        }

        self.agentNodes = [agentNode]
        self.agents = gkAgents
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toFleeAgent: self.agents[0])
    }

    init(toFollow pathname: String, time t: Float, forward: Bool, weight: Float) {
        goalType = .toFollow
        
        self.forward = forward
        self.name = NSUUID().uuidString
        self.pathname = pathname
        self.time = t
        self.weight = weight
        
        let afPath = AFPath(gameScene: AFCore.sceneUI.gameScene, copyFrom: AFCore.data.paths[pathname]!)
        gkGoal = GKGoal(toFollow: afPath.asPath()!, maxPredictionTime: TimeInterval(t), forward: forward)
    }
    
    init(toInterceptAgent agentNode: SKNode, time: TimeInterval, weight: Float) {
        goalType = .toInterceptAgent
        
        var gkAgents = [GKAgent]()
        for entity in AFCore.data.entities {
            if agentNode == entity.agent.sprite {
                gkAgents.append(entity.agent)
            }
        }
        
        self.agentNodes = [agentNode]
        self.agents = gkAgents
        self.time = Float(time)
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toInterceptAgent: self.agents[0], maxPredictionTime: time)
    }

    init(toReachTargetSpeed speed: Float, weight: Float) {
        goalType = .toReachTargetSpeed
        
        self.name = NSUUID().uuidString
        self.speed = speed
        self.weight = weight
        
        gkGoal = GKGoal(toReachTargetSpeed: speed)
    }
    
    init(toSeekAgent agentNode: SKNode, weight: Float) {
        goalType = .toSeekAgent
        
        var gkAgents = [GKAgent]()
        for entity in AFCore.data.entities {
            if agentNode == entity.agent.sprite {
                gkAgents.append(entity.agent)
            }
        }

        self.agentNodes = [agentNode]
        self.agents = gkAgents
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toSeekAgent: self.agents[0])
    }
    
    init(toSeparateFrom agentNodes: [SKNode], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toSeparateFrom
        
        var gkAgents = [GKAgent]()
        for entity in AFCore.data.entities {
            if agentNodes.contains(entity.agent.sprite) {
                gkAgents.append(entity.agent)
            }
        }
        
        self.agentNodes = agentNodes
        self.agents = gkAgents
        self.angle = maxAngle
        self.distance = maxDistance
        self.name = NSUUID().uuidString
        self.weight = weight
        
        gkGoal = GKGoal(toSeparateFrom: gkAgents, maxDistance: maxDistance, maxAngle: maxAngle)
    }
    
    init(toStayOn pathname: String, time t: Float, weight: Float) {
        goalType = .toStayOn
        
        self.name = NSUUID().uuidString
        self.pathname = pathname
        self.time = t
        self.weight = weight
        
        let afPath = AFPath(gameScene: AFCore.sceneUI.gameScene, copyFrom: AFCore.data.paths[pathname]!)
        gkGoal = GKGoal(toStayOn: afPath.gkPath, maxPredictionTime: TimeInterval(t))
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
    
    func toString() -> String {
        let m: [AFGoalType: String] = [
            .toAlignWith: "Align", .toAvoidAgents: "Avoid agents", .toAvoidObstacles: "Avoid obstacles",
            .toCohereWith: "Cohere", .toFleeAgent: "Flee", .toFollow: "Follow path",
            .toInterceptAgent: "Intercept", .toReachTargetSpeed: "Speed", .toSeekAgent: "Seek",
            .toSeparateFrom: "Separate from", .toStayOn: "Stay on path", .toWander: "Wander"
        ]
        
        return String(format: m[goalType]!, weight)
    }
}

// MARK: Goal factory

extension AFGoal {
    static func makeGoal(copyFrom: AFGoal, weight: Float) -> AFGoal {
        switch copyFrom.goalType {
        case .toSeekAgent:        fallthrough
        case .toFleeAgent:        return makeGoal(copyFrom.goalType, agentNode: copyFrom.agentNodes[0], weight: weight)

        case .toReachTargetSpeed: fallthrough
        case .toWander:           return makeGoal(copyFrom.goalType, speed: copyFrom.speed, weight: weight)

        case .toAvoidAgents:      return makeGoal(copyFrom.goalType, agentNodes: copyFrom.agentNodes, time: copyFrom.time, weight: weight)
        case .toAvoidObstacles:   return makeGoal(copyFrom.goalType, obstacleNames: copyFrom.obstacleNames, time: copyFrom.time, weight: weight)
        case .toInterceptAgent:   return makeGoal(copyFrom.goalType, agentNodes: copyFrom.agentNodes, time: copyFrom.time, weight: weight)

        case .toAlignWith:        fallthrough
        case .toCohereWith:       fallthrough
        case .toSeparateFrom:
            return makeGoal(copyFrom.goalType, agentNodes: copyFrom.agentNodes, distance: copyFrom.distance, angle: copyFrom.angle, weight: weight)

        case .toFollow:           fallthrough
        case .toStayOn:           return makeGoal(copyFrom.goalType, pathname: copyFrom.pathname!, time: copyFrom.time, forward: copyFrom.forward, weight: weight)
        }
    }
    
    static func makeGoal(_ type: AFGoalType, pathname: String, time: Float, forward: Bool, weight: Float) -> AFGoal {
        switch type {
        case .toFollow: return AFGoal(toFollow: pathname, time: time, forward: forward, weight: weight)
        case .toStayOn: return AFGoal(toStayOn: pathname, time: time, weight: weight)
            
        default: fatalError()
        }
    }
    
    static func makeGoal(_ type: AFGoalType, agentNodes: [SKNode], distance: Float, angle: Float, weight: Float) -> AFGoal {
        switch type {
        case .toAlignWith:    return AFGoal(toAlignWith: agentNodes, maxDistance: distance, maxAngle: angle, weight: weight)
        case .toCohereWith:   return AFGoal(toCohereWith: agentNodes, maxDistance: distance, maxAngle: angle, weight: weight)
        case .toSeparateFrom: return AFGoal(toSeparateFrom: agentNodes, maxDistance: distance, maxAngle: angle, weight: weight)
            
        default: fatalError()
        }
    }
    
    static func makeGoal(_ type: AFGoalType, obstacleNames: [String], time: Float, weight: Float) -> AFGoal {
        switch type {
        case .toAvoidObstacles: return AFGoal(toAvoidObstacles: obstacleNames, time: TimeInterval(time), weight: weight)
            
        default: fatalError()
        }
    }

    static func makeGoal(_ type: AFGoalType, agentNodes: [SKNode], time: Float, weight: Float) -> AFGoal {
        switch type {
        case .toAvoidAgents: return AFGoal(toAvoidAgents: agentNodes, time: TimeInterval(time), weight: weight)
            
        default: fatalError()
        }
    }
    
    static func makeGoal(_ type: AFGoalType, agentNode: SKNode, weight: Float) -> AFGoal {
        switch type {
        case .toFleeAgent: return AFGoal(toFleeAgent: agentNode, weight: weight)
        case .toSeekAgent: return AFGoal(toSeekAgent: agentNode, weight: weight)
            
        default: fatalError()
        }
    }

    static func makeGoal(_ type: AFGoalType, speed: Float, weight: Float) -> AFGoal {
        switch type {
        case .toReachTargetSpeed: return AFGoal(toReachTargetSpeed: speed, weight: weight)
        case .toWander:           return AFGoal(toWander: speed, weight: weight)
            
        default: fatalError()
        }
    }
}

