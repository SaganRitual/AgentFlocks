//
// Created by Rob Bishop on 1/23/18
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

class AFMotivatorsReader: AgentGoalsDataSource {
    var arrayizer = 0   // For simulating array behavior with certain nodes in the data
    var core: AFCore!
    var dataNotifications: Foundation.NotificationCenter!
    var selectedAgent: String?
    var uiNotifications: Foundation.NotificationCenter!

    init(_ injector: AFCore.AFDependencyInjector) {}

    // From the doc: The number of child items encompassed by item. ***If item is nil, this method should
    // return the number of children for the top-level item.***
    func agentGoals(_ agentGoalsController: AgentGoalsController, numberOfChildrenOfItem item: Any?) -> Int {
        // If there's no agent selected, we just tell the outline view no one is home.
        // It's so eager to go that it will call us here before the outline view even
        // appears on the screen. That's UI stuff for you.
        guard selectedAgent != nil else { return 0 }

        if let itemName = item as? String {
            return core.bigData.getChildCount(for: itemName)
        } else {
            let pathToBehaviors = core.getPathTo(selectedAgent!)! + ["behaviors"]
            let behaviors = AFCompositeEditor(pathToBehaviors, core: core)
            return behaviors.count
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemExpandable item: Any) -> Bool {
        if let itemName = item as? String {
            return core.bigData.getChildCount(for: itemName) > 0
        } else { return false }
    }
    
    // From the doc: The child at item[index]. If item is nil, returns the appropriate
    // child item of the root object. That's the composite, ie, the agent's behaviors dictionary.
    // We can also come here for goals, hence using the mini-editor for access to the fake index.
    func agentGoals(_ agentGoalsController: AgentGoalsController, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            let pathToComposite: [JSONSubscriptType] = ["agents", selectedAgent!, "behaviors"]
            let behaviors = AFCompositeEditor(pathToComposite, core: core)
            return behaviors[index]
        } else if let itemName = item as? String {
            let pathToItem = core.getPathTo(itemName)!
            let pathToDictionary = Array(pathToItem.prefix(pathToItem.count))
            if pathToDictionary.contains(where: { String(describing: $0) == "behaviors" }) {
                // A kludgey way of determining whether we're talking to a
                // behavior or a goal. Figure out a better way.
                let goals = AFBehaviorEditor(pathToDictionary, core: core)
                return goals[index]
            } else {
                let behaviors = AFCompositeEditor(pathToDictionary, core: core)
                return behaviors[index]
            }
        }
        
        fatalError()
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, labelOfItem item: Any) -> String {
        if let item = item as? String {
            let fullPath = core.getPathTo(item)!
            let c = fullPath.count
            let parent = String(describing: fullPath[c - 2])
            if parent == "behaviors" {
                return "Behavior \(core.nickname(item))"
            } else if parent == "goals" {
                return "Goal \(core.nickname(item))"
            } else {
                return "The agent goals controller is a noisy contraption. Ignore stuff like this."
            }
        } else {
            return "And this."
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, weightOfItem item: Any) -> Float {
        if let itemName = item as? String { return AFMotivatorEditor(itemName, core: core).weight }
        
        return 0    // Not sure why I get nil items in this function
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemEnabled item: Any) -> Bool {
        if let itemName = item as? String { return AFMotivatorEditor(itemName, core: core).isEnabled }
            
        return false
    }
    
    // The motivators reader has to make a couple of tree nodes look like arrays. For
    // this, we need an ascending id number on every node we'll ever care about. At this
    // moment, that means behaviors and goals. So whenever a behavior or goal is created,
    // we grab it as it goes by and stamp the number on it.
    @objc func coreDataChanged(notification: Foundation.Notification) {
        let pathToChangedNode = AFData.Notifier(notification).pathToNode
        let changedNode = pathToChangedNode.last!
        let pathToParent = Array(pathToChangedNode.prefix(upTo: pathToChangedNode.count - 1))
        let parentNode = String(describing: pathToParent.last!)
        
        guard parentNode == "behaviors" || parentNode == "goals" else { return }

        // I think these serial numbers count as metadata. I generally worry about the notion
        // of suppressing notifications, but it seems ok when we're talking about metadata.
        let nw_ = core.bigData.getNodeWriter(pathToParent)
        let nw = nw_.suppressNotifications()
        let sn: JSONSubscriptType = "serialNumber"
        nw.write(this: JSON(arrayizer), to: changedNode, under: sn)
        
        arrayizer += 1
    }
    
    @objc func dataSourceHasBeenSelected(notification: Foundation.Notification) {
        selectedAgent = AFSceneController.Notification.Decode(notification).name
    }
    
    @objc func dataSourceHasBeenDeselected(notification: Foundation.Notification) {
        selectedAgent = nil
    }
    
    func inject(_ injector: AFCore.AFDependencyInjector) {
        var iStillNeedSomething = false
        
        self.core = injector.core!
        
        if let dn = injector.dataNotifications { self.dataNotifications = dn }
        else { injector.someoneStillNeedsSomething = true; iStillNeedSomething = true }

        if let un = injector.uiNotifications { self.uiNotifications = un }
        else { injector.someoneStillNeedsSomething = true; iStillNeedSomething = true }
        
        if !iStillNeedSomething {
            injector.agentGoalsDataSource = self
            
            let s1 = Foundation.Notification.Name(rawValue: AFSceneController.NotificationType.Selected.rawValue)
            let ss1 = #selector(dataSourceHasBeenSelected(notification:))
            self.uiNotifications.addObserver(self, selector: ss1, name: s1, object: nil)
            
            let s2 = Foundation.Notification.Name(rawValue: AFSceneController.NotificationType.Deselected.rawValue)
            let ss2 = #selector(dataSourceHasBeenDeselected(notification:))
            self.uiNotifications.addObserver(self, selector: ss2, name: s2, object: nil)
            
            let s3 = Foundation.Notification.Name(rawValue: "ThereCanBeOnlyOne")
            let ss3 = #selector(coreDataChanged(notification:))
            self.dataNotifications.addObserver(self, selector: ss3, name: s3, object: nil)
        }
    }

}
