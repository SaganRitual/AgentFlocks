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

enum GoalSetupInputMode {
    case MultiSelectAgents, MultiSelectObstacles, NoSelect, SingleSelectAgent, SingleSelectPath
}

class AFSceneUI: GKStateMachine, AFSceneInputDelegate {
    var activePath: AFPath!     // The one we're doing stuff to, whether it's selected or not (like dragging handles)
    let contextMenu: AFContextMenu
    var currentPosition = CGPoint.zero
    var data: AFData!
    var downNode: SKNode?
    var goalSetupInputMode = GoalSetupInputMode.NoSelect
    var mouseState = MouseStates.up
    var nodeToMouseOffset = CGPoint.zero
    var obstacleCloneStamp = String()
    var parentOfNewMotivator: AFBehavior?
    var pathForNextPathGoal = 0
    var primarySelection: SKNode?
    unowned let gameScene: GameScene
    var selectedNodes = Set<SKNode>()
    var selectedPath: AFPath!   // The one that has a visible selection indicator on it, if any
    var ui: AppDelegate
    var upNode: SKNode?

    enum MouseStates { case down, dragging, rightDown, rightUp, up }

    init(gameScene: GameScene, ui: AppDelegate, contextMenu: AFContextMenu) {
        self.contextMenu = contextMenu
        self.gameScene = gameScene
        self.ui = ui

        super.init(states: [ Draw(), Default(), GoalSetup() ])
        
        enter(Default.self)
    }
    
    func addNodeToPath(at position: CGPoint) {
        let newNode = activePath.addGraphNode(at: position)
        select(newNode.sprite, primary: true)
        
        // With two or more nodes, we now have a path that can be
        // added to the library
        if activePath.graphNodes.count > 1 {
            contextMenu.enableInDisplay(.AddPathToLibrary)
        }
    }

    func bringToTop(_ node: SKNode) {
        if let pathOwner = AFNodeAdapter(node).getPathOwner() {
            pathOwner.getNodesForBringToTop().forEach { bringToTop_($0) }
        } else {
            bringToTop_(node)
        }
    }
    
    func bringToTop_(_ nodeToPromote: SKNode) {
        // Get them in order
        var zOrderStack = gameScene.children.sorted(by: { $0.name == nil || $0.zPosition < $1.zPosition })

        // Eliminate any gaps
        zOrderStack.enumerated().forEach {  $1.zPosition = ($1.name == nil) ? -1 : CGFloat($0) }
        
        // Nameless nodes go to the bottom. So if we're in here due to a nameless node,
        // just take the opportunity to make the zPositions contiguous and then bail.
        if nodeToPromote.name == nil { return }

        // Find the slot where the promotee lives
        if let emptySlot = zOrderStack.index(where: { $0.name != nil && $0.name == nodeToPromote.name }) {
            // Take him out
            zOrderStack.remove(at: emptySlot)
            
            // Put him at the end, which is the top
            zOrderStack.append(nodeToPromote)
            
            // Reorder the gameScene zPositions
            zOrderStack.enumerated().forEach { $1.zPosition = CGFloat($0) }
        } else {
            print("Doesn't look right", zOrderStack.count)
        }
        
        // Use this to dig into that ordering issue further if I
        // ever get the stomach for it.
        func dumpChildren(of node: SKNode, tabCount: Int) {
            let debugStack = node.children.sorted(by: { $0.zPosition > $1.zPosition })
            debugStack.forEach {
                let typeString = AFNodeAdapter($0).getTypeString() ?? "<type unknown>"

                for _ in 0 ..< tabCount { print("\t", separator: "", terminator: "") }
                print($0.zPosition, typeString, $0.name ?? "<no name>")
                
                dumpChildren(of: $0, tabCount: tabCount + 1)
            }
        }
    }
    
    func cloneAgent() {
        guard let copyFrom = primarySelection else { return }

        let originalEntity = data.entities[copyFrom.name!]!
        _ = makeEntity(copyFrom: originalEntity, position: currentPosition)
    }

    func finalizePath(close: Bool) {
        activePath.refresh(final: close) // Auto-add the closing line segment
        AFCore.data.paths.append(key: activePath.name, value: activePath)
                
        contextMenu.includeInDisplay(.AddPathToLibrary, false)
        contextMenu.includeInDisplay(.Place, true, enable: true)
        
        activePath = nil
        enter(Default.self)
    }

    func flagsChanged(to newFlags: NSEvent.ModifierFlags) {
        drone.flagsChanged(to: newFlags)
    }
    
    func getNextZPosition() -> Int { return gameScene.children.count }

    func getNode(named: String?) -> SKNode? {
        guard let name = named else { return nil }
        
        return gameScene.childNode(withName: name)
    }

    func getPathThatOwnsTouchedNode(_ name: String) -> (AFPath, String)? {
        for path in data.paths {
            if path.graphNodes.getIndexOf(name) != nil {
                return (path, name)
            }
        }
        
        if let obstacle = data.obstacles[name] {
            return (obstacle, name)
        }
        
        return nil
    }

    func getParentForNewMotivator() -> AFBehavior {
        if let p = parentOfNewMotivator { return p }
        else {
            let agent = primarySelection!
            let entity = data.entities[agent.name!]!
            return (entity.agent.behavior! as! GKCompositeBehavior)[0] as! AFBehavior
        }
    }
    
    func isNodeClickable(_ node: SKNode) -> Bool { return AFNodeAdapter(node).getIsClickable() }
    
    // meaning is there any descendant of this node that is clickable. If there
    // is, count the branch -- namely the top node -- as clickable.
    func isNodeBranchClickable(_ node: SKNode) -> Bool {
        if isNodeClickable(node) { return true }
        for child in node.children { if isNodeClickable(child) { return true } }
        return false
    }

    func keyDown(_ info: AFSceneInput.InputInfo) {
    }
    
    func keyUp(_ info: AFSceneInput.InputInfo) {
    }
    
    func makeEntity(image: NSImage, position: CGPoint) -> AFEntity {
        return AFEntity(scene: gameScene, image: image, position: position)
    }
    
    func makeEntity(prototype: AFEntity_Script) -> AFEntity {
        return AFEntity(scene: gameScene, prototype: prototype)
    }
    
    func makeEntity(copyFrom: AFEntity, position: CGPoint) -> AFEntity {
        return AFEntity(scene: gameScene, copyFrom: copyFrom, position: position)
    }
    
    func makePath(prototype: AFPath_Script) -> AFPath {
        return AFPath(gameScene: gameScene, prototype: prototype)
    }
    
    func mouseDown(_ info: AFSceneInput.InputInfo) {
        downNode = info.node
        currentPosition = info.mousePosition

        if let node = info.node {
            bringToTop(node)
            setNodeToMouseOffset(anchor: node.position)
        }

        mouseState = .down
        upNode = nil
    }
    
    func mouseDrag(_ info: AFSceneInput.InputInfo) {
        mouseState = .dragging
        
        if let node = info.node {
            switch AFNodeAdapter(node).getNodeOwner() {
            case let agent as AFAgent2D: agent.move(to: info.mousePosition)
                
            case let node as AFGraphNode2D:
                node.move(to: info.mousePosition)
                drone.updateDrawIndicator(info.mousePosition + nodeToMouseOffset)
                if let (path, _) = getPathThatOwnsTouchedNode(node.name) {
                    path.refresh()
                } else {
                    activePath?.refresh()
                }

            case let path as AFPath:
                path.move(to: info.mousePosition + nodeToMouseOffset)
            default: break
            }
        }
    }
    
    func mouseMove(_ info: AFSceneInput.InputInfo) {
        drone.mouseMove(to: info.mousePosition)
    }
    
    func mouseUp(_ info: AFSceneInput.InputInfo) {
        upNode = info.node
        currentPosition = info.mousePosition
        
        let nodeName: String? = info.node?.name ?? nil
        drone.click(name: nodeName, flags: info.flags)
        
        mouseState = .up
        downNode = nil
    }

    func place(at point: CGPoint) -> String {
        let imageIndex = AFCore.browserDelegate.agentImageIndex
        let image = ui.agents[imageIndex].image
        let newEntity = data.createEntity(image: image, position: point)
        
        return newEntity.name
    }

    func rightMouseDown(_ info: AFSceneInput.InputInfo) {
        upNode = nil
        mouseState = .rightDown
    }
    
    func rightMouseUp(_ info: AFSceneInput.InputInfo) {
        upNode = info.node
        mouseState = .rightUp
    }
    
    func select(_ index: Int, primary: Bool) {
        drone.select(index, primary: primary)
    }
    
    func select(_ node: SKNode, primary: Bool) {
        drone.select(node, primary: primary)
    }
    
    func setGoalSetupInputMode(_ mode: GoalSetupInputMode) {
        goalSetupInputMode = mode
        enter(GoalSetup.self)
    }

    func setNodeToMouseOffset(anchor: CGPoint) {
        nodeToMouseOffset.x = anchor.x - currentPosition.x
        nodeToMouseOffset.y = anchor.y - currentPosition.y
    }
    
    func showFullPathHandle(_ show: Bool = true) {
        activePath?.showPathHandle(show)
    }
    
    func stampObstacle() {
        let offset = currentPosition - CGPoint(activePath.graphNodes[0].position)
        let newPath = AFPath.init(gameScene: gameScene, copyFrom: activePath, offset: offset)

        newPath.stampObstacle()
        data.obstacles[newPath.name] = newPath
    }

    func toggleSelection(_ node: SKNode) {
        if selectedNodes.contains(node) { drone.deselect(node) }
        else { drone.select(node, primary: primarySelection == nil) }
    }

    func updatePrimarySelectionState(agentNode: SKNode?) {
        let afAgent = AFNodeAdapter(agentNode).getOwningAgent()
        ui.changePrimarySelectionState(selectedAgent: afAgent)
    }
}

extension AFSceneUI {
    struct AFNodeAdapter {
        enum AFUserDataItem { case Clickable, Drawable, NodeOwner, NodeType,
            OwningAgent, PathOwner, Selectable, TheCloneablePart }

        var node: SKNode?
        
        init(_ node: SKNode?) { self.node = node }
        
        func getCloneablePart() -> AFCloneable? { return getUserDataItem(.TheCloneablePart) as? AFCloneable }
        func getIsClickable() -> Bool { return getUserDataItem(.Clickable) as? Bool ?? false }
        func getNodeOwner() -> Any? { return getUserDataItem(.NodeOwner) }
        func getOwningAgent() -> AFAgent2D? { return getUserDataItem(.OwningAgent) as? AFAgent2D }
        func getPathOwner() -> AFPath? { return getUserDataItem(.PathOwner) as? AFPath }
        func getTypeString() -> String? { return getUserDataItem(.NodeType) as? String }
        func getUserDataItem(_ item: AFUserDataItem) -> Any? { return node?.userData?[item] }
        func setIsClickable(_ newValue: Bool) { setUserDataItem(.Clickable, to: newValue) }

        func setupUserData(clickable: Bool? = nil, drawable: Bool? = nil, nodeOwner: Any? = nil,
                           nodeType: String? = nil, owningAgent: AFAgent2D? = nil, pathOwner: AFPath? = nil,
                           selectable: Bool? = nil, theCloneablePart: AFCloneable? = nil)
        {
            if let node = node {
                node.userData = NSMutableDictionary()
                let u = node.userData!
                
                u[AFUserDataItem.Clickable] = clickable ?? false
                u[AFUserDataItem.Drawable] = drawable ?? false
                u[AFUserDataItem.NodeType] = nodeType ?? "<no type specified>"
                u[AFUserDataItem.Selectable] = selectable ?? false

                if let nodeOwner = nodeOwner { u[AFUserDataItem.NodeOwner] = nodeOwner }
                if let owningAgent = owningAgent { u[AFUserDataItem.OwningAgent] = owningAgent }
                if let pathOwner = pathOwner { u[AFUserDataItem.PathOwner] = pathOwner }
                if let theCloneablePart = theCloneablePart { u[AFUserDataItem.TheCloneablePart] = theCloneablePart }
            }
        }
        
        func setUserDataItem(_ item: AFUserDataItem, to value: Any) { node?.userData?[item]? = value }
    }
}

protocol AFCloneable {
    var name: String { get }
    func clone(position: CGPoint) -> AFEntity
}

protocol AFSceneDrone {
    func deselect(_ name: String)
    func deselectAll()
    func finalizePath(close: Bool)
    func getPosition(ofNode name: String) -> CGPoint
    func mouseDown(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?)
    func mouseMove(at position: CGPoint)
    func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?)
    func select(_ node: SKNode, primary: Bool)
    func select(_ imageIndex: Int, primary: Bool)
    func trackMouse(nodeName: String, atPoint: CGPoint)
}
