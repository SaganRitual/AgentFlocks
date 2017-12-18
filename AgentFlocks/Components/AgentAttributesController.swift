//
//  AgentAttributesController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 19/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

protocol AgentAttributesDelegate {
	func agent(_ controller: AgentAttributesController, newValue value:Double, ofAttribute:AgentAttributesController.Attribute)
	func agent(_ controller: AgentAttributesController, newMaxValue maxValue:Double, ofAttribute:AgentAttributesController.Attribute)
}

class AgentAttributesController: NSViewController {
	
	enum Attribute {
		case Speed
		case Mass
	}
	
	// MARK: - Attributes (public)
	
	var speed:Double {
		get {
			return speedSliderController.value
		}
		set {
			speedSliderController.value = newValue
		}
	}
	var maxSpeed:Double {
		get {
			return speedSliderController.maxValue
		}
		set {
			speedSliderController.maxValue = newValue
		}
	}
	var mass:Double {
		get {
			return massSliderController.value
		}
		set {
			massSliderController.value = newValue
		}
	}
	var maxMass:Double {
		get {
			return massSliderController.maxValue
		}
		set {
			massSliderController.maxValue = newValue
		}
	}

	var delegate:AgentAttributesDelegate?
	
	// MARK: - Attributes (private)
	
	@IBOutlet private weak var speedSliderContainer: NSView!
	@IBOutlet private weak var massSliderContainer: NSView!
	
	private let speedSliderController = SliderController()
	private let massSliderController = SliderController()
	
	// MARK: - Initialization
	
	init() {
		super.init(nibName: NSNib.Name(rawValue: "AgentAttributesView"), bundle: nil)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		speedSliderController.sliderName = "Speed"
		massSliderController.sliderName = "Mass"
		
        speedSliderController.addToView(speedSliderContainer)
		massSliderController.addToView(massSliderContainer)
    }
    
}

// MARK: -

extension AgentAttributesController: SliderDelegate {
	
	func slider(_ controller: SliderController, newValue value: Double) {
		switch controller {
		case speedSliderController:
			delegate?.agent(self, newValue: value, ofAttribute: .Speed)
		case massSliderController:
			delegate?.agent(self, newValue: value, ofAttribute: .Mass)
		default:
			return
		}
	}
	
	func slider(_ controller: SliderController, newMaxValue maxValue: Double) {
		switch controller {
		case speedSliderController:
			delegate?.agent(self, newMaxValue: maxValue, ofAttribute: .Speed)
		case massSliderController:
			delegate?.agent(self, newMaxValue: maxValue, ofAttribute: .Mass)
		default:
			return
		}
	}
	
}
