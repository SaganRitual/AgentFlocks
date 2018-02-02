//
// Created by Rob Bishop on 1/31/18
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

protocol AFSceneInputStateDelegate {
    func dragEnd(_ info: AFSceneInputState.InputInfo)
    func keyDown(_ info: AFSceneInputState.InputInfo)
    func keyUp(_ info: AFSceneInputState.InputInfo)
    func mouseDown(_ info: AFSceneInputState.InputInfo)
    func mouseDrag(_ info: AFSceneInputState.InputInfo)
    func mouseMove(_ info: AFSceneInputState.InputInfo)
    func mouseUp(_ info: AFSceneInputState.InputInfo)
    func rightMouseDown(_ info: AFSceneInputState.InputInfo)
    func rightMouseUp(_ info: AFSceneInputState.InputInfo)
    func update(deltaTime dt: TimeInterval)
}

class AFSceneInputState: GKStateMachine, AFGameSceneDelegate {
    var currentPosition = CGPoint.zero
    var delegate: AFSceneInputStateDelegate?
    var downNode: String?
    var event: NSEvent!
    var nodeToMouseOffset = CGPoint.zero
    let gameScene: GameScene
    var upNode: String?
    
    init(_ injector: AFCoreData.AFDependencyInjector) {
        self.gameScene = injector.gameScene!

        super.init(states: [
            MouseDown(), MouseDragging(), MouseMoving(), MouseUp(), RightMouseDown(), RightMouseUp()
        ])
        
        injector.sceneInputState = self
        enter(MouseUp.self)
    }
    
    func getTouchedNode() -> String? {
        let touchedNode = gameScene.nodes(at: currentPosition).filter {
            AFNodeAdapter(gameScene: gameScene, name: $0.name).isClickable
        }.first?.name
        
        return touchedNode
    }

    func setNodeToMouseOffset(anchor: CGPoint) { nodeToMouseOffset = anchor - currentPosition }
    
    func enter(_ stateClass: AnyClass, with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        self.event = event
        enter(stateClass)
    }

    func mouseDown(with event: NSEvent) { enter(MouseDown.self, with: event) }
    func mouseDragged(with event: NSEvent) { enter(MouseDragging.self, with: event) }
    func mouseMoved(with event: NSEvent) { enter(MouseMoving.self, with: event) }
    func mouseUp(with event: NSEvent) { enter(MouseUp.self, with: event) }
    func rightMouseDown(with event: NSEvent) { enter(RightMouseDown.self, with: event) }
    func rightMouseUp(with event: NSEvent) { enter(RightMouseUp.self, with: event) }
}

extension AFSceneInputState {
    class BaseState: GKState {
        // Read-only
        var afStateMachine: AFSceneInputState { return stateMachine! as! AFSceneInputState}
        var currentPosition: CGPoint { return afStateMachine.currentPosition }
        var delegate: AFSceneInputStateDelegate? { return afStateMachine.delegate }
        var event: NSEvent { return afStateMachine.event }
        var gameScene: SKScene { return afStateMachine.gameScene }

        // Read-write
        var downNode: String? { get { return afStateMachine.downNode } set { afStateMachine.downNode = newValue } }
        var upNode: String? { get { return afStateMachine.upNode } set { afStateMachine.upNode = newValue } }
    }
    
    class MouseDown: BaseState {
        override func didEnter(from previousState: GKState?) {
            downNode = afStateMachine.getTouchedNode()

            if let nodeCenter = AFNodeAdapter(gameScene: gameScene, name: downNode).position {
                afStateMachine.setNodeToMouseOffset(anchor: nodeCenter)
            }
            
            let info = InputInfo(downNode: downNode, flags: event.modifierFlags, mousePosition: currentPosition)
            delegate?.mouseDown(info)
            
            upNode = nil
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // If the user is dragging across the black, we refuse to leave
            // the down state, so we just don't see the drag. We wake up
            // normally when the mouseUp comes in.
            if stateClass == MouseDragging.self && downNode == nil { return false }
            
            return true
        }
    }
    
    class MouseDragging: BaseState {
        
        override func didEnter(from previousState: GKState?) {
            let info = InputInfo(downNode: downNode, mousePosition: currentPosition, name: downNode)
            delegate?.mouseDrag(info)

            upNode = nil
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            // MouseDown is disallowed once we start dragging. The only way out
            // of drag state is a mouse up.
            return stateClass == MouseDragging.self || stateClass == MouseUp.self
        }

    }
    
    class MouseMoving: BaseState {
        override func didEnter(from previousState: GKState?) {
            let info = InputInfo(mousePosition: currentPosition)
            delegate?.mouseMove(info)

            downNode = nil
        }

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == MouseDown.self || stateClass == MouseMoving.self
        }

    }
 
    class MouseUp: BaseState {
        override func didEnter(from previousState: GKState?) {
            // The initial state is mouse up, but we don't want
            // to respond to it like a normal mouse up. Instead
            // we just ignore this first one.
            guard previousState != nil else { return }
            
            upNode = afStateMachine.getTouchedNode()

            let info = InputInfo(downNode: downNode, flags: event.modifierFlags, mousePosition: currentPosition,
                                 name: upNode, previousState: previousState, upNode: upNode)

            if previousState == afStateMachine.state(forClass: MouseDown.self) {
                // MouseUp after MouseDown -- a simple click
                delegate?.mouseUp(info)
            } else if  previousState == afStateMachine.state(forClass: MouseDragging.self) {
                // MouseUp after dragging - a simple end-of-drag
                delegate?.dragEnd(info)
            }
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == MouseDown.self || stateClass == MouseMoving.self
        }
    }
    
    class RightMouseDown: BaseState {
        override func didEnter(from previousState: GKState?) {
            fatalError()
        }
    }
    
    class RightMouseUp: BaseState {
        override func didEnter(from previousState: GKState?) {
            fatalError()
        }
    }
}

extension AFSceneInputState {

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
    
}

extension AFSceneInputState {
    struct InputInfo {
        let downNode: String?
        let flags: NSEvent.ModifierFlags?
        let key: UInt16
        let mousePosition: CGPoint
        let name: String?
        let previousState: GKState?
        let upNode: String?
        
        init(flags: NSEvent.ModifierFlags, key: UInt16, mousePosition: CGPoint, name: String?) {
            self.downNode = nil
            self.flags = flags
            self.key = key
            self.mousePosition = mousePosition
            self.name = name
            self.previousState = nil
            self.upNode = nil
        }
        
        init(downNode: String?, flags: NSEvent.ModifierFlags?, mousePosition: CGPoint, name: String?, previousState: GKState?, upNode: String?) {
            self.downNode = downNode
            self.mousePosition = mousePosition
            self.name = name
            self.previousState = previousState
            self.upNode = upNode
            self.flags = flags
            
            self.key = 0
        }
        
        init(downNode: String?, mousePosition: CGPoint, name: String?) {
            self.downNode = downNode
            self.mousePosition = mousePosition
            self.name = name
            
            self.key = 0
            self.flags = nil
            self.previousState = nil
            self.upNode = nil
        }
        
        init(flags: NSEvent.ModifierFlags, key: UInt16, mousePosition: CGPoint) {
            self.flags = flags
            self.key = key
            self.mousePosition = mousePosition
            
            self.downNode = nil
            self.name = nil
            self.previousState = nil
            self.upNode = nil
        }
        
        init(downNode: String?, flags: NSEvent.ModifierFlags, mousePosition: CGPoint) {
            self.downNode = downNode
            self.flags = flags
            self.mousePosition = mousePosition
            
            self.key = 0
            self.name = nil
            self.previousState = nil
            self.upNode = nil
        }
        
        init(downNode: String?, mousePosition: CGPoint) {
            self.downNode = downNode
            self.mousePosition = mousePosition
            
            self.flags = nil
            self.key = 0
            self.previousState = nil
            self.name = nil
            self.upNode = nil
        }
        
        init(mousePosition: CGPoint) {
            self.mousePosition = mousePosition
            
            self.downNode = nil
            self.flags = nil
            self.key = 0
            self.name = nil
            self.previousState = nil
            self.upNode = nil
        }
    }
}
