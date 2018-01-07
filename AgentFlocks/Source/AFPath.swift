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
    var nodesMap: [Int: AFGraphNode2D_Script]
    var radius: Float = 0.0

    init(afPath: AFPath) {
        name = afPath.name
        radius = afPath.radius
        
        nodesMap = [Int: AFGraphNode2D_Script]()
        
        for i in 0 ..< afPath.nodesMap.count {
            nodesMap[i] = AFGraphNode2D_Script(gkGraphNode: afPath.nodesMap[i]!)
        }
    }
}

class AFGraphNode2D_Script: Codable {
    let position: CGPoint
    
    init(gkGraphNode: GKGraphNode2D) {
        position = CGPoint(x: CGFloat(gkGraphNode.position.x), y: CGFloat(gkGraphNode.position.y))
    }
}

class AFPath {
    var containerNode: SKNode?
    var gkPath: GKPath!
    let locked: Bool
    let name: String
    var nodes: Set<AFGraphNode2D>
    var nodesMap: [Int: AFGraphNode2D]
    var obstacle: GKPolygonObstacle?
    var radius: Float = 5.0
    
    init(obstacle: GKPolygonObstacle? = nil) {
        name = NSUUID().uuidString
        nodes = Set<AFGraphNode2D>()
        nodesMap = [Int: AFGraphNode2D]()
        
        // For the built-in corral, we create the node at startup.
        // To get a unique name for it, we have to create an AFPath.
        // But this AFPath doesn't function in any other way. You
        // can't add stuff to it.
        locked = (obstacle != nil)

        self.obstacle = obstacle
    }
    
    init(prototype: AFPath_Script) {
        name = prototype.name
        radius = prototype.radius

        nodes = Set<AFGraphNode2D>()
        nodesMap = [Int: AFGraphNode2D]()

        for i in 0 ..< prototype.nodesMap.count {
            let afGraphNode = AFGraphNode2D(prototype: prototype.nodesMap[i]!)
            nodesMap[i] = afGraphNode
            nodes.insert(afGraphNode)
        }
        
        locked = false

        refresh()
    }
    
    func add(point: CGPoint) {
        let node = AFGraphNode2D(point: point)
        nodes.insert(node)
        nodesMap[nodesMap.count] = node
        refresh()
    }
    
    func makeObstacle() -> GKPolygonObstacle {
        if obstacle == nil {
            var floats = [float2]()
            
            for node in nodes {
                floats.append(float2(x: node.position.x, y: node.position.y))
            }
            
            obstacle = GKPolygonObstacle(points: floats)
        }
        
        return obstacle!
    }
    
    func refresh(final: Bool = false) {
        if let c = containerNode {
            c.removeFromParent()    // Entirely remove the old one
            containerNode = nil
        }

        // GKPath constructor will totally crash the app such
        // that XCode can't catch the error
        guard nodes.count > 1 else { return }

        containerNode = SKNode()

        var nodesArray = [float2]()
        var visualDotsArray = [CGPoint]()
        for i in 0 ..< nodesMap.count {
            let point = CGPoint(x: CGFloat(nodesMap[i]!.position.x), y: CGFloat(nodesMap[i]!.position.y))
            let node = vector_float2(nodesMap[i]!.position.x, nodesMap[i]!.position.y)
            
            nodesArray.append(node)
            visualDotsArray.append(point)
        }
        
        if final {  // To draw from the last point back to the first
            nodesArray.append(nodesArray[0])
            visualDotsArray.append(visualDotsArray[0])
        }

        gkPath = GKPath(points: nodesArray, radius: 1, cyclical: true)
        
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
        
        let sprite = SKShapeNode(path: visualPath)
        containerNode!.addChild(sprite)

        if let c = containerNode {
            GameScene.me!.addChild(c)
        }
    }
    
    func remove(node: AFGraphNode2D) {
        nodes.remove(node)
        refresh()
    }

    func remove(node: SKNode) {
        var minimumDistance = Float.greatestFiniteMagnitude
        var nodeToRemove: AFGraphNode2D?
        
        for candidate in nodes {
            let x2 = pow(candidate.position.x - Float(node.position.x), 2)
            let y2 = pow(candidate.position.y - Float(node.position.y), 2)
            let distance = sqrt(x2 + y2)
            
            if distance < minimumDistance {
                minimumDistance = distance
                nodeToRemove = candidate
            }
        }
        
        if let thisOne = nodeToRemove {
            nodes.remove(thisOne)
            refresh()
        }
    }
}

class AFGraphNode2D: GKGraphNode2D {
    init(point: CGPoint) {
        super.init(point: vector_float2(Float(point.x), Float(point.y)))
    }
    
    init(prototype: AFGraphNode2D_Script) {
        super.init(point: vector_float2(Float(prototype.position.x), Float(prototype.position.y)))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
