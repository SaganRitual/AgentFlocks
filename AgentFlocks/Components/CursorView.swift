//
//  CursorView.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 09/01/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

class CursorView: NSView {
	
	var cursor:NSCursor = .arrow {
		didSet {
			resetCursorRects()
		}
	}
	
	override func resetCursorRects() {
		super.resetCursorRects()
		self.addCursorRect(self.bounds, cursor: cursor)
	}
	
}
