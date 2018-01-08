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

	var defaultMass:Double {
		get {
			return massDefaultEntry.doubleValue
		}
		set {
			massDefaultEntry.stringValue = String(newValue)
		}
	}
	var defaultMaxAcceleration:Double {
		get {
			return maxAccelerationDefulatEntry.doubleValue
		}
		set {
			maxAccelerationDefulatEntry.stringValue = String(newValue)
		}
	}
	var defaultMaxSpeed:Double {
		get {
			return maxSpeedDefaultEntry.doubleValue
		}
		set {
			maxSpeedDefaultEntry.stringValue = String(newValue)
		}
	}
	var defaultRadius:Double {
		get {
			return radiusDefaultEntry.doubleValue
		}
		set {
			radiusDefaultEntry.stringValue = String(newValue)
		}
	}
	var defaultScale:Double {
		get {
			return scaleDefaultEntry.doubleValue
		}
		set {
			scaleDefaultEntry.stringValue = String(newValue)
		}
	}
	
	var delegate:AgentAttributesDelegate?
	
	// MARK: - Attributes (private)
	
	@IBOutlet private weak var massSliderContainer: NSView!
	@IBOutlet private weak var maxSpeedSliderContainer: NSView!
    @IBOutlet private weak var maxAccelerationSliderContainer: NSView!
    @IBOutlet private weak var radiusSliderContainer: NSView!
    @IBOutlet private weak var scaleSliderContainer: NSView!
	
	@IBOutlet weak var massDefaultEntry: NSTextField!
	@IBOutlet weak var maxSpeedDefaultEntry: NSTextField!
	@IBOutlet weak var maxAccelerationDefulatEntry: NSTextField!
	@IBOutlet weak var radiusDefaultEntry: NSTextField!
	@IBOutlet weak var scaleDefaultEntry: NSTextField!
	
	private let massSliderController = LogSliderController()
	private let maxSpeedSliderController = LogSliderController()
    private let maxAccelerationSliderController = LogSliderController()
    private let radiusSliderController = LogSliderController()
    private let scaleSliderController = LogSliderController()

	// MARK: - Initialization
	
	init() {
		super.init(nibName: NSNib.Name(rawValue: "AgentAttributesView"), bundle: nil)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        typealias AttributeSet = (container: NSView?, roller: LogSliderController, label: String, value: Double)
        let attributeSets: [AttributeSet] = [
            (massSliderContainer, massSliderController, "Mass", 1),
            (maxAccelerationSliderContainer, maxAccelerationSliderController, "Max Accel", 100),
            (maxSpeedSliderContainer, maxSpeedSliderController, "Max Speed", 100),
            (radiusSliderContainer, radiusSliderController, "Radius", 100),
            (scaleSliderContainer, scaleSliderController, "Scale", 1)
        ]
        
        for s in attributeSets {
            s.roller.sliderName = s.label
            s.roller.delegate = self
            s.roller.value = s.value
			s.roller.addToView(s.container!)
        }
    }
	
	override func viewWillAppear() {
		makeDefaults()
	}
	
	private func makeDefaults() {
		defaultMass = massSliderController.value
		defaultMaxSpeed = maxSpeedSliderController.value
		defaultMaxAcceleration = maxAccelerationSliderController.value
		defaultRadius = radiusSliderController.value
		defaultScale = scaleSliderController.value
	}
	
    // Any time we select a new agent, we need to force the sliders to recalculate their exponents
    func resetSliderControllers() {
        let controllers = [
            massSliderController, maxAccelerationSliderController, maxSpeedSliderController,
            radiusSliderController, scaleSliderController
        ]

        for controller in controllers { controller.resetExponent() }
    }
	
	@IBAction func buttonMakeDefaultsClicked(_ sender: NSButton) {
		makeDefaults()
	}
	
	@IBAction func buttonApplyDefaultsClicked(_ sender: NSButton) {
		massSliderController.value = defaultMass
		maxSpeedSliderController.value = defaultMaxSpeed
		maxAccelerationSliderController.value = defaultMaxAcceleration
		radiusSliderController.value = defaultRadius
		scaleSliderController.value = defaultScale
	}
	
}

// MARK: -

extension AgentAttributesController: LogSliderDelegate {
	
	func logSlider(_ controller: LogSliderController, newValue value: Double) {
		switch controller {
        case massSliderController:
            mass = value
            delegate?.agent(self, newValue: value, ofAttribute: .mass)
        case maxAccelerationSliderController:
            maxAcceleration = value
            delegate?.agent(self, newValue: value, ofAttribute: .maxAcceleration)
        case maxSpeedSliderController:
            maxSpeed = value
            delegate?.agent(self, newValue: value, ofAttribute: .maxSpeed)
        case radiusSliderController:
            radius = value
            delegate?.agent(self, newValue: value, ofAttribute: .radius)
		case scaleSliderController:
            scale = value
			delegate?.agent(self, newValue: value, ofAttribute: .scale)
		default:
			return
		}
	}
	
}

