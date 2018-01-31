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

struct AFMotivatorsReader/*: AgentGoalsDataSource*/ {
//    var agent: String?
//    unowned let coreData: AFCoreData
    
    init(coreData: AFCoreData) {
//        self.coreData = coreData
    }
/*
    func agentGoals(_ agentGoalsController: AgentGoalsController, numberOfChildrenOfItem item: Any?) -> Int {
        let itemName = item! as! String
        return coreData.getChildCount(for: itemName)
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemExpandable item: Any) -> Bool {
        let itemName = item as! String
        return coreData.getChildCount(for: itemName) > 0
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, child index: Int, ofItem item: Any?) -> Any {
        let itemName = item! as! String
        if let children = coreData.getChildrenOf(itemName) { return children[index] }
        else { return 0 }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, labelOfItem item: Any) -> String {
        return "Label \(item as? String ?? "huh?")"
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, weightOfItem item: Any) -> Float {
        let itemName = item as! String
        return coreData.getItemWeight(itemName)
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemEnabled item: Any) -> Bool {
        let itemName = item as! String
        return coreData.getIsItemEnabled(itemName)
    }
 */
}
