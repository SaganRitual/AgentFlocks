//
//  WindowContentView.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 11/01/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

class WindowContentView: NSView {
	
	override var acceptsFirstResponder: Bool {
		get {
			return true
		}
	}
	
	override func keyDown(with event: NSEvent) {
		GameScene.me!.keyDown(with: event)
	}
	
	override func keyUp(with event: NSEvent) {
		GameScene.me!.keyUp(with: event)
	}
	
}
