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
    var impl: AFNodeAdapter_?
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
        
        func move(to position: CGPoint) { node!.position = position }

        var isClickable:  Bool { return spriteContainerNode.isClickable }
        var isPath:       Bool { return spriteContainerNode.isPath }
        var isPathHandle: Bool { return spriteContainerNode.isPathHandle }
        var name:       String { return spriteContainerNode.name! }
        var position:  CGPoint { return spriteContainerNode.position }

        // These have a default value, because we don't set them right away, because
        // they're set and cleared all the time. So we allow for agents and other
        // minions not to have these flags set the first time we see them.
        var isPrimarySelection: Bool {
            get { return spriteContainerNode.isPrimarySelection }
            set { spriteContainerNode.isPrimarySelection = newValue }
        }
        
        var isSelected: Bool {
            get { return spriteContainerNode.isSelected }
            set { spriteContainerNode.isSelected = newValue }
        }
        
        var spriteContainerNode: AFAgentAvatar.SpriteContainerNode {
            return self.node as! AFAgentAvatar.SpriteContainerNode
        }
        
        mutating func deselect() {
//            isSelected = false
//            isPrimarySelection = false
//            getAgent().hasBeenDeselected(getAgent().name)
        }

        mutating func select(primary: Bool) {
//            isSelected = true
//            isPrimarySelection = primary
//            let nener = node!.name!
//            getAgent().hasBeenSelected(nener, primary: primary)
        }
    }
    
    init(gameScene: SKScene, name: String?) {
        self.name = name
        guard let name = name else { impl = nil; return }

        if let node = gameScene.children.filter({ return AFNodeAdapter_($0).name == name }).first { impl = AFNodeAdapter_(node) }
        else { impl = nil }
    }
    
    func move(to position: CGPoint) { impl?.move(to: position) }

    var isClickable: Bool { return impl?.isClickable ?? false }
    var isPath:      Bool { return impl?.isPath ?? false }
    
    var isPathHandle:       Bool { return impl?.isPathHandle ?? false }
    var isPrimarySelection: Bool { return impl?.isPrimarySelection ?? false }
    var isSelected:         Bool { return impl?.isSelected ?? false }
    
    var node:     SKNode { return impl!.node! }
    var position: CGPoint? { return impl?.position }
    
    mutating func deselect() {
        impl?.deselect() }
    mutating func select(primary: Bool) {
        impl?.select(primary: primary) }
}

