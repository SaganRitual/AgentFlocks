//
// Created by Rob Bishop on 1/15/18
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

protocol AFGameSceneDelegate {
    func keyDown(with event: NSEvent)
    func keyUp(with event: NSEvent)
    func mouseDown(with event: NSEvent)
    func mouseDragged(with event: NSEvent)
    func mouseMoved(with event: NSEvent)
    func mouseUp(with event: NSEvent)
    func rightMouseUp(with event: NSEvent)
    func rightMouseDown(with event: NSEvent)
    func update(deltaTime dt: TimeInterval)
}

class AFAgentGoalsDelegate {
    private unowned let afSceneController: AFSceneController
    private unowned let core: AFCore
    private var gameScene: GameScene!
    private var selectedMotivator: String?
    
    var agent: String?
    
    init(_ injector: AFCore.AFDependencyInjector) {
        self.core = injector.core!
        self.afSceneController = injector.afSceneController!
    }
    
    func deleteItem(_ item: String) { self.deleteItem(item) }
    
    func deselect() { self.agent = nil }
    
    func getEditableAttributes(for motivator: Any, names: [String]) -> AFOrderedMap<String, Double> {
        let editor = AFMotivatorEditor(motivator as! String, core: core)

        var attributes = AFOrderedMap<String, Double>()
        
        names.forEach { if let value = editor.getOptionalScalar($0) { attributes.append(key: $0, value: value) } }

        return attributes
    }
    
    func inject(_ injector: AFCore.AFDependencyInjector) {
        var iStillNeedSomething = false
        
        if let gs = injector.gameScene { self.gameScene = gs }
        else { iStillNeedSomething = true; injector.someoneStillNeedsSomething = true }
        
        if !iStillNeedSomething {
            injector.agentGoalsDelegate = self
        }
    }
    
    func itemClicked(_ item: Any) { selectedMotivator = (item as! String) }
    
    func enableItem(_ item: Any, parent: Any?, on: Bool) {
        AFMotivatorEditor(item as! String, core: core).isEnabled = on
    }
    
    func play(_ yesno: Bool) {
//        guard let agent = AFSceneController.AFNodeAdapter(sceneController.primarySelection).getOwningAgent() else { return }
//        agent.isPlaying = yesno
    }
    
    func select(_ agent: String) { self.agent = agent }
}
