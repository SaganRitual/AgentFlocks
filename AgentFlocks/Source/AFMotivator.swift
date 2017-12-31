//
//  AFMotivator.swift
//  AgentFlocks
//
//  Created by Rob Bishop on 12/18/17.
//  Copyright © 2017 TriKatz. All rights reserved.
//


import GameplayKit

enum AFMotivatorType {
    case behavior, compositeBehavior, goal
}

protocol AFMotivator {
    var motivatorType: AFMotivatorType { get }
    var angle: Float { get set }
    var distance: Float { get set }
    var predictionTime: Float { get set }
    var speed: Float { get set }
    var weight: Float { get set }
    
    func toString() -> String
}

protocol AFMotivatorCollection: AFMotivator {
    func getChild(at: Int) -> AFMotivator
    func hasChildren() -> Bool
    func howManyChildren() -> Int
}

class AFBehavior: AFMotivatorCollection {
    let agent: AFAgent2D
    var enabled = true
    var goals: [AFGoal]
    let motivatorType: AFMotivatorType
    var weight: Float
    
    var angle: Float = 0
    var distance: Float = 0
    var predictionTime: Float = 0
    var speed: Float = 0
    
    init(agent: AFAgent2D) {
        self.agent = agent
        goals = [AFGoal]()
        motivatorType = .behavior
        weight = 100
    }
    
    init(agent: AFAgent2D, goal: AFGoal) {
        self.agent = agent
        goals = [AFGoal]()
        goals.append(goal)
        motivatorType = .behavior
        weight = goal.weight
    }
    
    func addGoal(_ goal: AFGoal) {
        goals.append(goal)
        weight = goal.weight
        agent.applyMotivator()
    }
    
    func getChild(at: Int) -> AFMotivator {
        return goals[at]
    }
    
    func hasChildren() -> Bool {
        return goals.count > 0
    }
    
    func howManyChildren() -> Int {
        return goals.count
    }
    
    func toString() -> String {
        return String(format: "Behavior: %.0f", weight)
    }
}

class AFCompositeBehavior: AFMotivatorCollection {
    let agent: AFAgent2D
    var enabled = true
    var behaviors: [AFBehavior]
    let motivatorType: AFMotivatorType
    
    var angle: Float = 0
    var distance: Float = 0
    var predictionTime: Float = 0
    var speed: Float = 0
    var weight: Float = 0
    
    init(agent: AFAgent2D) {
        self.agent = agent
        behaviors = [AFBehavior]()
        motivatorType = .compositeBehavior
    }
    
    func addBehavior(_ behavior: AFBehavior) {
        behaviors.append(behavior)
        weight = behavior.weight
        agent.applyMotivator()
    }
    
    func getChild(at: Int) -> AFMotivator {
        return behaviors[at]
    }
    
    func hasChildren() -> Bool {
        return behaviors.count > 0
    }
    
    func howManyChildren() -> Int {
        return behaviors.count
    }
    
    func toString() -> String {
        return "You've found a bug"
    }
}

enum AFGoalType {
    case toAlignWith, toAvoidAgents, toAvoidObstacles, toCohereWith, toFleeAgent, toFollow,
            toInterceptAgent, toReachTargetSpeed, toSeekAgent, toSeparateFrom, toStayOn, toWander
}

class AFGoal: AFMotivator {
    var enabled = true
    var goal: GKGoal!
    let goalType: AFGoalType
    let motivatorType: AFMotivatorType
    var weight: Float
    
    var angle: Float = 0
    var distance: Float = 0
    var predictionTime: Float = 0
    var speed: Float = 0 {
        willSet(newValue) {
            newGoal(newValue: newValue)
        }
    }
    
    var obstacles = [GKObstacle]()
    
    init(toAlignWith agents: [GKAgent], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toAlignWith
        motivatorType = .goal
        
        self.angle = maxAngle
        self.distance = maxDistance
        self.weight = weight

        goal = GKGoal(toAlignWith: agents, maxDistance: maxDistance, maxAngle: maxAngle)
    }

    init(toAvoidAgents agents: [GKAgent], maxPredictionTime: TimeInterval, weight: Float) {
        goalType = .toAvoidAgents
        motivatorType = .goal
        
        self.predictionTime = Float(maxPredictionTime)
        self.weight = weight
        
        goal = GKGoal(toAvoid: agents, maxPredictionTime: maxPredictionTime)
    }

    init(toAvoidObstacles obstacles: [GKObstacle], maxPredictionTime: TimeInterval, weight: Float) {
        goalType = .toAvoidObstacles
        motivatorType = .goal
        
        self.obstacles = obstacles
        self.predictionTime = Float(maxPredictionTime)
        self.weight = weight
        
        goal = GKGoal(toAvoid: obstacles, maxPredictionTime: maxPredictionTime)
    }
    
    init(toCohereWith agents: [GKAgent], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toCohereWith
        motivatorType = .goal
        
        self.angle = maxAngle
        self.distance = maxDistance
        self.weight = weight
        
        goal = GKGoal(toCohereWith: agents, maxDistance: maxDistance, maxAngle: maxAngle)
    }

    init(toInterceptAgent agent: GKAgent, maxPredictionTime: TimeInterval, weight: Float) {
        goalType = .toInterceptAgent
        motivatorType = .goal
        
        self.predictionTime = Float(maxPredictionTime)
        self.weight = weight
        
        goal = GKGoal(toInterceptAgent: agent, maxPredictionTime: maxPredictionTime)
    }

    init(toFleeAgent agent: GKAgent, weight: Float) {
        goalType = .toFleeAgent
        motivatorType = .goal
        
        self.weight = weight
        
        goal = GKGoal(toFleeAgent: agent)
    }

    init(toFollow path: GKPath, maxPredictionTime t: Float, forward: Bool, weight: Float) {
        goalType = .toFollow
        motivatorType = .goal
        
        self.predictionTime = t
        self.weight = weight
        
        goal = GKGoal(toFollow: path, maxPredictionTime: TimeInterval(t), forward: true)
    }

    init(toReachTargetSpeed speed: Float, weight: Float) {
        goalType = .toReachTargetSpeed
        motivatorType = .goal
        
        self.speed = speed
        self.weight = weight
        
        newGoal(newValue: speed)
    }
    
    init(toSeekAgent agent: GKAgent, weight: Float) {
        goalType = .toSeekAgent
        motivatorType = .goal
        
        self.weight = weight
        
        goal = GKGoal(toSeekAgent: agent)
    }
    
    init(toSeparateFrom agents: [GKAgent], maxDistance: Float, maxAngle: Float, weight: Float) {
        goalType = .toSeparateFrom
        motivatorType = .goal
        
        self.angle = maxAngle
        self.distance = maxDistance
        self.weight = weight
        
        goal = GKGoal(toSeparateFrom: agents, maxDistance: maxDistance, maxAngle: maxAngle)
    }

    init(toStayOn path: GKPath, maxPredictionTime t: Float, weight: Float) {
        goalType = .toStayOn
        motivatorType = .goal
        
        self.predictionTime = t
        self.weight = weight

        goal = GKGoal(toStayOn: path, maxPredictionTime: TimeInterval(t))
    }
    
    init(toWander speed: Float, weight: Float) {
        goalType = .toWander
        motivatorType = .goal
        self.speed = speed
        self.weight = weight
        
        newGoal(newValue: speed)
    }
    
    init(goal: GKGoal, type: AFGoalType, weight: Float) {
        self.goal = goal
        self.goalType = type
        self.motivatorType = .goal
        self.weight = weight
    }
    
    func newGoal(newValue: Float) {
        switch goalType {
        case .toReachTargetSpeed: goal = GKGoal(toReachTargetSpeed: newValue)
        case .toWander:           goal = GKGoal(toWander: newValue)
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

