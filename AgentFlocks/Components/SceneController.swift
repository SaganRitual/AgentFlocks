//
//  SceneController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 01/11/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa
import SpriteKit

protocol SceneDelegate {
//	func sceneView(_ controller: SceneController)
}

class SceneController: NSViewController {
	
	// MARK: - Attributes (public)
	
	let scene = SKScene()
	
	// MARK: - Attributes (private)
	
	private var nodes = [SKSpriteNode]()
	private var draggedNodeIndex:Int?
	
	// MARK: - Initialization
	
	init() {
		super.init(nibName: NSNib.Name(rawValue: "SceneView"), bundle: nil)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		scene.backgroundColor = NSColor(red:0.93, green:0.93, blue:0.93, alpha:1.00)
		
		if let sceneView = view as? SKView {
			// Add SpriteKit scene to sceneView (SKView)
			scene.size = view.bounds.size
			sceneView.presentScene(scene)
			
			// Sprite Kit applies additional optimizations to improve rendering performance
			sceneView.ignoresSiblingOrder = true
			
			sceneView.showsFPS = true
			sceneView.showsNodeCount = true
		}
    }
	
	override func viewDidLayout() {
		scene.size = view.frame.size
	}
	
	// MARK: - Public methods
	
	func addNode(image: NSImage) {
		let sprite = SKSpriteNode(texture: SKTexture(image: image))
		sprite.anchorPoint = NSMakePoint(0.5, 0.5)
		sprite.position = NSMakePoint(scene.size.width/2, scene.size.height/2)
		scene.addChild(sprite)
		nodes.append(sprite)
	}
	
	// MARK: - Mouse handling

	override func mouseDown(with event: NSEvent) {
		let location = event.location(in: scene)
		let touchedNodes = scene.nodes(at: location)
		for (index, node) in nodes.enumerated() {
			if touchedNodes.contains(node) {
				draggedNodeIndex = index
				break
			}
		}
	}
	
	override func mouseUp(with event: NSEvent) {
		draggedNodeIndex = nil
	}
	
	override func mouseDragged(with event: NSEvent) {
		if let draggedIndex = draggedNodeIndex {
			nodes[draggedIndex].position = event.location(in: scene)
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
