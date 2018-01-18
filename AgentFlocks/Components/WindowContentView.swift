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
	
    // I'm not sure these functions ever get called
	override func keyDown(with event: NSEvent) {
        AFCore.sceneUI.keyDown(mouseAt: CGPoint.zero)
	}
	
	override func keyUp(with event: NSEvent) {
        AFCore.sceneUI.keyUp(mouseAt: CGPoint.zero)
	}
	
}
