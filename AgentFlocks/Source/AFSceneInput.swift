//
// Created by Rob Bishop on 1/17/18
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

protocol AFSceneInputDelegate {
    func keyDown(_ info: AFSceneInput.InputInfo)
    func keyUp(_ info: AFSceneInput.InputInfo)
    func mouseDown(_ info: AFSceneInput.InputInfo)
    func mouseDrag(_ info: AFSceneInput.InputInfo)
    func mouseMove(_ info: AFSceneInput.InputInfo)
    func mouseUp(_ info: AFSceneInput.InputInfo)
    func rightMouseDown(_ info: AFSceneInput.InputInfo)
    func rightMouseUp(_ info: AFSceneInput.InputInfo)
    func update(deltaTime dt: TimeInterval)
}

class AFSceneInput: AFGameSceneDelegate {
    var currentPosition = CGPoint.zero
    let appData: AFDataModel
    var delegate: AFSceneInputDelegate?
    var downNode: SKNode?
    let gameScene: GameScene!
    var touchedNodes = [SKNode]()
    var upNode: SKNode?
    
    init(appData: AFDataModel, gameScene: GameScene) {
        self.appData = appData
        self.gameScene = gameScene
    }

    func getTouchedNode() -> SKNode? {
        // We have a lot of sprites flying around, but we only care about the primary
        // containers, all of which are marked as clickable. Everyone else is like
        // they're not really there.
        return gameScene.nodes(at: currentPosition).filter { AFNodeAdapter($0).getIsClickable() ?? false }.first
    }

    func keyDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNode = nil
        upNode = nil
        
        let info = InputInfo(flags: event.modifierFlags, key: event.keyCode, mousePosition: currentPosition)
        delegate?.keyDown(info)
    }

    func keyUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNode = nil
        upNode = nil
        
        let info = InputInfo(flags: event.modifierFlags, key: event.keyCode, mousePosition: currentPosition)
        delegate?.keyUp(info)
    }

    func mouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNode = getTouchedNode()
        
        let info = InputInfo(downNode: downNode, flags: event.modifierFlags, mousePosition: currentPosition)
        delegate?.mouseDown(info)

        upNode = nil
    }
    
    func mouseDragged(with event: NSEvent) {
        guard let downNode = self.downNode else { return }
        currentPosition = event.location(in: gameScene)
        
        let info = InputInfo(downNode: downNode, mousePosition: currentPosition, node: downNode)
        delegate?.mouseDrag(info)
    }
    
    func mouseMoved(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        
        let info = InputInfo(mousePosition: currentPosition)
        delegate?.mouseMove(info)
    }
    
    func mouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNode = getTouchedNode()
        
        let info = InputInfo(downNode: downNode, flags: event.modifierFlags, mousePosition: currentPosition, node: upNode, upNode: upNode)
        delegate?.mouseUp(info)
        
        downNode = nil
    }
    
    func rightMouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNode = getTouchedNode()

        let info = InputInfo(downNode: downNode, flags: nil, mousePosition: currentPosition, node: upNode, upNode: upNode)
        delegate?.rightMouseDown(info)
        upNode = nil
        
    }
    
    func rightMouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNode = getTouchedNode()

        let info = InputInfo(downNode: downNode, flags: nil, mousePosition: currentPosition, node: upNode, upNode: upNode)
        delegate?.rightMouseUp(info)
        
        downNode = nil
    }
    
    func update(deltaTime dt: TimeInterval) {
        delegate?.update(deltaTime: dt)
    }
}

extension AFSceneInput {
    struct InputInfo {
        let downNode: SKNode?
        let flags: NSEvent.ModifierFlags?
        let key: UInt16
        let mousePosition: CGPoint
        let node: SKNode?
        let upNode: SKNode?
        
        init(flags: NSEvent.ModifierFlags, key: UInt16, mousePosition: CGPoint, node: SKNode?) {
            self.flags = flags
            self.key = key
            self.mousePosition = mousePosition
            self.node = node
            
            self.downNode = nil
            self.upNode = nil
        }
        
        init(downNode: SKNode?, flags: NSEvent.ModifierFlags?, mousePosition: CGPoint, node: SKNode?, upNode: SKNode?) {
            self.downNode = downNode
            self.mousePosition = mousePosition
            self.node = node
            self.upNode = upNode
            self.flags = flags
            
            self.key = 0
        }
        
        init(downNode: SKNode?, mousePosition: CGPoint, node: SKNode?) {
            self.downNode = downNode
            self.mousePosition = mousePosition
            self.node = node
            
            self.key = 0
            self.flags = nil
            self.upNode = nil
        }
        
        init(flags: NSEvent.ModifierFlags, key: UInt16, mousePosition: CGPoint) {
            self.flags = flags
            self.key = key
            self.mousePosition = mousePosition
            
            self.downNode = nil
            self.node = nil
            self.upNode = nil
        }
        
        init(downNode: SKNode?, flags: NSEvent.ModifierFlags, mousePosition: CGPoint) {
            self.downNode = downNode
            self.flags = flags
            self.mousePosition = mousePosition
            
            self.node = nil
            self.upNode = nil
            self.key = 0
        }
        
        init(downNode: SKNode?, mousePosition: CGPoint) {
            self.downNode = downNode
            self.mousePosition = mousePosition
            
            self.flags = nil
            self.node = nil
            self.upNode = nil
            self.key = 0
        }
        
        init(mousePosition: CGPoint) {
            self.mousePosition = mousePosition
            
            self.downNode = nil
            self.flags = nil
            self.node = nil
            self.upNode = nil
            self.key = 0
        }
    }
}
