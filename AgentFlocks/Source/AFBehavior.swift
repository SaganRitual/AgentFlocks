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

class AFBehavior: GKBehavior {
    private unowned let core: AFCore
    private var enabled = true
    private let familyName: String
    private var goalsMap = [GKGoal: AFGoal]()
    let name: String
    private unowned let notifications: Foundation.NotificationCenter
    private var savedState: (weight: Float, goal: AFGoal)?
    private unowned let gameScene: SKScene
    
    init(core: AFCore, editor: AFBehaviorEditor, gameScene: SKScene) {
        self.core = core
        self.familyName = "Corlione"
        self.name = NSUUID().uuidString
        self.gameScene = gameScene
        self.notifications = core.bigData.notifier
        
        super.init()
        
        let n = Foundation.Notification.Name.CoreTreeUpdate
        self.notifications.addObserver(self, selector: #selector(aGoalHasBeenCreated(notification:)), name: n, object: nil)
    }
    
    @objc func aGoalHasBeenCreated(notification: Foundation.Notification) {
    }
    
    func getAFGoalForGKGoal(_ gkGoal: GKGoal?) -> AFGoal? {
        if let gg = gkGoal { return goalsMap[gg] }
        else { return nil }
    }
    
    func setWeight(_ weight: Float, for goal: AFGoalEditor) {
//        super.setWeight(weight, for: goal.gkGoal)
    }
}

/*

class AFBehavior: GKBehavior {
    let agent: AFAgent2D
    var enabled = true
    var goalsMap = [GKGoal: AFGoal]()
    var secondaryMap = [GKGoal: GKGoal]()
    var savedState: (weight: Float, goal: AFGoal)?
    var weight: Float

    init(prototype: AFBehavior_Script, agent: AFAgent2D) {
        self.agent = agent
        enabled = prototype.enabled
        weight = prototype.weight
        
        super.init()
        
        for gkGoal in prototype.goals {
            let goal = AFGoal(prototype: gkGoal)
            setWeightage(goal.weight, for: goal)
            goalsMap[goal.gkGoal!] = goal
        }
    }
    
    init(agent: AFAgent2D, copyFrom: AFBehavior) {
        self.agent = agent
        self.weight = copyFrom.weight
        
        super.init()
        
        for i in 0 ..< copyFrom.goalCount {
            let hisAFGoal = copyFrom.getChild(at: i)
            let myAFGoal = AFGoal.makeGoal(copyFrom: hisAFGoal, weight: hisAFGoal.weight)
            
            self.setWeightage(myAFGoal.weight, for: myAFGoal)
        }
    }
    
    init(agent: AFAgent2D) {
        self.agent = agent
        weight = 1
    }
    
    func addGoal(_ goal: AFGoal) {
        setWeightage(goal.weight, for: goal)
    }
    
    func enableGoal(_ goal: AFGoal, on: Bool = true) {
        if on {
            enabled = true
            
            setWeight(savedState!.weight, for: goal.gkGoal)
            savedState = nil
        } else {
            enabled = false
            
            let weight = self.weight(for: goal)
            savedState = (weight: weight, goal: goal)
            
            self.remove(goal.gkGoal)
        }
    }

    func getChild(at index: Int) -> AFGoal {
        let gkGoal = self[index]
        return goalsMap[gkGoal]!
    }
    
    func hasChildren() -> Bool {
        return goalCount > 0
    }
    
    func howManyChildren() -> Int {
        return goalCount
    }
    
    func remove(_ goal: AFGoal) {
        goalsMap.removeValue(forKey: goal.gkGoal)
        super.remove(goal.gkGoal)
    }
    
    func setWeightage(_ weight: Float, for afGoal: AFGoal) {
        super.setWeight(weight, for: afGoal.gkGoal)

        // AFBehavior has to track goals, because there's no way to read
        // them back out of the GKBehavior structures
        afGoal.weight = weight
        goalsMap[afGoal.gkGoal] = afGoal
    }
    
    func toString() -> String {
        return String(format: "Behavior", weight)
    }
    
    func weight(for goal: AFGoal) -> Float {
        return weight(for: goal.gkGoal)
    }
}
*/
