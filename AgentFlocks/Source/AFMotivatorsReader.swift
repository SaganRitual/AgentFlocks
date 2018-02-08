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

    // From the doc: The number of child items encompassed by item. ***If item is nil, this method should
    // return the number of children for the top-level item.***
    func agentGoals(_ agentGoalsController: AgentGoalsController, numberOfChildrenOfItem item: Any?) -> Int {
        // If there's no agent selected, we just tell the outline view no one is home.
        // It's so eager to go that it will call us here before the outline view even
        // appears on the screen. That's UI stuff for you.
        if selectedAgent == nil { return 0 }

//        if let itemName = item as? String {
//            print("1", coreData.getChildCount(for: itemName))
//            return coreData.getChildCount(for: itemName)
//        } else {
//            let editor = AFAgentEditor(core: core, loadAgent: selectedAgent!)
//            print("2", editor.compositeEditor.behaviors.count, editor.name, coreData.data)
//            return editor.compositeEditor.behaviors.count
//        }
        return 0
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemExpandable item: Any) -> Bool {
        return false
//        if let itemName = item as? String {
//            return coreData.getChildCount(for: itemName) > 0
//        } else { return false }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, child index: Int, ofItem item: Any?) -> Any {
        return false
//        if let itemName = item as? String, let children = coreData.getChildren(of: itemName) { return children[index] }
//
//        // From the doc: The child item at index of item. If item is nil, returns the appropriate
//        // child item of the root object. That's the composite.
//        else {
//            let editor = AFAgentEditor(core: core, loadAgent: selectedAgent!)
//            return editor.compositeEditor.behaviors[index]
//        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, labelOfItem item: Any) -> String {
//        if let item = item as? String {
//            return "Behavior \(Nickname(item))"
//        } else {
//            return "Who the fuck knows"
//        }
        return "false"
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, weightOfItem item: Any) -> Float {
//        if let itemName = item as? String, let path = coreData.getPathTo(itemName) {
//            if coreData.data[path][itemName].dictionaryValue["weight"]?.exists() ?? false {
//                return coreData.data[path][itemName]["weight"].floatValue
//            }
//        }
        
        return 0    // Not sure why I get nil items in this function
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemEnabled item: Any) -> Bool {
//        if let itemName = item as? String { return coreData.getIsItemEnabled(itemName) }
//        else { return false }
        return false
    }
    
    @objc func dataSourceHasBeenSelected(notification: Foundation.Notification) {
    }
    
    @objc func dataSourceHasBeenDeselected(notification: Foundation.Notification) {
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
