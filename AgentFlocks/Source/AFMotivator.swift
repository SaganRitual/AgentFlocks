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
    var enabled = true
    var goals: [AFGoal]
    let motivatorType: AFMotivatorType
    var weight: Float
    
    var angle: Float = 0
    var distance: Float = 0
    var predictionTime: Float = 0
    var speed: Float = 0
    
    init() {
        goals = [AFGoal]()
        motivatorType = .behavior
        weight = 0
    }
    
    init(goal: AFGoal) {
        goals = [goal]
        motivatorType = .behavior
        weight = 1
    }
    
    func addGoal(_ goal: AFGoal) {
        goals.append(goal)
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
    var enabled = true
    var behaviors: [AFBehavior]
    let motivatorType: AFMotivatorType
    
    var angle: Float = 0
    var distance: Float = 0
    var predictionTime: Float = 0
    var speed: Float = 0
    var weight: Float = 0
    
    init() {
        behaviors = [AFBehavior]()
        motivatorType = .compositeBehavior
    }
    
    func addBehavior(_ behavior: AFBehavior) {
        behaviors.append(behavior)
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
    case toAvoidObstacles, toReachTargetSpeed, toWander
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


