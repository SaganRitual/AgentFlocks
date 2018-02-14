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
        
        // These notifications come from the data
        let s1 = #selector(coreNodeAdd(notification:))
        self.dataNotifications.addObserver(self, selector: s1, name: .CoreNodeAdd, object: nil)

        let s2 = #selector(coreNodeDelete(notification:))
        self.dataNotifications.addObserver(self, selector: s2, name: .CoreNodeDelete, object: nil)

        let s3 = #selector(coreNodeUpdate(notification:))
        self.dataNotifications.addObserver(self, selector: s3, name: .CoreNodeUpdate, object: nil)

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
    
    func handoffToGameplayKit(avatar: AFAgentAvatar) {
        // I'm the Agent. The node component becomes my delegate here. It keeps
        // the sprite in sync with my movements, which are driven by the goals.
        let nc = avatar.makeNodeComponent()
        self.delegate = nc
        
        // Compose ourselves, and subscribe to the tick, after which, the entity will
        // own the memory reference to the agent, and via the node component, the
        // sprite as well. I think.
        let entity = GKEntity()
        entity.addComponent(self)
        entity.addComponent(nc)
        
        core.ui.gameScene.entities.append(entity)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: track updates to the tree

private extension AFAgent {
    func addGoal(notification: Foundation.Notification) {
        let n = AFData.Notifier(notification)
        let last = JSON(n.pathToNode.last!).stringValue
        
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
        } else {
            fatalError()
        }
        
        chargeMotivators()
    }
    
    func iCareAboutThisNotification(notification: Foundation.Notification) -> Bool {
        // I'm not mentioned at all. The nerve.
        let n = AFData.Notifier(notification)
        guard n.pathToNode.contains(where: { JSON($0) == JSON(self.name) }) else { return false }
        
        // Don't care about anything but the motivators themselves.
        guard AFData.isBehavior(n.pathToNode) || AFData.isGoal(n.pathToNode) else { return false }
        
        return true
    }
    
    @objc func coreNodeAdd(notification: Foundation.Notification) {
        guard iCareAboutThisNotification(notification: notification) else { return }
        addGoal(notification: notification)
    }

    @objc func coreNodeDelete(notification: Foundation.Notification) {
        guard iCareAboutThisNotification(notification: notification) else { return }
        
        let n = AFData.Notifier(notification)
        let last = JSON(n.pathToNode.last!).stringValue

        if AFData.isBehavior(n.pathToNode) {
            self.composite.remove(knownMotivators[last] as! GKBehavior)
        } else if AFData.isGoal(n.pathToNode) {
            let pathToBehavior = AFData.getPathToParent(n.pathToNode)
            let behaviorName = JSON(pathToBehavior.last!).stringValue
            let theGkBehaviorToFind = knownMotivators[behaviorName]!
            let theGkGoalToFind = knownMotivators[last]!
            
            var done = false
            for i in 0 ..< self.composite.behaviorCount {
                let checkBehavior = self.composite[i]
                if checkBehavior == theGkBehaviorToFind as! GKBehavior {
                    for j in 0 ..< checkBehavior.goalCount {
                        let checkGoal = checkBehavior[j]
                        if checkGoal == theGkGoalToFind as! GKGoal {
                            checkBehavior.remove(checkGoal)
                            done = true
                            break
                        }
                    }
                }
                
                if done { break }
            }
        } else {
            fatalError()
        }
        
        chargeMotivators()
    }
    
    @objc func coreNodeUpdate(notification: Foundation.Notification) {
        guard iCareAboutThisNotification(notification: notification) else { return }
        
        let n = AFData.Notifier(notification)
        let last = JSON(n.pathToNode.last!).stringValue
        
        // The gk machinery allows us to set the weight for a motivator independently
        // of its other attributes, and it gives us direct access to the weight. So
        // if the user is only changing the weight, we can just change it here, as
        // opposed to recharging the motivators, as we must do for updates on other
        // goal attributes.
        if last == "weight" {
            if AFData.isBehavior(n.pathToNode) {
                let editor = AFBehaviorEditor(n.pathToNode, core: core)
                let gkBehavior = knownMotivators[editor.name]!
                self.composite.setWeight(editor.weight, for: gkBehavior as! GKBehavior)
            } else if AFData.isGoal(n.pathToNode) {
                let pathToBehavior = AFData.getPathToParent(n.pathToNode)
                let behaviorName = JSON(pathToBehavior.last!).stringValue

                let gkBehavior = knownMotivators[behaviorName]! as! GKBehavior
                let gkGoal = knownMotivators[last]! as! GKGoal
                
                let editor = AFGoalEditor(n.pathToNode, core: core)
                gkBehavior.setWeight(editor.weight, for: gkGoal)
            } else {
                fatalError()
            }
        } else {
            // Updating something other than weight. This happens only for goals, as
            // behaviors don't have any other attributes. We have to discard the existing
            // goal and create a new one.
            guard AFData.isGoal(n.pathToNode) else { fatalError() }
            
            let pathToGoal = Array(n.pathToNode.prefix(n.pathToNode.count - 1))
            let goalName = JSON(pathToGoal.last!).stringValue
            
            let pathToBehavior = AFData.getPathToParent(n.pathToNode)
            let behaviorName = JSON(pathToBehavior.last!).stringValue
            
            let gkBehavior = knownMotivators[behaviorName]! as! GKBehavior
            let gkGoal = knownMotivators[goalName]! as! GKGoal
            
            // Discard the existing goal
            gkBehavior.remove(gkGoal)
            knownMotivators.removeValue(forKey: last)
            
            addGoal(notification: notification)
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
