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

class AFSceneUI: GKStateMachine {
    var activePath: AFPath!     // The one we're doing stuff to, whether it's selected or not (like dragging handles)
    let contextMenu: AFContextMenu
    var currentPosition = CGPoint.zero
    var data: AFData!
    var downNodeName: String?
    var goalSetupInputMode = GoalSetupInputMode.NoSelect
    var mouseState = MouseStates.up
    var nodeToMouseOffset = CGPoint.zero
    var obstacleCloneStamp = String()
    var parentOfNewMotivator: AFBehavior?
    var pathForNextPathGoal = 0
    var primarySelection: String?
    unowned let gameScene: GameScene
    var selectedNames = Set<String>()
    var selectedPath: AFPath!   // The one that has a visible selection indicator on it, if any
    var ui: AppDelegate
    var upNodeName: String?

    enum MouseStates { case down, dragging, rightDown, rightUp, up }

    init(gameScene: GameScene, ui: AppDelegate, contextMenu: AFContextMenu) {
        self.contextMenu = contextMenu
        self.gameScene = gameScene
        self.ui = ui

        super.init(states: [
            Draw(sceneUI: self), Default(sceneUI: self), GoalSetup(sceneUI: self)
        ])
        
        enter(Default.self)
    }
    
    func addNodeToPath(at position: CGPoint) {
        let newNode = activePath.addGraphNode(at: position)
        select(newNode.name, primary: true)
        
        // With two or more nodes, we now have a path that can be
        // added to the library
        if activePath.graphNodes.count > 1 {
            contextMenu.enableInDisplay(.AddPathToLibrary)
        }
    }

    func bringToTop(_ node: SKNode) {
        if let userData = node.userData, let pathOwner = userData["pathOwner"] as? AFPath {
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
                var typeString = "<type unknown>"
                if let userData = $0.userData, let type = userData["nodeType"] as? String {
                    typeString = type
                }
                for _ in 0 ..< tabCount { print("\t", separator: "", terminator: "") }
                print($0.zPosition, typeString, $0.name ?? "<no name>")
                
                dumpChildren(of: $0, tabCount: tabCount + 1)
            }
        }
    }
    
    func cloneAgent() {
        guard let originalName = primarySelection else { return }

        let originalEntity = data.entities[originalName]!
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
            let agentName = primarySelection!
            let entity = data.entities[agentName]!
            return (entity.agent.behavior! as! GKCompositeBehavior)[0] as! AFBehavior
        }
    }
    
    func isNodeClickable(_ node: SKNode) -> Bool {
        if let userData = node.userData, let clickable = userData["clickable"] as? Bool, clickable == true {
            return true
        } else {
            return false
        }
    }
    
    // meaning is there any descendant of this node that is clickable. If there
    // is, count the branch -- namely the top node -- as clickable.
    func isNodeBranchClickable(_ node: SKNode) -> Bool {
        if isNodeClickable(node) { return true }
        for child in node.children { if isNodeClickable(child) { return true } }
        return false
    }

    func keyDown(_ key: UInt16, mouseAt: CGPoint, flags: NSEvent.ModifierFlags?) {
    }
    
    func keyUp(_ key: UInt16, mouseAt: CGPoint, flags: NSEvent.ModifierFlags?) {
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
    
    func mouseDown(on node: SKNode?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
        downNodeName = node?.name
        currentPosition = position

        if let node = node {
            bringToTop(node)
            setNodeToMouseOffset(anchor: node.position)
        }

        mouseState = .down
        upNodeName = nil
    }
    
    func mouseDrag(on node: SKNode?, at position: CGPoint) {
        mouseState = .dragging
        
        if let node = node, let userData = node.userData {
            switch userData["nodeOwner"] {
            case let agent as AFAgent2D: agent.move(to: position)
                
            case let node as AFGraphNode2D:
                node.move(to: position)
                drone.updateDrawIndicator(position + nodeToMouseOffset)
                if let (path, _) = getPathThatOwnsTouchedNode(node.name) {
                    path.refresh()
                } else {
                    activePath?.refresh()
                }

            case let path as AFPath:
                path.move(to: position + nodeToMouseOffset)
            default: break
            }
        }
    }
    
    func mouseMove(at position: CGPoint) {
        drone.mouseMove(to: position)
    }
    
    func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?) {
        upNodeName = node
        currentPosition = position
        
        drone.click(name: node, flags: flags)
        
        mouseState = .up
        downNodeName = nil
    }

    func place(at point: CGPoint) -> String {
        let imageIndex = AFCore.browserDelegate.agentImageIndex
        let image = ui.agents[imageIndex].image
        let newEntity = data.createEntity(image: image, position: point)
        
        return newEntity.name
    }

    func rightMouseDown(on node: String?) {
        upNodeName = nil
        mouseState = .rightDown
    }
    
    func rightMouseUp(on node: String?) {
        upNodeName = node
        mouseState = .rightUp
    }
    
    func select(_ index: Int, primary: Bool) {
        drone.select(index, primary: primary)
    }
    
    func select(_ name: String, primary: Bool) {
        drone.select(name, primary: primary)
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

    func toggleSelection(_ name: String) {
        if selectedNames.contains(name) { drone.deselect(name) }
        else { drone.select(name, primary: primarySelection == nil) }
    }

    func updatePrimarySelectionState(agentName: String?) {
        var agent: AFAgent2D?
        
        if let agentName = agentName {
            agent = data.entities[agentName]!.agent
        }
        
        ui.changePrimarySelectionState(selectedAgent: agent)
    }
}

protocol AFSceneDrone {
    func deselect(_ name: String)
    func deselectAll()
    func finalizePath(close: Bool)
    func getPosition(ofNode name: String) -> CGPoint
    func mouseDown(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?)
    func mouseMove(at position: CGPoint)
    func mouseUp(on node: String?, at position: CGPoint, flags: NSEvent.ModifierFlags?)
    func select(_ name: String, primary: Bool)
    func select(_ imageIndex: Int, primary: Bool)
    func trackMouse(nodeName: String, atPoint: CGPoint)
}
