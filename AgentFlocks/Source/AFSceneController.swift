//
// Created by Rob Bishop on 1/13/18
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

extension CGPoint {
    init(_ position: vector_float2) { self.x = CGFloat(position.x); self.y = CGFloat(position.y) }
    
    func as_vector_float2() -> vector_float2 { return [Float(x), Float(y)] }
    
    static func +=(lhs : inout CGPoint, rhs : CGPoint) { lhs.x += rhs.x; lhs.y += rhs.y }
    static func +(lhs : CGPoint, rhs : CGPoint) -> CGPoint { return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func -(lhs : CGPoint, rhs : CGPoint) -> CGPoint { return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
}

enum GoalSetupInputMode {
    case MultiSelectAgents, MultiSelectObstacles, NoSelect, SingleSelectAgent, SingleSelectPath
}

protocol AFCloneable {
    var name: String { get }
}

protocol AFSpriteContainerNode {
    func select(primary: Bool)
}

// Because there are so many people listening for gameScene activity,
// we have to use a broadcast rather than a delegate. But these
// are the messages you'll get anyway, just in a different form.
protocol AFSceneControllerDelegate {
    func hasBeenDeselected(_ name: String?)
    func hasBeenSelected(_ name: String, primary: Bool)
}

class AFSceneController: GKStateMachine, AFSceneInputStateDelegate {
//    var activePath: AFPath!     // The one we're doing stuff to, whether it's selected or not (like dragging handles)
    var agentsMap = [String: AFAgent]()
    var browserDelegate: AFBrowserDelegate!
    let contextMenu: AFContextMenu
    var core: AFCore!
    var draggedInTheBlack = false
    unowned let gameScene: GameScene
    var goalSetupInputMode = GoalSetupInputMode.NoSelect
    var mouseState = MouseStates.up
    var uiNotifications: Foundation.NotificationCenter!
    var obstacleCloneStamp = String()
    var parentOfNewMotivator: AFBehavior?
    var pathForNextPathGoal = 0
    var primarySelection: String?
    var sceneInputState: AFSceneInputState!
    var selectionController: AFSelectionController!
    var selectedNodes = Set<String>()
//    var selectedPath: AFPath!   // The one that has a visible selection indicator on it, if any
    var ui: AppDelegate
    
    var currentPosition: CGPoint { return sceneInputState.currentPosition }

    enum MouseStates { case down, dragging, rightDown, rightUp, up }
    enum NotificationType: String { case Deselected = "Deselected", Recalled = "Recalled", Selected = "Selected"}

    init(gameScene: GameScene, ui: AppDelegate, contextMenu: AFContextMenu) {
        self.contextMenu = contextMenu
        self.gameScene = gameScene
        self.selectionController = AFSelectionController(gameScene: gameScene)

        self.ui = ui

        super.init(states: [ Draw(), Default(), GoalSetup() ])

        enter(Default.self)
    }

//    func addNodeToPath(at position: CGPoint) { activePath.addGraphNode(at: position) }

    func bringToTop(_ name: String) {
//        let count = compressZOrder()
//        AFNodeAdapter(name).setZPosition(above: count - 1)
    }
   
    func cloneAgent() {
//        guard let copyFrom = primarySelection else { return }
//        core.core.sceneController.cloneAgent()
    }

    func compressZOrder() -> Int {
        // Get them in order
        let zOrderStack = gameScene.children.sorted(by: { $0.zPosition < $1.zPosition })
        
        // Eliminate any gaps
        zOrderStack.enumerated().forEach {  $1.zPosition = ($1.name == nil) ? -1 : CGFloat($0) }
        
        return zOrderStack.count
    }

    func createAgent() {
        // Create a new agent and send it off into the world.
        let imageIndex = browserDelegate.agentImageIndex
        let image = ui.agents[imageIndex].image
        let agentEditor = core.createAgent()
        
        let c = agentEditor.createComposite()   // Add a complimentary behavior before we
        let b = c.createBehavior()              // send the new agent on his way
        c.setWeight(forMotivator: b.name, to: 100)
        
        let g = b.createGoal()
        b.setWeight(forMotivator: g.name, to: 100)
        g.composeGoal_toWander(speed: 200)

        let agent = AFAgent(agentEditor.name, core: core, position: currentPosition)
        agentsMap[agentEditor.name] = agent

//        let agent = AFAgent2D(core: core, editor: agentEditor, image: image, position: currentPosition, gameScene: gameScene)
//        selectionController.newAgentWasCreated(agent.name)
    }
    
    func dragEnd(_ info: AFSceneInputState.InputInfo) {
        // Nothing to do, I think. Just stop tracking the mouse, which we do elsewhere. I think.
    }

    func finalizePath(close: Bool) {
//        core.newGraphNode(for: <#T##String#>)
//        activePath.refresh(final: close) // Auto-add the closing line segment
//        core.newPath()
//        core.paths.append(key: activePath.name, value: activePath)
        
//        contextMenu.includeInDisplay(.AddPathToLibrary, false)
//        contextMenu.includeInDisplay(.Place, true, enable: true)
//        
//        activePath = nil
//        enter(Default.self)
    }

    func flagsChanged(to newFlags: NSEvent.ModifierFlags) {
        drone.flagsChanged(to: newFlags)
    }
    
    func getAgent(_ name: String) -> AFAgent { return agentsMap[name]! }
    
    func getAgents(_ names: [String]) -> [AFAgent] {
        return agentsMap.filter({ names.contains($0.key) }).map { (_, value) in return value }
    }

    func getNextZPosition() -> Int { return gameScene.children.count }
    
    @objc func hasBeenSelected(notification: Foundation.Notification) {
        print("SceneController gets hasBeenSelected()")
    }
    
    @objc func hasBeenDeselected(notification: Foundation.Notification) {
        print("SceneController gets hasBeenDeselected()")
    }
    
    func inject(_ injector: AFCore.AFDependencyInjector) {
        var iStillNeedSomething = false
        
        if let bd = injector.browserDelegate { browserDelegate = bd }
        else { iStillNeedSomething = true; injector.someoneStillNeedsSomething = true }
        
        if let cd = injector.core { self.core = cd }
        else { iStillNeedSomething = true; injector.someoneStillNeedsSomething = true }
        
        if let si = injector.sceneInputState { self.sceneInputState = si }
        else { iStillNeedSomething = true; injector.someoneStillNeedsSomething = true }

        selectionController.inject(injector)
        
        if !iStillNeedSomething && !injector.someoneStillNeedsSomething {
            injector.selectionController = self.selectionController
            self.startStateMachine()
            self.selectionController.startStateMachine()
        }
    }

    func keyDown(_ info: AFSceneInputState.InputInfo) {
    }
    
    func keyUp(_ info: AFSceneInputState.InputInfo) {
    }
    
    func mouseDown(_ info: AFSceneInputState.InputInfo) {
        if let name = info.name {
            bringToTop(name)
        }
    }
    
    func mouseDrag(_ info: AFSceneInputState.InputInfo) {
        if let name = info.name, let downNode = info.downNode, name == downNode {
            AFNodeAdapter(gameScene: gameScene, name: name).move(to: info.mousePosition + sceneInputState.nodeToMouseOffset)
        }
    }
    
    func mouseMove(_ info: AFSceneInputState.InputInfo) {
        drone.mouseMove(to: info.mousePosition)
    }
    
    func mouseUp(_ info: AFSceneInputState.InputInfo) {
        drone.click(info.name, flags: info.flags)
    }
    
    @objc func newAgentHasBeenCreated(_ notification: Foundation.Notification) {
        drone.newAgentHasBeenCreated(notification)
    }
    
    @objc func newPathHasBeenCreated(_ notification: Foundation.Notification) {
        drone.newPathHasBeenCreated(notification)
    }
    
    func recallAgents() {
        let n = Foundation.Notification.Name(rawValue: NotificationType.Recalled.rawValue)
        let nn = Foundation.Notification(name: n, object: nil, userInfo: nil)
        uiNotifications.post(nn)
    }

    func rightMouseDown(_ info: AFSceneInputState.InputInfo) { }
    func rightMouseUp(_ info: AFSceneInputState.InputInfo) { }

    func setGoalSetupInputMode(_ mode: GoalSetupInputMode) {
        goalSetupInputMode = mode
        enter(GoalSetup.self)
    }
    
    func stampObstacle() {
//        let offset = currentPosition - CGPoint(activePath.graphNodes[0].position)
//        let newPath = AFPath.init(gameScene: gameScene, copyFrom: activePath, offset: offset)
//
//        newPath.stampObstacle()
//        data.obstacles[newPath.name] = newPath
    }
    
    func startStateMachine() { enter(Default.self) }
}

extension AFSceneController {
    struct Notification {
        struct Encode {
            var attribute: AFAgentAttribute?
            var core: AFCore?
            var editor: AFEditor?
            var gameScene: GameScene?
            var isPrimary: Bool?
            var name: String?
            var value: Any?
            var weight: Float?
            
            init(_ name: String, attribute: AFAgentAttribute? = nil, core: AFCore? = nil,
                 editor: AFEditor? = nil, gameScene: GameScene? = nil, isPrimary: Bool? = nil, value: Any? = nil,
                 weight: Float? = nil) {
                self.attribute = attribute
                self.core = core
                self.editor = editor
                self.gameScene = gameScene
                self.isPrimary = isPrimary
                self.name = name
                self.value = value
                self.weight = weight
            }
            
            func encode() -> [String : Any] {
                return ["attribute" : attribute ?? "<no attributes>",
                        "core"      : core ?? "<no core>",
                        "editor"    : editor ?? "<no editor>",
                        "gameScene" : gameScene ?? "<no game scene>",
                        "isPrimary" : self.isPrimary ?? "<no primary selection indicator>",
                        "name"      : self.name ?? "<missing name>",
                        "value"     : self.value ?? "<missing value>",
                        "weight"    : self.weight ?? "<missing weight>" ]
            }
        }
        
        struct Decode {
            var attribute: AFAgentAttribute? { return getField("attribute") as? AFAgentAttribute }
            var core: AFCore? { return getField("core") as? AFCore }
            var editor: AFEditor? { return getField("editor") as? AFEditor }
            var gameScene: GameScene? { return getField("gameScene") as? GameScene }
            var isPrimary: Bool? { return getBool("isPrimary") }
            let foundationNotification: Foundation.Notification
            var name: String? { return getField("name") as? String }
            var value: Any? { return getField("value") }
            var weight: Float? { return getFloat("weight") }
            
            init(_ foundationNotification: Foundation.Notification) { self.foundationNotification = foundationNotification }
            func getField(_ key: String) -> Any? { return foundationNotification.userInfo![key] }
            
            func getBool(_ key: String) -> Bool? { return getField(key) as? Bool }
            func getFloat(_ key: String) -> Float? { return getField(key) as? Float }
        }
    }
}
