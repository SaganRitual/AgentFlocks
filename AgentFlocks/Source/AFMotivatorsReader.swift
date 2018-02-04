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
    let coreData: AFCoreData
    let notifications: NotificationCenter
    var selectedAgent: String?
    
    init(_ injector: AFCoreData.AFDependencyInjector) {
        self.coreData = injector.coreData!
        self.notifications = injector.notifications!
        
        let s1 = NSNotification.Name(rawValue: AFSceneController.NotificationType.Selected.rawValue)
        self.notifications.addObserver(self, selector: #selector(dataSourceHasBeenSelected(notification:)), name: s1, object: nil)
        
        let s2 = NSNotification.Name(rawValue: AFSceneController.NotificationType.Deselected.rawValue)
        self.notifications.addObserver(self, selector: #selector(dataSourceHasBeenDeselected(notification:)), name: s2, object: nil)
    }

    // From the doc: The number of child items encompassed by item. ***If item is nil, this method should
    // return the number of children for the top-level item.***
    func agentGoals(_ agentGoalsController: AgentGoalsController, numberOfChildrenOfItem item: Any?) -> Int {
        // If there's no agent selected, we just tell the outline view no one is home.
        // It's so eager to go that it will call us here before the outline view even
        // appears on the screen. That's UI stuff for you.
        if selectedAgent == nil { return 0 }

        if let itemName = item as? String {
            print("1", coreData.getChildCount(for: itemName))
            return coreData.getChildCount(for: itemName)
        } else {
            let editor = AFAgentEditor(coreData: coreData, loadAgent: selectedAgent!)
            print("2", editor.compositeEditor.behaviors.count, editor.name, coreData.data)
            return editor.compositeEditor.behaviors.count
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemExpandable item: Any) -> Bool {
        if let itemName = item as? String {
            return coreData.getChildCount(for: itemName) > 0
        } else { return false }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, child index: Int, ofItem item: Any?) -> Any {
        if let itemName = item as? String, let children = coreData.getChildren(of: itemName) { return children[index] }
            
        // From the doc: The child item at index of item. If item is nil, returns the appropriate
        // child item of the root object. That's the composite.
        else {
            let editor = AFAgentEditor(coreData: coreData, loadAgent: selectedAgent!)
            return editor.compositeEditor.behaviors[index]
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, labelOfItem item: Any) -> String {
        if let item = item as? String {
            return "Behavior \(Nickname(item))"
        } else {
            return "Who the fuck knows"
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, weightOfItem item: Any) -> Float {
        if let itemName = item as? String, let path = coreData.getPathTo(itemName) {
            if coreData.data[path][itemName].dictionaryValue["weight"]?.exists() ?? false {
                return coreData.data[path][itemName]["weight"].floatValue
            }
        }
        
        return 0    // Not sure why I get nil items in this function
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemEnabled item: Any) -> Bool {
        if let itemName = item as? String { return coreData.getIsItemEnabled(itemName) }
        else { return false }
    }
    
    @objc func dataSourceHasBeenSelected(notification: Notification) {
        self.selectedAgent = AFNotification.Decode(notification).name!
    }
    
    @objc func dataSourceHasBeenDeselected(notification: Notification) {
        guard let current = self.selectedAgent else { return }

        if let incoming = AFNotification.Decode(notification).name, incoming == current {
            // If this is the one to be deselected, go ahead. If it's not us, ignore it.
            self.selectedAgent = nil
        }
    }

    func inject(_ injector: AFCoreData.AFDependencyInjector) {
        let iStillNeedSomething = false
        
        if !iStillNeedSomething {
            injector.agentGoalsDataSource = self
        }
    }

}
