//
// Created by Rob Bishop on 2/12/18
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

protocol AFMotivator { }
extension GKBehavior: AFMotivator {}
extension GKGoal: AFMotivator {}

class AFAgent: GKAgent2D {
    private unowned let core: AFCore
    private unowned let dataNotifications: Foundation.NotificationCenter
    private var knownMotivators = [String: AFMotivator]()
    let name: String
    
    private var composite: GKCompositeBehavior {
        if self.behavior == nil { self.behavior = GKCompositeBehavior() }
        return self.behavior as! GKCompositeBehavior
    }
    
    init(_ name: String, core: AFCore, position: CGPoint) {
        self.core = core
        self.dataNotifications = core.bigData.notifier
        self.name = name
        
        super.init()
        
        // Hook up to the entity/component mechanism, which provides us our tick.
        core.ui.gameScene.agents.addComponent(self)
        
        // Dummy sprite
        let sprite = SKShapeNode(circleOfRadius: 25)
        sprite.name = NSUUID().uuidString
        core.ui.gameScene.addChild(sprite)
        
        // I'm the Agent. The node component becomes my delegate here. It keeps
        // the sprite in sync with my movements, which are driven by the goals.
        let nc = GKSKNodeComponent(node: sprite)
        self.delegate = nc

        // Compose ourselves, and subscribe to the tick
        let entity = GKEntity()
        entity.addComponent(self)
        entity.addComponent(nc)

        core.ui.gameScene.entities.append(entity)
        
        // These notifications come from the data
        let s1 = #selector(coreDataChanged(notification:))
        self.dataNotifications.addObserver(self, selector: s1, name: .CoreTreeUpdate, object: nil)
        
        chargeMotivators()
    }
    
    func chargeMotivators() {
        
        mass = 0.1
        maxAcceleration = 200
        maxSpeed = 200
        radius = 1

        let pathToAgent = core.getPathTo(self.name)!
        let agentEditor = AFAgentEditor(pathToAgent, core: core)
        let compositeEditor = agentEditor.getComposite()

        for i in 0 ..< compositeEditor.behaviorsCount {

            let behaviorEditor = compositeEditor.getBehaviorEditor(i)
            let gkBehavior = GKBehavior()

            knownMotivators[behaviorEditor.name] = gkBehavior
            self.composite.setWeight(behaviorEditor.weight, for: gkBehavior)
            
            for j in 0 ..< behaviorEditor.goalsCount {
                let goalEditor = behaviorEditor.getGoalEditor(j)
                let gkGoal = composeGkGoal(goalEditor)

                knownMotivators[goalEditor.name] = gkGoal
                gkBehavior.setWeight(goalEditor.weight, for: gkGoal)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: track updates to the tree

private extension AFAgent {
    @objc func coreDataChanged(notification: Foundation.Notification) {
        // I'm not mentioned at all. The nerve.
        let n = AFData.Notifier(notification)
        guard n.pathToNode.contains(where: { JSON($0) == JSON(self.name) }) else { return }
        
        // Don't care about anything but the motivators themselves.
        guard AFData.isBehavior(n.pathToNode) || AFData.isGoal(n.pathToNode) else { return }
        
        let last = JSON(n.pathToNode.last!).stringValue
        if knownMotivators[last] != nil {
            // We know this one; this is an update
        } else {
            // This is a new motivator

            // An empty behavior, ready for goals
            if AFData.isBehavior(n.pathToNode) {
                
                let weight = AFCompositeEditor(n.pathToNode, core: core).getWeight(forMotivator: last)
                let behavior = GKBehavior()
                
                knownMotivators[last] = behavior
                composite.setWeight(weight, for: behavior)
                
            } else if AFData.isGoal(n.pathToNode) {
                
                let behaviorName = JSON(AFData.getBehavior(n.pathToNode)).stringValue
                let gkBehavior = knownMotivators[behaviorName] as! GKBehavior
                let behaviorEditor = AFBehaviorEditor(n.pathToNode, core: core)
                let weight = behaviorEditor.getWeight(forMotivator: last)
                let goalEditor = AFGoalEditor(n.pathToNode, core: core)
                let gkGoal = composeGkGoal(goalEditor)
                
                knownMotivators[last] = gkGoal
                gkBehavior.setWeight(weight, for: gkGoal)

            }
        }
    }
}

// MARK: Create GKGoals

private extension AFAgent {
    func composeGkGoal(_ editor: AFGoalEditor) -> GKGoal {
        switch editor.type! {
        case .toReachTargetSpeed: return GKGoal(toReachTargetSpeed: editor.speed)
        case .toWander:           return GKGoal(toWander: editor.speed)

        case .toFollow:           fatalError()
        case .toStayOn:           fatalError()
            
        case .toFleeAgent:        return GKGoal(toFleeAgent: core.sceneController.getAgent(editor.name))
        case .toSeekAgent:        return GKGoal(toSeekAgent: core.sceneController.getAgent(editor.name))
            
        case .toAlignWith:        return GKGoal(toAlignWith: core.sceneController.getAgents(editor.agents), maxDistance: editor.distance, maxAngle: editor.angle)
        case .toCohereWith:       return GKGoal(toCohereWith: core.sceneController.getAgents(editor.agents), maxDistance: editor.distance, maxAngle: editor.angle)
        case .toSeparateFrom:     return GKGoal(toSeparateFrom: core.sceneController.getAgents(editor.agents), maxDistance: editor.distance, maxAngle: editor.angle)

        case .toAvoidAgents:      return GKGoal(toAvoid: core.sceneController.getAgents(editor.agents), maxPredictionTime: editor.time)
        case .toAvoidObstacles:   fatalError()
        case .toInterceptAgent:   return GKGoal(toInterceptAgent: core.sceneController.getAgent(editor.name), maxPredictionTime: editor.time)
        }
    }
}
