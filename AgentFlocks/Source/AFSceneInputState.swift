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
    let scene: GameScene
    var upNode: String?
    
    init(scene: GameScene) {
        self.scene = scene

        super.init(states: [
            MouseDown(), MouseDragging(), MouseMoving(), MouseUp(), RightMouseDown(), RightMouseUp()
        ])
        
        enter(MouseUp.self)
    }
    
    func getTouchedNode() -> String? {
        let touchedNode = scene.nodes(at: currentPosition).filter({
            print(Nickname(upNode ?? "??????????"))
            let clickable = AFNodeAdapter(scene: scene, name: $0.name).isClickable
            print(Nickname($0.name ?? "?????????"), clickable)
            return clickable
        }).first?.name
        
        print(Nickname(touchedNode ?? "???????????"))
        return touchedNode
    }

    func setNodeToMouseOffset(anchor: CGPoint) { nodeToMouseOffset = anchor - currentPosition }
}

extension AFSceneInputState {
    class BaseState: GKState {
        // Read-only
        var afStateMachine: AFSceneInputState { return stateMachine! as! AFSceneInputState}
        var currentPosition: CGPoint { return afStateMachine.currentPosition }
        var delegate: AFSceneInputStateDelegate? { return afStateMachine.delegate }
        var event: NSEvent { return afStateMachine.event }
        var scene: SKScene { return afStateMachine.scene }

        // Read-write
        var downNode: String? { get { return afStateMachine.downNode } set { afStateMachine.downNode = newValue } }
        var upNode: String? { get { return afStateMachine.upNode } set { afStateMachine.upNode = newValue } }
    }
    
    class MouseDown: BaseState {
        override func didEnter(from previousState: GKState?) {
            let info = InputInfo(downNode: downNode, flags: event.modifierFlags, mousePosition: currentPosition)
            delegate?.mouseDown(info)
            
            upNode = nil
        }
    }
    
    class MouseDragging: BaseState {
        
        override func didEnter(from previousState: GKState?) {
            let info = InputInfo(downNode: downNode, mousePosition: currentPosition, name: downNode)
            delegate?.mouseDrag(info)

            upNode = nil
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == MouseDown.self || stateClass == MouseDragging.self || stateClass == MouseUp.self
        }

    }
    
    class MouseMoving: BaseState {
        
        override func didEnter(from previousState: GKState?) {
            let info = InputInfo(mousePosition: currentPosition)
            delegate?.mouseMove(info)

            downNode = nil
        }

        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == MouseDown.self || stateClass == MouseMoving.self || stateClass == MouseUp.self
        }

    }
 
    class MouseUp: BaseState {
        override func didEnter(from previousState: GKState?) {
            // The initial state is mouse up, but we don't want
            // to respond to it like a normal mouse up. Instead
            // we just ignore this first one.
            guard previousState != nil else { return }
            
            if previousState == afStateMachine.state(forClass: MouseDown.self) {
                // MouseUp after MouseDown -- a simple click

                let info = InputInfo(downNode: downNode, flags: event.modifierFlags,
                                     mousePosition: currentPosition, name: upNode, upNode: upNode)
                
                delegate?.mouseUp(info)
                
            } else if previousState == afStateMachine.state(forClass: MouseDragging.self) {
                // MouseUp after dragging - a simple end-of-drag
            }
            
            downNode = nil
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
        currentPosition = event.location(in: scene)
        downNode = nil
        upNode = nil
        
        let info = InputInfo(flags: event.modifierFlags, key: event.keyCode, mousePosition: currentPosition)
        delegate?.keyDown(info)
    }
    
    func keyUp(with event: NSEvent) {
        currentPosition = event.location(in: scene)
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
        let upNode: String?
        
        init(flags: NSEvent.ModifierFlags, key: UInt16, mousePosition: CGPoint, name: String?) {
            self.flags = flags
            self.key = key
            self.mousePosition = mousePosition
            self.name = name
            self.downNode = nil
            self.upNode = nil
        }
        
        init(downNode: String?, flags: NSEvent.ModifierFlags?, mousePosition: CGPoint, name: String?, upNode: String?) {
            self.downNode = downNode
            self.mousePosition = mousePosition
            self.name = name
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
            self.upNode = nil
        }
        
        init(flags: NSEvent.ModifierFlags, key: UInt16, mousePosition: CGPoint) {
            self.flags = flags
            self.key = key
            self.mousePosition = mousePosition
            
            self.downNode = nil
            self.name = nil
            self.upNode = nil
        }
        
        init(downNode: String?, flags: NSEvent.ModifierFlags, mousePosition: CGPoint) {
            self.downNode = downNode
            self.flags = flags
            self.mousePosition = mousePosition
            
            self.name = nil
            self.upNode = nil
            self.key = 0
        }
        
        init(downNode: String?, mousePosition: CGPoint) {
            self.downNode = downNode
            self.mousePosition = mousePosition
            
            self.flags = nil
            self.name = nil
            self.upNode = nil
            self.key = 0
        }
        
        init(mousePosition: CGPoint) {
            self.mousePosition = mousePosition
            
            self.downNode = nil
            self.flags = nil
            self.name = nil
            self.upNode = nil
            self.key = 0
        }
    }
}
