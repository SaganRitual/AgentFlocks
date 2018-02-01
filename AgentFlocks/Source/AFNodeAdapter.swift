//
// Created by Rob Bishop on 1/30/18
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

struct AFNodeAdapter {
    let impl: AFNodeAdapter_?
    let name: String?
    
    struct AFNodeAdapter_ {
        let node: SKNode?
        let userData: NSMutableDictionary!

        init(_ node: SKNode?) {
            self.node = node
            
            if let node = node {
                self.userData = node.userData
            } else {
                self.userData = nil
            }
        }
        
        func getAgent() -> AFAgent2D { return userData["agent"] as! AFAgent2D }
        func move(to position: CGPoint) { getAgent().move(to: position) }

        var isAgent:      Bool { return userData["isAgent"] as! Bool }
        var isClickable:  Bool { return userData["isClickable"] as! Bool }
        var isPath:       Bool { return userData["isPath"] as! Bool }
        var isPathHandle: Bool { return userData["isPathHandle"] as! Bool }
        var ownsUserData: Bool { return node?.userData != nil }
        var position:  CGPoint { return CGPoint(getAgent().position) }

        // These have a default value, because we don't set them right away, because
        // they're set and cleared all the time. So we allow for agents and other
        // minions not to have these flags set the first time we see them.
        var isPrimarySelection: Bool {
            get { return userData["isPrimarySelection"] as? Bool ?? false }
            set { setUserData("isPrimarySelection", to: newValue) }
        }
        
        var isSelected: Bool {
            get { return userData["isSelected"] as? Bool ?? false }
            set { setUserData("isSelected", to: newValue) }
        }
        
        func deselect() {
            setUserData("isSelected", to: true)
            setUserData("isPrimarySelection", to: false)
            getAgent().hasBeenDeselected(getAgent().name)
        }

        func select(primary: Bool) {
            setUserData("isSelected", to: true)
            setUserData("isPrimarySelection", to: primary)
            getAgent().hasBeenSelected(getAgent().name, primary: primary)
        }
        
        func setUserData(_ key: String, to value: Bool) { userData[key] = value }
    }
    
    init(scene: SKScene, name: String?) {
        self.name = name
        guard name != nil else { impl = nil; return }

        if let node = scene.children.filter({ return AFNodeAdapter_($0).ownsUserData }).first { impl = AFNodeAdapter_(node) }
        else { impl = nil }
    }
    
    func getAgent() -> AFAgent2D? { return impl?.getAgent() }
    func move(to position: CGPoint) { impl?.move(to: position) }

    var isAgent:     Bool { return impl?.isAgent ?? false }
    var isClickable: Bool { return impl?.isClickable ?? false }
    var isPath:      Bool { return impl?.isPath ?? false }
    
    var isPathHandle:       Bool { return impl?.isPathHandle ?? false }
    var isPrimarySelection: Bool { return impl?.isPrimarySelection ?? false }
    var isSelected:         Bool { return impl?.isSelected ?? false }
    
    var node:     SKNode { return impl!.node! }
    var position: CGPoint? { return impl?.position }
    
    func deselect() { impl?.deselect() }
    func select(primary: Bool) { impl?.select(primary: primary) }
}
/*
struct AFNodeAdapter {
    let name: String?
    let node: SKNode
    let scene: SKScene
    
    init(_ name: String?, scene: SKScene) {
        self.scene = scene
        
        if let name = name {
            self.name = name
            self.node = scene.children.filter { $0.name != nil && $0.name! == name }.first!
        }
    }
    
    init(_ node: SKNode) {
        // Lots of sprites out there, but we only care about the ones
        // that have names, and not even all of them.
        if let nodeName = node.name { self.name = nodeName } else { self.name = nil }
        self.node = node
    }
    
    func getIsClickable() -> Bool {
        return (getUserDataEntry("clickable") as? Bool) ?? false
    }
    
    static func getOwningAgent(for node: SKNode) -> AFAgent2D? {
        if let userData = node.userData, let value = userData["OwningAgent"] {
            return value as? AFAgent2D
        } else {
            return nil
        }
    }
    
    func getOwningAgent() -> AFAgent2D? {
        return AFNodeAdapter.getOwningAgent(for: self.node)
    }
    
    func getUserDataEntry(_ name: String) -> Any? {
        if let userData = node.userData, let value = userData[name] {
            return value
        } else {
            return nil
        }
    }
    
    func move(to position: CGPoint) {
        getOwningAgent()!.move(to: position)
    }
    
    func setIsClickable(_ set: Bool = true) {
        setUserDataEntry(key: "clickable", value: set)
    }
    
    func setOwningAgent(_ agent: AFAgent2D) {
        if let userData = node.userData { userData["OwningAgent"] = agent }
    }
    
    func setUserDataEntry(key: String, value: Any) {
        if let userData = node.userData {
            userData[key] = value
        }
    }
    
    func setZPosition(above: Int) {
        setUserDataEntry(key: "zPosition", value: above)
    }
}
*/
