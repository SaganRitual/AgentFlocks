//
// Created by Rob Bishop on 1/4/18
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

class AFObstacle_Script: Codable, Equatable {
    var name: String
    
    init(afPath: AFPath) {
        self.name = afPath.name
    }

    static func ==(lhs: AFObstacle_Script, rhs: AFObstacle_Script) -> Bool {
        return lhs.name == rhs.name
    }
}

class AFObstacle {
    var name: String
    
    init(prototype: AFObstacle_Script) {
        self.name = prototype.name
    }
}

class AFPath_Script: Codable, Equatable {
    var name: String
    var graphNodes: AFOrderedMap_Script<String, AFGraphNode2D_Script>
    var radius: Float

    init(afPath: AFPath) {
        name = afPath.name
        radius = afPath.radius
        graphNodes = AFOrderedMap_Script<String, AFGraphNode2D_Script>()
        
        for afGraphNode in afPath.graphNodes {
            let newNode = AFGraphNode2D_Script(afGraphNode: afGraphNode)
            graphNodes.append(key: newNode.name, value: newNode)
        }
    }

    static func ==(lhs: AFPath_Script, rhs: AFPath_Script) -> Bool {
        return lhs.name == rhs.name
    }
}

class AFPath: Equatable {
    var containerNode: SKNode?
    var finalized = false
    let gameScene: GameScene
    var gkPath: GKPath!
    var graphNodes: AFOrderedMap<String, AFGraphNode2D>
    var gkObstacle: GKPolygonObstacle!
    let name: String
    var radius: Float = 5.0
    var visualPathSprite: SKShapeNode?
    
    init(gameScene: GameScene, obstacle: GKPolygonObstacle? = nil) {
        self.gameScene = gameScene
        graphNodes = AFOrderedMap<String, AFGraphNode2D>()
        name = NSUUID().uuidString

        self.gkObstacle = obstacle
    }
    
    init(gameScene: GameScene, copyFrom: AFPath, offset: CGPoint? = nil) {
        self.gameScene = gameScene
        graphNodes = AFOrderedMap<String, AFGraphNode2D>()
        name = NSUUID().uuidString

        copyFrom.graphNodes.forEach {
            let newNode = AFGraphNode2D(copyFrom: $0, gameScene: gameScene, drawable: false)
            graphNodes.append(key: newNode.name, value: newNode)
        }
        
        if let offset = offset {
            graphNodes.forEach { 
                let p = CGPoint($0.position) + offset
                $0.position = p.as_vector_float2()
            }
        }
        
        refresh(final: true)
    }
    
    init(gameScene: GameScene, prototype: AFPath_Script) {
        self.gameScene = gameScene
        name = prototype.name
        radius = prototype.radius

        graphNodes = AFOrderedMap<String, AFGraphNode2D>()

        for protoNode in prototype.graphNodes {
            let afGraphNode = AFGraphNode2D(prototype: protoNode, gameScene: gameScene)
            graphNodes.append(key: afGraphNode.name, value: afGraphNode)
        }
        
        // Force the new path to rebuild its internal stuff
        finalized = false
        refresh()
    }
    
    deinit {
        visualPathSprite?.removeFromParent()
        containerNode?.removeFromParent()
    }

    static func ==(lhs: AFPath, rhs: AFPath) -> Bool {
        return lhs.name == rhs.name
    }

    func addGraphNode(at point: CGPoint) -> AFGraphNode2D {
        let node = AFGraphNode2D(point: point, gameScene: gameScene)
        graphNodes.append(key: node.name, value: node)
        refresh()
        
        return node
    }
    
    func asObstacle() -> GKPolygonObstacle? {
        guard graphNodes.count > 1 else { return nil }

        if gkObstacle == nil || gkObstacle != nil {
            var floats = [float2]()
            
            for node in graphNodes {
                floats.append(float2(x: node.position.x, y: node.position.y))
            }
            
            gkObstacle = GKPolygonObstacle(points: floats)
            
            let obs = SKNode.obstacles(fromNodeBounds: [visualPathSprite!])
            gkObstacle = obs[0]
        }
        
        return gkObstacle
    }
    
    func asPath() -> GKPath? {
        guard graphNodes.count > 1 else { return nil }
        
        if gkPath == nil {
            var floats = [float2]()
            
            for node in graphNodes {
                floats.append(float2(x: node.position.x, y: node.position.y))
            }
            
            gkPath = GKPath(points: floats, radius: radius, cyclical: true)
        }
        
        return gkPath
    }

    func deselect(_ ix: Int? = nil) {
        if let ix = ix {
            graphNodes[ix].deselect()
        } else {
            visualPathSprite?.strokeColor = .white
        }
    }
    
    func deselectAll() {
        graphNodes.forEach{ $0.deselect() }
        AFCore.data.obstacles.forEach{ $1.deselect() }
    }
    
    func getImageData(size: CGSize) -> NSImage {
        let texture = gameScene.view!.texture(from: visualPathSprite!)!
        let cgImage = texture.cgImage()
        let nsImage = NSImage(cgImage: cgImage, size: size)
        
        return nsImage
    }
    
    func moveNode(node: String, to point: CGPoint) {
        let x = Float(point.x)
        let y = Float(point.y)
        graphNodes[node].position = [x, y]

        refresh()
    }

    func refresh(final: Bool = false) {
        if let c = containerNode {
            c.removeFromParent()    // Entirely remove the old one
            containerNode = nil
        }

        // GKPath constructor will totally crash the app such
        // that XCode can't catch the error
        guard graphNodes.count > 1 else { return }

        containerNode = SKNode()
        containerNode!.name = self.name
        containerNode!.userData = NSMutableDictionary()
        containerNode!.userData!["type"] = "pathContainer"

        var nodesArray = [float2]()
        var visualDotsArray = [CGPoint]()
        
        for node in graphNodes {
            let cgPoint = CGPoint(x: CGFloat(node.position.x), y: CGFloat(node.position.y))
            let float2Point = vector_float2(node.position.x, node.position.y)
            
            nodesArray.append(float2Point)
            visualDotsArray.append(cgPoint)
        }
        
        if self.finalized {
            // If we've already closed the path, we need to keep
            // the last (dummy) point in sync with the first, so the lines
            // will draw properly
            let last = visualDotsArray.count - 1
            visualDotsArray[last] = visualDotsArray[0]
        }
        
        if final && !self.finalized {  // To draw from the last point back to the first
            nodesArray.append(nodesArray[0])
            visualDotsArray.append(visualDotsArray[0])
            
            let closingNode = AFGraphNode2D(point: visualDotsArray[0], gameScene: gameScene, drawable: false)
            graphNodes.append(key: closingNode.name, value: closingNode)
            
            self.finalized = true
        }

        gkPath = GKPath(points: nodesArray, radius: 1, cyclical: true)
        
        // If we have an obstacle, we need to blow it away and
        // replace it with one that reflects the latest path
        if gkObstacle != nil { _ = asObstacle() }
        
        var startPoint: CGPoint!
        let visualPath = CGMutablePath()
        for dot in visualDotsArray {
            let point = CGPoint(x: CGFloat(dot.x), y: CGFloat(dot.y))
            if startPoint == nil {
                startPoint = point
                visualPath.move(to: point)
            } else {
                visualPath.addLine(to: point)
            }
        }
        
        visualPathSprite = SKShapeNode(path: visualPath)
        visualPathSprite!.name = name
        visualPathSprite!.userData = NSMutableDictionary()
        visualPathSprite!.userData!["selectable"] = false
        containerNode!.addChild(visualPathSprite!)
        
        if !finalized { visualPathSprite!.strokeColor = .red }
        if gkObstacle != nil { visualPathSprite!.fillColor = .gray }

        if let c = containerNode { gameScene.addChild(c) }
    }
    
    func remove(node: AFGraphNode2D) {
        graphNodes.remove(node.name)
    }
    
    func remove(node: String) {
        graphNodes.remove(node)
    }
    
    func select(_ name: String) {
        if let ix = graphNodes.getIndexOf(name) {
            graphNodes[ix].select(primary: true)
        } else {
            AFCore.data.obstacles[name]!.visualPathSprite?.strokeColor = .green
        }
    }
    
    func showNodes(_ show: Bool = false) {
        visualPathSprite?.strokeColor = (show ? .white : NSColor(calibratedWhite: 1, alpha: 0.5))
        
        let reallyShow = (gkObstacle == nil) ? show : false
        graphNodes.forEach{ $0.showNode(reallyShow) }
    }
    
    func stampObstacle() {
        _ = self.asObstacle()
        refresh(final: true)
    }
}

extension CGPoint {
    func as_vector_float2() -> vector_float2 { return [Float(x), Float(y)] }
    
    static func +=(lhs : inout CGPoint, rhs : CGPoint) { lhs.x += rhs.x; lhs.y += rhs.y }
    static func +(lhs : CGPoint, rhs : CGPoint) -> CGPoint { return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func -(lhs : CGPoint, rhs : CGPoint) -> CGPoint { return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
}
