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
        return "GKBehavior"
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
        if weight == 0 { weight = 100 } // Until I can retrieve the weight from the UI
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
        return "GKCompositeBehavior"
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
    
    init(toAvoidObstacles obstacles: [GKObstacle], maxPredictionTime: TimeInterval, weight: Float) {
        goalType = .toAvoidObstacles
        motivatorType = .goal
        
        self.obstacles = obstacles
        self.weight = weight
        
        goal = GKGoal(toAvoid: obstacles, maxPredictionTime: maxPredictionTime)
    }
    
    init(toReachTargetSpeed speed: Float, weight: Float) {
        goalType = .toReachTargetSpeed
        motivatorType = .goal
        
        self.speed = speed
        self.weight = weight
        
        newGoal(newValue: speed)
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
        return "GKGoal: \(goalType)"
    }
}


