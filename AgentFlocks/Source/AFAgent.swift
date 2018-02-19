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
        self.dataNotifications.addObserver(self, selector: s1, name: Foundation.Notification.Name.CoreNodeAdd, object: nil)

        let s2 = #selector(coreNodeDelete(notification:))
        self.dataNotifications.addObserver(self, selector: s2, name: Foundation.Notification.Name.CoreNodeDelete, object: nil)

        let s3 = #selector(coreNodeUpdate(notification:))
        self.dataNotifications.addObserver(self, selector: s3, name: Foundation.Notification.Name.CoreNodeUpdate, object: nil)

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
    func addMotivator(notification: Foundation.Notification) {
        let packet = AFNotificationPacket.unpack(notification)
        
        var path = [JSONSubscriptType]()
        if case let AFNotificationPacket.CoreNodeAdd(path_) = packet { path = path_ }
        else if case let AFNotificationPacket.CoreNodeUpdate(path_) = packet { path = path_ }
        
        let last = JSON(path.last!).stringValue
        
        // An empty behavior, ready for goals
        if AFData.isBehavior(path) {
            
            let weight = AFBehaviorEditor(path, core: core).weight
            let behavior = GKBehavior()
            
            knownMotivators[last] = behavior
            composite.setWeight(weight, for: behavior)
            
        } else if AFData.isGoal(path) {
            
            let behaviorName = JSON(AFData.getBehavior(path)).stringValue
            let gkBehavior = knownMotivators[behaviorName] as! GKBehavior
            let goalEditor = AFGoalEditor(path, core: core)
            let weight = goalEditor.weight
            let gkGoal = composeGkGoal(goalEditor)
            
            knownMotivators[last] = gkGoal
            gkBehavior.setWeight(weight, for: gkGoal)
        } else {
            fatalError()
        }
    }
    
    func iCareAboutThisNotification(notification: Foundation.Notification) -> Bool {
        let packet = AFNotificationPacket.unpack(notification)
        
        var path = [JSONSubscriptType]()
        if case let .CoreNodeAdd(path_) = packet { path = path_ }
        else if case let .CoreNodeDelete(path_) = packet { path = path_ }
        else if case let .CoreNodeUpdate(path_) = packet { path = path_ }
        
        // I'm not mentioned at all. The nerve.
        guard path.contains(where: { JSON($0) == JSON(self.name) }) else { return false }
        
        // Don't care about anything but the motivators themselves.
        guard AFData.isBehavior(path) || AFData.isGoal(path) else { return false }
        
        return true
    }
    
    @objc func coreNodeAdd(notification: Foundation.Notification) {
        guard iCareAboutThisNotification(notification: notification) else { return }
        addMotivator(notification: notification)
    }

    @objc func coreNodeDelete(notification: Foundation.Notification) {
        let packet = AFNotificationPacket.unpack(notification)

        guard case let .CoreNodeAdd(path) = packet else { fatalError() }
        guard iCareAboutThisNotification(notification: notification) else { return }

        let last = JSON(path).stringValue

        if AFData.isBehavior(path) {
            self.composite.remove(knownMotivators[last] as! GKBehavior)
        } else if AFData.isGoal(path) {
            let pathToBehavior = AFData.getPathToParent(path)
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
        
        chargeMotivators()  // Overkill --- come back to this when we start implementing delete
    }
    
    @objc func coreNodeUpdate(notification: Foundation.Notification) {
        let packet = AFNotificationPacket.unpack(notification)

        guard case let .CoreNodeUpdate(path) = packet else { fatalError() }
        guard iCareAboutThisNotification(notification: notification) else { return }

        // The gk machinery allows us to set the weight for a motivator independently
        // of its other attributes, and it gives us direct access to the weight. So
        // if the user is only changing the weight, we can just change it here, as
        // opposed to recharging the motivators, as we must do for updates on other
        // goal attributes.
        let last = JSON(path.last!).stringValue
        if last == "weight" {
            if AFData.isBehavior(path) {
                let editor = AFBehaviorEditor(path, core: core)
                let gkBehavior = knownMotivators[editor.name]!
                self.composite.setWeight(editor.weight, for: gkBehavior as! GKBehavior)
            } else if AFData.isGoal(path) {
                let pathToBehavior = AFData.getPathToParent(path)
                let behaviorName = JSON(pathToBehavior.last!).stringValue

                let gkBehavior = knownMotivators[behaviorName]! as! GKBehavior
                let gkGoal = knownMotivators[last]! as! GKGoal
                
                let editor = AFGoalEditor(path, core: core)
                gkBehavior.setWeight(editor.weight, for: gkGoal)
            } else {
                fatalError()
            }
        } else {
            // Updating something other than weight. This happens only for goals, as
            // behaviors don't have any other attributes. We have to discard the existing
            // gkGoal and create a new one. But we use the original name on the new
            // gkGoal--we're supposed to be updating here, not discarding and replacing.
            // We do that only because the gk architecture forces it on us.
            guard AFData.isGoal(path) else { fatalError() }
            
            addMotivator(notification: notification)
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
            
        case .toFleeAgent:        return GKGoal(toFleeAgent: core.sceneController.getAgent(editor.agent))
        case .toSeekAgent:        return GKGoal(toSeekAgent: core.sceneController.getAgent(editor.agent))
            
        case .toAlignWith:        return GKGoal(toAlignWith: core.sceneController.getAgents(editor.agents), maxDistance: editor.distance, maxAngle: editor.angle)
        case .toCohereWith:       return GKGoal(toCohereWith: core.sceneController.getAgents(editor.agents), maxDistance: editor.distance, maxAngle: editor.angle)
        case .toSeparateFrom:     return GKGoal(toSeparateFrom: core.sceneController.getAgents(editor.agents), maxDistance: editor.distance, maxAngle: editor.angle)

        case .toAvoidAgents:      return GKGoal(toAvoid: core.sceneController.getAgents(editor.agents), maxPredictionTime: editor.time)
        case .toAvoidObstacles:   fatalError()
        case .toInterceptAgent:   return GKGoal(toInterceptAgent: core.sceneController.getAgent(editor.name), maxPredictionTime: editor.time)
        }
    }
}
