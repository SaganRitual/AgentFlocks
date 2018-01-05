//
//  PreferencesController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 05/01/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

class PreferencesController: NSWindowController {
	
	// This property is used bor binding window components
	// with configuration singleton. Because of this it
	// must be KVC-compliant which is achieved by "@objc dynamic"
	@objc dynamic let configuration = Configuration.shared
	
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
	@IBAction func closseButtonClicked(_ sender: NSButton) {
		if let window = self.window {
			if let parentWindow = window.sheetParent
			{
				// If window is displayed as a modal sheet, close this sheet
				parentWindow.endSheet(window)
			}
			else {
				// Otherwise this is a normal window, just close it
				window.performClose(self)
			}
		}
	}
	
}
