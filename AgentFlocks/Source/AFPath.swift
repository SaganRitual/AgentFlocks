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

class AFPath_Script: Codable {
    var name: String
//    var graphNodes: AFOrderedMap<String, AFGraphNode2D>
    var radius: Float = 0.0

    init(afPath: AFPath) {
        name = afPath.name
        radius = afPath.radius
//        graphNodes = AFOrderedMap<String, AFGraphNode2D>()
        
//        for (_, graphNode) in afPath.graphNodesByName {
//            let newNode = AFGraphNode2D_Script(gkGraphNode: graphNode)
//            
//            graphNodeNames.append(newNode.name)
//            graphNodesByName[newNode.name] = newNode
//        }
    }
}

class AFGraphNode2D_Script: Codable {
    let position: CGPoint
    
    init(gkGraphNode: GKGraphNode2D) {
        position = CGPoint(x: CGFloat(gkGraphNode.position.x), y: CGFloat(gkGraphNode.position.y))
    }
}

class AFPath: Equatable {
    var containerNode: SKNode?
    var finalized = false
    var gkPath: GKPath!
    let name: String
    var graphNodes: AFOrderedMap<String, AFGraphNode2D>
    var gkObstacle: GKPolygonObstacle!
    var radius: Float = 5.0
    var visualPathSprite: SKShapeNode?
    
    init(obstacle: GKPolygonObstacle? = nil) {
        name = NSUUID().uuidString
        graphNodes = AFOrderedMap<String, AFGraphNode2D>()

        self.gkObstacle = obstacle
    }
    
    init(copyFrom: AFPath, offset: CGPoint? = nil) {
        name = NSUUID().uuidString
        graphNodes = copyFrom.graphNodes
        
        if let offset = offset {
            graphNodes.forEach { node in
                let p = CGPoint(node.position) + offset
                node.position = p.as_vector_float2()
            }
        }
        
        refresh()
    }
    
    init(prototype: AFPath_Script) {
        name = prototype.name
        radius = prototype.radius

        graphNodes = AFOrderedMap<String, AFGraphNode2D>()

//        for node in prototype.graphNodesByName {
//            let afGraphNode = AFGraphNode2D(prototype: node)
//            graphNodes[afGraphNode.name] = afGraphNode
//        }
        
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
        let node = AFGraphNode2D(point: point)
        graphNodes.append(key: node.name, value: node)
        refresh()
        
        return node
    }
    
    func asObstacle() -> GKPolygonObstacle? {
        guard graphNodes.count > 1 else { return nil }

        if gkObstacle == nil {
            var floats = [float2]()
            
            for node in graphNodes {
                floats.append(float2(x: node.position.x, y: node.position.y))
            }
            
            gkObstacle = GKPolygonObstacle(points: floats)
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

    func deselect(_ ix: Int) {
        graphNodes[ix].deselect()
    }
    
    func deselectAll() {
        graphNodes.forEach{ $0.deselect() }
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
            
            let closingNode = AFGraphNode2D(point: visualDotsArray[0], drawable: false)
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
        containerNode!.addChild(visualPathSprite!)
        
        if gkObstacle != nil { visualPathSprite!.fillColor = .gray }

        if let c = containerNode {
            GameScene.me!.addChild(c)
        }
    }
    
    func remove(node: AFGraphNode2D) {
        graphNodes.remove(node.name)
    }
    
    func remove(node: String) {
        graphNodes.remove(node)
    }
    
    func select(_ name: String) {
        graphNodes[name].select(primary: true)
    }
    
    func showNodes(_ show: Bool = false) {
        visualPathSprite?.strokeColor = (show ? .white : NSColor(calibratedWhite: 1, alpha: 0.5))
        graphNodes.forEach{ $0.showNode(show) }
    }
    
    func stampObstacle() {
        _ = self.asObstacle()
        refresh()
    }
}

extension CGPoint {
    func as_vector_float2() -> vector_float2 { return [Float(x), Float(y)] }
    
    static func +=(lhs : inout CGPoint, rhs : CGPoint) { lhs.x += rhs.x; lhs.y += rhs.y }
    static func +(lhs : CGPoint, rhs : CGPoint) -> CGPoint { return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func -(lhs : CGPoint, rhs : CGPoint) -> CGPoint { return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
}
