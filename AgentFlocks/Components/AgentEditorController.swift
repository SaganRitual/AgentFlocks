//
//  AgentEditorController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 21/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

class AgentEditorController: NSViewController {
	
	// MARK: - Attributes (public)
	
	let attributesController = AgentAttributesController()
	let goalsController = AgentGoalsController()
	
	// MARK: - Attributes (private)
	
	@IBOutlet private weak var attributesBox: NSBox!
	@IBOutlet private weak var goalsBox: NSBox!
	
	// MARK: - Initialization
	
	init() {
		super.init(nibName: NSNib.Name(rawValue: "AgentEditorView"), bundle: nil)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		attributesBox.addSubview(attributesController.view)
		attributesController.view.translatesAutoresizingMaskIntoConstraints = false
		
		goalsBox.addSubview(goalsController.view)
		goalsController.view.translatesAutoresizingMaskIntoConstraints = false

		let viewsDict = [ "attributesView": attributesController.view,
		                  "goalsView": goalsController.view ]
		var constraints = [NSLayoutConstraint]()
		constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0.0-[attributesView]-0.0-|", options: .init(rawValue: 0), metrics: nil, views: viewsDict))
		constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0.0-[attributesView]-0.0-|", options: .init(rawValue: 0), metrics: nil, views: viewsDict))
		constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0.0-[goalsView]-0.0-|", options: .init(rawValue: 0), metrics: nil, views: viewsDict))
		constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0.0-[goalsView]-0.0-|", options: .init(rawValue: 0), metrics: nil, views: viewsDict))
		NSLayoutConstraint.activate(constraints)
    }
	
	func refresh() {
		goalsController.refresh()
	}
	
	func selectedIndex() -> Int {
		return goalsController.selectedIndex()
	}
	
}
