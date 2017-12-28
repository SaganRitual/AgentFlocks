//
// Created by Rob Bishop on 12/28/17
//
// Copyright © 2017 Rob Bishop
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

class UIInputState: GKComponent {
    class BaseState: GKState {
        unowned let gameScene: GameScene
        unowned let stateComponent: UIInputState
        
        init(gameScene: GameScene, stateComponent: UIInputState) {
            self.gameScene = gameScene
            self.stateComponent = stateComponent
        }
        
        func trackMouse(agent: GKAgent2D) {
            let p = stateComponent.event.location(in: gameScene)
            agent.position = vector_float2(Float(p.x), Float(p.y))
            agent.position.x += Float(stateComponent.nodeToMouseOffset.x)
            agent.position.y += Float(stateComponent.nodeToMouseOffset.y)
        }
    }
    
    class MouseDown: BaseState {
        override func didEnter(from previousState: GKState?) {
            let location = stateComponent.event.location(in: gameScene)
            let touchedNodes = gameScene.nodes(at: location)
            
            for (index, entity_) in gameScene.entities.enumerated() {
                let entity = entity_ as! AFEntity
                if touchedNodes.contains(entity.agent.spriteContainer) {
                    stateComponent.touchedNodeIndex = index
                    
                    let e = stateComponent.event.location(in: gameScene)
                    stateComponent.nodeToMouseOffset.x = entity.agent.spriteContainer.position.x - e.x
                    stateComponent.nodeToMouseOffset.y = entity.agent.spriteContainer.position.y - e.y
                    break
                }
            }
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return !(stateClass is MouseDown.Type)
        }
        
        override func update(deltaTime seconds: TimeInterval) {
        }
    }
    
    class MouseDragging: BaseState {
        var agent: GKAgent2D?
        
        override func didEnter(from previousState: GKState?) {
            if let draggedNodeIndex = stateComponent.touchedNodeIndex {
                if let entity = gameScene.entities[draggedNodeIndex] as? AFEntity {
                    stateComponent.draggedNodeIndex = draggedNodeIndex
                    
                    agent = entity.agent
                }
            }
        }
        
        override func willExit(to nextState: GKState) {
            agent = nil
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass is MouseUp.Type
        }
        
        override func update(deltaTime seconds: TimeInterval) {
            if let d = agent { trackMouse(agent: d) }
        }
    }
    
    class MouseUp: BaseState {
        override func didEnter(from previousState: GKState?) {
            if let draggedNodeIndex = stateComponent.draggedNodeIndex {
                if let entity = gameScene.entities[draggedNodeIndex] as? AFEntity {
                    trackMouse(agent: entity.agent)
                }
                
                stateComponent.draggedNodeIndex = nil
                stateComponent.nodeToMouseOffset = CGPoint.zero
            } else {
                stateComponent.reselectScenoid()
            }
            
            stateMachine!.enter(Ready.self)
        }
        
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass is Ready.Type
        }

        override func update(deltaTime seconds: TimeInterval) {
        }
    }
    
    class Ready: BaseState {
        override func didEnter(from previousState: GKState?) {
        }
        
        override func update(deltaTime seconds: TimeInterval) {
        }
    }
    
    var draggedNodeIndex: Int?
    var event: NSEvent!
    var nodeToMouseOffset = CGPoint.zero
    var selectedNodeIndex: Int?
    var stateMachine: GKStateMachine!
    var touchedNodeIndex: Int?
    
    override init() {
        super.init()
        
        stateMachine = GKStateMachine(states: [
            MouseDown(gameScene: GameScene.selfScene!, stateComponent: self),
            MouseDragging(gameScene: GameScene.selfScene!, stateComponent: self),
            MouseUp(gameScene: GameScene.selfScene!, stateComponent: self),
            Ready(gameScene: GameScene.selfScene!, stateComponent: self)
        ])
        
        stateMachine.enter(Ready.self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func enter(_ state: AnyClass, event: NSEvent) {
        self.event = event
        stateMachine.enter(state)
    }
    
    func reselectScenoid() {
        GameScene.selfScene!.selectScenoid(new: touchedNodeIndex, old: selectedNodeIndex)
        
        if touchedNodeIndex == selectedNodeIndex {
            touchedNodeIndex = nil
            selectedNodeIndex = nil
        } else {
            selectedNodeIndex = touchedNodeIndex
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        stateMachine.update(deltaTime: seconds)
    }
}
