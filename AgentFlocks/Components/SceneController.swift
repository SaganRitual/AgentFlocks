//
//  SceneController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 01/11/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa
import GameplayKit
import SpriteKit

protocol SceneDelegate {
//	func sceneView(_ controller: SceneController)
}

class SceneController: NSViewController {
	
	// MARK: - Attributes (public)
	
    var sceneNode: GameScene!
    var scene: GKScene!
	
	// MARK: - Attributes (private)
	
	private var nodes = [SKSpriteNode]()
	private var draggedNodeIndex:Int?
    private var draggedNodeMouseOffset = CGPoint.zero
	
	// MARK: - Initialization
	
	init() {
		super.init(nibName: NSNib.Name(rawValue: "SceneView"), bundle: nil)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = GKScene(fileNamed: "GameScene")
        sceneNode = scene.rootNode as! GameScene?
		
		if let sceneView = view as? SKView {
			// Add SpriteKit root node to sceneView (SKView)
			sceneNode.size = view.bounds.size
			sceneView.presentScene(sceneNode)
			
			// Sprite Kit applies additional optimizations to improve rendering performance
			sceneView.ignoresSiblingOrder = true
			
			sceneView.showsFPS = true
			sceneView.showsNodeCount = true
		}
    }
	
	override func viewDidLayout() {
		sceneNode.size = view.frame.size
	}
	
	// MARK: - Public methods
	
	func addNode(image: NSImage) {
        let entity = AFEntity(scene: sceneNode, position: CGPoint.zero)
        sceneNode.entities.append(entity)

//        let sprite = SKSpriteNode(texture: SKTexture(image: image))
//        sprite.anchorPoint = NSMakePoint(0.5, 0.5)
//        sceneNode.addChild(sprite)
//        nodes.append(sprite)
	}
	
	// MARK: - Mouse handling

	override func mouseDown(with event: NSEvent) {
		let location = event.location(in: sceneNode)
        let touchedNodes = sceneNode.nodes(at: location)
        
        for (index, entity_) in sceneNode.entities.enumerated() {
            let entity = entity_ as! AFEntity
            if touchedNodes.contains(entity.agent.spriteContainer) {
                draggedNodeIndex = index
                sceneNode.draggedNodeIndex = index
                
                let e = event.location(in: sceneNode)

                draggedNodeMouseOffset.x = entity.agent.spriteContainer.position.x - e.x
                draggedNodeMouseOffset.y = entity.agent.spriteContainer.position.y - e.y
                break
            }
        }
	}
	
	override func mouseUp(with event: NSEvent) {
        if let draggedIndex = draggedNodeIndex {
            if let entity = sceneNode.entities[draggedIndex] as? AFEntity {
                let c = entity.agent
                let p = event.location(in: sceneNode)
                c.position = vector_float2(Float(p.x), Float(p.y))
                c.position.x += Float(draggedNodeMouseOffset.x)
                c.position.y += Float(draggedNodeMouseOffset.y)
            }
        }
        
		draggedNodeIndex = nil
        sceneNode.draggedNodeIndex = nil
        draggedNodeMouseOffset = CGPoint.zero
	}
	
	override func mouseDragged(with event: NSEvent) {
		if let draggedIndex = draggedNodeIndex {
            if let entity = sceneNode.entities[draggedIndex] as? AFEntity {
                let c = entity.agent.spriteContainer
                c.position = event.location(in: sceneNode)
                c.position.x += draggedNodeMouseOffset.x
                c.position.y += draggedNodeMouseOffset.y
            }
		}
	}
	
}

extension SKView {
	
	override open func mouseDown(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(mouseDown(with:))) {
				delegate.perform(#selector(mouseDown(with:)), with: event)
			}
		}
	}
	
	override open func mouseUp(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(mouseUp(with:))) {
				delegate.perform(#selector(mouseUp(with:)), with: event)
			}
		}
	}
	
	override open func mouseMoved(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(mouseMoved(with:))) {
				delegate.perform(#selector(mouseMoved(with:)), with: event)
			}
		}
	}
	
	override open func mouseExited(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(mouseExited(with:))) {
				delegate.perform(#selector(mouseExited(with:)), with: event)
			}
		}
	}
	
	override open func mouseDragged(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(mouseDragged(with:))) {
				delegate.perform(#selector(mouseDragged(with:)), with: event)
			}
		}
	}
	
	override open func mouseEntered(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(mouseEntered(with:))) {
				delegate.perform(#selector(mouseEntered(with:)), with: event)
			}
		}
	}
	
	override open func otherMouseUp(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(otherMouseUp(with:))) {
				delegate.perform(#selector(otherMouseUp(with:)), with: event)
			}
		}
	}
	
	override open func otherMouseDown(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(otherMouseDown(with:))) {
				delegate.perform(#selector(otherMouseDown(with:)), with: event)
			}
		}
	}
	
	override open func otherMouseDragged(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(otherMouseDragged(with:))) {
				delegate.perform(#selector(otherMouseDragged(with:)), with: event)
			}
		}
	}
	
	override open func rightMouseUp(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(rightMouseUp(with:))) {
				delegate.perform(#selector(rightMouseUp(with:)), with: event)
			}
		}
	}
	
	override open func rightMouseDown(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(rightMouseDown(with:))) {
				delegate.perform(#selector(rightMouseDown(with:)), with: event)
			}
		}
	}
	
	override open func rightMouseDragged(with event: NSEvent) {
		if let delegate = self.delegate {
			if delegate.responds(to: #selector(rightMouseDragged(with:))) {
				delegate.perform(#selector(rightMouseDragged(with:)), with: event)
			}
		}
	}
	
}
