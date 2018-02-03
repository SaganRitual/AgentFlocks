//
// Created by Rob Bishop on 1/15/18
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

class AFAgentGoalsDelegate {
    private unowned let afSceneController: AFSceneController
    private unowned let coreData: AFCoreData
    private var gameScene: GameScene!
    
    var agent: String?
    
    init(_ injector: AFCoreData.AFDependencyInjector) {
        self.coreData = injector.coreData!
        self.afSceneController = injector.afSceneController!
    }
    
    func deleteItem(_ item: String) { self.deleteItem(item) }
    
    func deselect() { self.agent = nil }
    
    func getEditableAttributes(for motivator: Any) -> AFOrderedMap<String, Double> {
        guard let n = afSceneController.primarySelection else { fatalError() }

        let agent = AFNodeAdapter(gameScene: afSceneController.gameScene, name: n).getAgent()!
        let gkGoal: GKGoal? = motivator as? GKGoal
        let composite = agent.behavior as! AFCompositeBehavior
        let behavior = (gkGoal == nil) ? (motivator as! AFBehavior) : composite.findParent(ofGoal: gkGoal!)
        let afGoal_: AFGoal? = behavior!.getAFGoalForGKGoal(gkGoal)
        
        var attributes_ = AFOrderedMap<String, Double>()
        var attributes = AFOrderedMap<String, Double>()

        if let afGoal = afGoal_ {
            attributes_.append(key: "Angle", value: Double(afGoal.angle ?? 0))
            attributes_.append(key: "Distance", value: Double(afGoal.distance ?? 0))
            attributes_.append(key: "Speed", value: Double(afGoal.speed ?? 0))
            attributes_.append(key: "Time", value: Double(afGoal.time ?? 0))
            attributes_.append(key: "Weight", value: Double(afGoal.weight ?? 0))

            switch afGoal.goalType {
            default: break
//            case .toAlignWith:        fallthrough
//            case .toCohereWith:       fallthrough
//            case .toSeparateFrom:
//                attributes.append(key: "Angle", value: attributes_["Angle"]!)
//                attributes.append(key: "Distance", value: attributes_["Distance"]!)
//
//            case .toFleeAgent:        fallthrough
//            case .toSeekAgent:        fallthrough
//            case .toReachTargetSpeed: fallthrough
//            case .toWander:
//                attributes.append(key: "Speed", value: attributes_["Speed"]!)
//
//            case .toFollow:           fallthrough
//            case .toStayOn:           fallthrough
//            case .toAvoidAgents:      fallthrough
//            case .toAvoidObstacles:   fallthrough
//            case .toInterceptAgent:
//                attributes.append(key: "Time", value: attributes_["Time"]!)
            }
        } else {
//            attributes_.append(key: "Weight", value: behavior.weight)
        }
        
        attributes.append(key: "Weight", value: attributes_["Weight"]!)
        return attributes
    }
    
    func inject(_ injector: AFCoreData.AFDependencyInjector) {
        var iStillNeedSomething = false
        
        if let gs = injector.gameScene { self.gameScene = gs }
        else { iStillNeedSomething = true; injector.someoneStillNeedsSomething = true }
        
        if !iStillNeedSomething {
            injector.agentGoalsDelegate = self
        }
    }
    
    func itemClicked(_ item: Any) {
        if let motivator = item as? AFBehavior {
            afSceneController.parentOfNewMotivator = motivator
        } else if let motivator = item as? GKGoal {
            guard let n = afSceneController.primarySelection else { fatalError() }
            
            let agent = AFNodeAdapter(gameScene: self.gameScene, name: n).getAgent()!
            let composite = agent.behavior as! AFCompositeBehavior

            afSceneController.parentOfNewMotivator = composite.findParent(ofGoal: motivator)
        }
    }
    
    func enableItem(_ item: Any, parent: Any?, on: Bool) -> [Any]? {
        if let behavior = item as? AFBehavior {
            guard let n = afSceneController.primarySelection else { fatalError() }

            let agent = AFNodeAdapter(gameScene: afSceneController.gameScene, name: n).getAgent()!
            let composite = agent.behavior as! AFCompositeBehavior
            
            composite.enableBehavior(behavior, on: on)
            
            var itemsUpdated = [Any]()
//            for gkGoal in behavior.goalsMap.keys {
//                itemsUpdated.append(gkGoal)
//            }
            
            return itemsUpdated
        }
//        else if let gkGoal = item as? GKGoal {
//            let behavior = parent! as! AFBehavior
//            let afGoal = behavior.goalsMap[gkGoal]!
//
//            behavior.enableGoal(afGoal, on: on)
//        }

        return nil
    }
    
    func play(_ yesno: Bool) {
//        guard let agent = AFSceneController.AFNodeAdapter(sceneController.primarySelection).getOwningAgent() else { return }
//        agent.isPlaying = yesno
    }
    
    func select(_ agent: String) { self.agent = agent }
}
