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
        let info = AFSceneInput.InputInfo(flags: event.modifierFlags, key: event.keyCode, mousePosition: CGPoint.zero)
        AFCore.sceneUI.keyDown(info)
	}
	
	override func keyUp(with event: NSEvent) {
        let info = AFSceneInput.InputInfo(flags: event.modifierFlags, key: event.keyCode, mousePosition: CGPoint.zero)
        AFCore.sceneUI.keyUp(info)
	}
	
}
