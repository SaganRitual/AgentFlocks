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
    var core: AFCore!
    var uiNotifications: Foundation.NotificationCenter!
    var selectedAgent: String?
    
    init(_ injector: AFCore.AFDependencyInjector) { }
    
    private struct EditorWithIndexSimulator {
        unowned let core: AFCore
        let fullPath: [JSONSubscriptType]
        
        init(_ nodeName: JSONSubscriptType, core: AFCore) {
            self.core = core
            fullPath = core.getPathTo(JSON(nodeName).stringValue)!
        }
        
        var indexSimulator: Int {
            get {
                let i: JSONSubscriptType = "indexSimulator"
                return JSON(core.bigData.data[fullPath][i]).intValue
            }
            set {
                let i: JSONSubscriptType = "indexSimulator"
                core.bigData.getNodeWriter(for: fullPath).write(this: JSON(newValue), to: i)
            }
        }
    }

    struct EditorWithWeightValue {
        unowned let core: AFCore
        let fullPath: [JSONSubscriptType]
        
        init(_ nodeName: JSONSubscriptType, core: AFCore) {
            self.core = core
            fullPath = core.getPathTo(JSON(nodeName).stringValue)!
        }
        
        var weight: Float? {
            get {
                let w: JSONSubscriptType = "weight"
                return JSON(core.bigData.data[fullPath][w]).float
            }
            set {
                let w: JSONSubscriptType = "weight"
                core.bigData.getNodeWriter(for: fullPath).write(this: JSON(newValue!), to: w)
            }
        }
    }

    struct EditorWithIsItemEnabled {
        unowned let core: AFCore
        let field: JSONSubscriptType = "isEnabled"
        let fullPath: [JSONSubscriptType]
        
        init(_ nodeName: JSONSubscriptType, core: AFCore) {
            self.core = core
            fullPath = core.getPathTo(JSON(nodeName).stringValue)!
        }
        
        var isEnabled: Bool {
            get { return JSON(core.bigData.data[fullPath][field]).boolValue }
            set { core.bigData.getNodeWriter(for: fullPath).write(this: JSON(newValue), to: field) }
        }
    }

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
            let editor = AFAgentEditor(core.getPathTo(selectedAgent!)!, core; core)
            return editor.
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
        let itemName = item as? String ?? "behaviors"
        
        if let children = core.bigData.getChildren(of: itemName, under: selectedAgent!)?.sorted(by: {
            let lhs = EditorWithIndexSimulator($0.stringValue, core: core).indexSimulator
            let rhs = EditorWithIndexSimulator($1.stringValue, core: core).indexSimulator
            return lhs < rhs}) {
            
            return children[index]
        }
        
        fatalError()
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, labelOfItem item: Any) -> String {
        if let item = item as? String {
            return "Behavior/goal \(core.nickname(item))"
        } else {
            return "Who the fuck knows"
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, weightOfItem item: Any) -> Float {
        if let itemName = item as? JSONSubscriptType,
            let weight = EditorWithWeightValue(itemName, core: core).weight {
            return weight
        }
        
        return 0    // Not sure why I get nil items in this function
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemEnabled item: Any) -> Bool {
        if let itemName = item as? String {
            return EditorWithIsItemEnabled(itemName, core: core).isEnabled
        }
            
        return false
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
        self.uiNotifications = injector.uiNotifications!
        
        if let un = injector.uiNotifications { self.uiNotifications = un }
        else { injector.someoneStillNeedsSomething = true; iStillNeedSomething = true }
        
        if !iStillNeedSomething {
            injector.agentGoalsDataSource = self
            
            let s1 = NSNotification.Name(rawValue: AFSceneController.NotificationType.Selected.rawValue)
            let ss1 = #selector(dataSourceHasBeenSelected(notification:))
            self.uiNotifications.addObserver(self, selector: ss1, name: s1, object: nil)
            
            let s2 = NSNotification.Name(rawValue: AFSceneController.NotificationType.Deselected.rawValue)
            let ss2 = #selector(dataSourceHasBeenDeselected(notification:))
            self.uiNotifications.addObserver(self, selector: ss2, name: s2, object: nil)
        }
    }

}
