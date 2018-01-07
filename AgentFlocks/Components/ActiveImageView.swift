//
//  ActiveImageView.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 06/01/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

protocol ActiveImageViewDelegate {
	func imageView(mouseUpWithEvent event: NSEvent)
}

class ActiveImageView: NSImageView {
	
	var delegate:ActiveImageViewDelegate?
	
	override func mouseUp(with event: NSEvent) {
		delegate?.imageView(mouseUpWithEvent: event)
	}
	
	override func resetCursorRects() {
		self.addCursorRect(self.bounds, cursor: NSCursor.pointingHand)
	}
	
}
