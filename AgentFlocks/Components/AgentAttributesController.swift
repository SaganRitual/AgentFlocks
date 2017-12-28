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
}

class AgentAttributesController: NSViewController {
	
	enum Attribute { case mass, maxAcceleration, maxSpeed, radius, scale }
	
	// MARK: - Attributes (public)
	
    var mass:Double {
        get {
            return massSliderController.value
        }
        set {
            massSliderController.value = newValue
        }
    }
    var maxAcceleration:Double {
        get {
            return maxAccelerationSliderController.value
        }
        set {
            maxAccelerationSliderController.value = newValue
        }
    }
    var maxSpeed:Double {
        get {
            return maxSpeedSliderController.value
        }
        set {
            maxSpeedSliderController.value = newValue
        }
    }
    var radius:Double {
        get {
            return radiusSliderController.value
        }
        set {
            radiusSliderController.value = newValue
        }
    }
	var scale:Double {
		get {
			return scaleSliderController.value
		}
		set {
			scaleSliderController.value = newValue
		}
	}

	var delegate:AgentAttributesDelegate?
	
	// MARK: - Attributes (private)
	
	@IBOutlet private weak var massSliderContainer: NSView!
    @IBOutlet private weak var maxAccelerationSliderContainer: NSView!
    @IBOutlet private weak var maxSpeedSliderContainer: NSView!
    @IBOutlet private weak var radiusSliderContainer: NSView!
    @IBOutlet private weak var scaleSliderContainer: NSView!

	private let massSliderController = SliderController()
    private let maxAccelerationSliderController = SliderController()
    private let maxSpeedSliderController = SliderController()
    private let radiusSliderController = SliderController()
    private let scaleSliderController = SliderController()

	// MARK: - Initialization
	
	init() {
		super.init(nibName: NSNib.Name(rawValue: "AgentAttributesView"), bundle: nil)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        typealias AttributeSet = (ainer: NSView?, roller: SliderController, label: String, max: Double, increment: Double)
        let attributeSets: [AttributeSet] = [
            (massSliderContainer, massSliderController, "Mass", 1.0, 0.001),
            (maxAccelerationSliderContainer, maxAccelerationSliderController, "Max Accel", 1000.0, 1.0),
            (maxSpeedSliderContainer, maxSpeedSliderController, "Max Speed", 1000.0, 1.0),
            (radiusSliderContainer, radiusSliderController, "Radius", 100, 0.1),
            (scaleSliderContainer, scaleSliderController, "Scale", 10.0, 0.01)
        ]
        
        for s in attributeSets {
            s.roller.sliderName = s.label
            s.roller.addToView(s.ainer!)
            s.roller.delegate = self
            s.roller.minValue = 0
            s.roller.maxValue = s.max
            s.roller.incrementValue = s.increment
        }
    }
    
}

// MARK: -

extension AgentAttributesController: SliderDelegate {
	
	func slider(_ controller: SliderController, newValue value: Double) {
		switch controller {
        case massSliderController:
            delegate?.agent(self, newValue: value, ofAttribute: .mass)
        case maxAccelerationSliderController:
            delegate?.agent(self, newValue: value, ofAttribute: .maxAcceleration)
        case maxSpeedSliderController:
            delegate?.agent(self, newValue: value, ofAttribute: .maxSpeed)
        case radiusSliderController:
            delegate?.agent(self, newValue: value, ofAttribute: .radius)
		case scaleSliderController:
			delegate?.agent(self, newValue: value, ofAttribute: .scale)
		default:
			return
		}
	}
	
}

