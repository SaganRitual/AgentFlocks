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

class AFSceneInput: AFGameSceneDelegate {
    var currentPosition = CGPoint.zero
    let data: AFData
    var downNodeName: String?
    let gameScene: GameScene!
    let sceneUI: AFSceneUI
    var touchedNodes = [SKNode]()
    var upNodeName: String?
    
    init(data: AFData, sceneUI: AFSceneUI, gameScene: GameScene) {
        self.data = data
        self.gameScene = gameScene
        self.sceneUI = sceneUI
    }
    
    func getTouchedNode() -> SKNode? {
        let touchedNodes = gameScene.nodes(at: currentPosition).filter({
            var selectable = true
            if $0.name == nil { selectable = false }
            else if let userData = $0.userData {
                if let flag = userData["selectable"] as? Bool {
                    selectable = flag
                }
                
                if let type = userData["type"] as? String, type == "pathContainer" {
                    selectable = false
                }
            }
            
            return selectable
        })
        
        return touchedNodes.last
    }
    
    func getTouchedNodeName() -> String? {
        if let node = getTouchedNode() { return node.name }
        else { return nil }
    }

    func keyDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNodeName = nil
        upNodeName = nil
        sceneUI.keyDown(mouseAt: currentPosition)
    }

    func keyUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNodeName = nil
        upNodeName = nil
        sceneUI.keyUp(mouseAt: currentPosition)
    }

    func mouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNodeName = getTouchedNodeName()
        sceneUI.mouseDown(on: downNodeName, at: currentPosition, flags: event.modifierFlags)
        upNodeName = nil
    }
    
    func mouseDragged(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        sceneUI.mouseDrag(on: downNodeName, at: currentPosition)
    }
    
    func mouseMoved(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        sceneUI.mouseMove(at: currentPosition)
    }
    
    func mouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeName = getTouchedNodeName()
        sceneUI.mouseUp(on: upNodeName, at: currentPosition, flags: event.modifierFlags)
        downNodeName = nil
    }
    
    func rightMouseDown(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        downNodeName = getTouchedNodeName()
        sceneUI.rightMouseDown(on: downNodeName)
        upNodeName = nil
    }
    
    func rightMouseUp(with event: NSEvent) {
        currentPosition = event.location(in: gameScene)
        upNodeName = getTouchedNodeName()
        sceneUI.rightMouseUp(on: upNodeName)
        downNodeName = nil
    }
    
    func update(deltaTime dt: TimeInterval) {
        data.entities.forEach { $0.update(deltaTime: dt ) }
    }
}
