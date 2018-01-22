//
// Created by Rob Bishop on 1/20/18
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

extension AFSceneUI {
    class Draw: BaseState {
        var drawIndicator: SKNode?
        
        override func click(name: String?, flags: NSEvent.ModifierFlags?) {
            if let name = name { click_node(name: name, flags: flags) }
            else { click_black(flags: flags) }
        }
        
        private func click_black(flags: NSEvent.ModifierFlags?) {
            // Ignore all modified clicks in the black, for now
            guard !((flags?.contains(.command) ?? false) ||
                (flags?.contains(.control) ?? false) ||
                (flags?.contains(.option) ?? false)) else { return }
            
            // Clicked in the black; add a node
            deselectAll()
            sceneUI.addNodeToPath(at: sceneUI.currentPosition)
        }
        
        private func click_node(name: String, flags: NSEvent.ModifierFlags?) {
            // Ignore all modified clicks on a path node, for now
            guard !((flags?.contains(.command) ?? false) ||
                (flags?.contains(.control) ?? false) ||
                (flags?.contains(.option) ?? false)) else { return }
            
            let graphNodes = sceneUI.activePath.graphNodes
            if graphNodes.count > 2 && name == graphNodes[0].name {
                sceneUI.finalizePath(close: true)
            } else {
                deselectAll()
                select(name, primary: true)
            }
        }
        
        override func deselect(_ name: String) {
            sceneUI.activePath.graphNodes[name]!.deselect()
            sceneUI.selectedNames.remove(name)
        }
        
        override func deselectAll() {
            sceneUI.selectedNames.forEach { sceneUI.activePath?.graphNodes[$0]!.deselect() }
            sceneUI.selectedNames.removeAll()
        }
        
        override func didEnter(from previousState: GKState?) {
            sceneUI.showFullPathHandle(true)
            
            // Plain click in the black starts a path and plants the first handle
            newPath()
            click(name: nil, flags: nil)
        }

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // Can't leave draw state until the active path is closed
            return sceneUI.activePath == nil
        }
        
        override func mouseMove(to position: CGPoint) {
            updateDrawIndicator(position)
        }
        
        func newPath() {
            guard sceneUI.activePath == nil else { fatalError() }
            
            sceneUI.activePath = AFPath(gameScene: sceneUI.gameScene)
            
            // With a new path started, no other options are available
            // until the path is finalized. However, the "add path" option
            // is disabled until there are at least two nodes in the path.
            sceneUI.contextMenu.reset()
            sceneUI.contextMenu.includeInDisplay(.AddPathToLibrary, true, enable: false)
        }
        
        override func select(_ name: String, primary: Bool) {
            sceneUI.activePath.select(name)
            sceneUI.selectedNames.insert(name)
        }
        
        override func updateDrawIndicator(_ position: CGPoint) {
            drawIndicator?.removeFromParent()
            
            if let ap = sceneUI.activePath, let start = ap.getLastHandlePosition() {
                let linePath = CGMutablePath()
                linePath.move(to: start)
                linePath.addLine(to: position)
                
                drawIndicator = SKShapeNode(path: linePath)
                sceneUI.gameScene.addChild(drawIndicator!)
            }
        }
        
        override func willExit(to nextState: GKState) {
            drawIndicator?.removeFromParent()
            deselectAll()
        }
    }
}
