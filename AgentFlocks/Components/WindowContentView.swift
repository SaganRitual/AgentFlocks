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
    
    override func flagsChanged(with event: NSEvent) {
        AFCore.sceneUI.flagsChanged(to: event.modifierFlags)
    }
	
	override func keyDown(with event: NSEvent) {
        AFCore.sceneUI.keyDown(event.keyCode, mouseAt: CGPoint.zero, flags: event.modifierFlags)
	}
	
	override func keyUp(with event: NSEvent) {
        AFCore.sceneUI.keyUp(event.keyCode, mouseAt: CGPoint.zero, flags: event.modifierFlags)
	}
	
}
