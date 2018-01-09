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
            guard !AgentAttributesController.massReentrant else { return }
            
            AgentAttributesController.massReentrant = true
            massSliderController.value = newValue
            reloadAgentAttributes(skip: .mass)
            AgentAttributesController.massReentrant = false
        }
    }
    
    func reloadAgentAttributes(skip: AgentAttributesController.Attribute) {
        guard let ix = GameScene.me!.getPrimarySelectionIndex() else { return }

        let agent = GameScene.me!.entities[ix].agent

        if skip != .mass { mass = Double(agent.mass) }
        if skip != .maxAcceleration { maxAcceleration = Double(agent.maxAcceleration) }
        if skip != .maxSpeed { maxSpeed = Double(agent.maxSpeed) }
        if skip != .radius { radius = Double(agent.radius) }
        if skip != .scale { scale = Double(agent.scale) }
    }

    var maxAcceleration:Double {
        get {
            return maxAccelerationSliderController.value
        }
        set {
            guard !AgentAttributesController.maxAccelerationReentrant else { return }
            
            AgentAttributesController.maxAccelerationReentrant = true
            maxAccelerationSliderController.value = newValue
            reloadAgentAttributes(skip: .maxAcceleration)
            AgentAttributesController.maxAccelerationReentrant = false
        }
    }
    var maxSpeed:Double {
        get {
            return maxSpeedSliderController.value
        }
        set {
            guard !AgentAttributesController.maxSpeedReentrant else { return }
            
            AgentAttributesController.maxSpeedReentrant = true
            maxSpeedSliderController.value = newValue
            reloadAgentAttributes(skip: .maxSpeed)
            AgentAttributesController.maxSpeedReentrant = false
        }
    }
    var radius:Double {
        get {
            return radiusSliderController.value
        }
        set {
            guard !AgentAttributesController.radiusReentrant else { return }
            
            AgentAttributesController.radiusReentrant = true
            radiusSliderController.value = newValue
            reloadAgentAttributes(skip: .radius)
            AgentAttributesController.radiusReentrant = false
        }
    }
	var scale:Double {
		get {
			return scaleSliderController.value
		}
		set {
            guard !AgentAttributesController.scaleReentrant else { return }
            
            AgentAttributesController.scaleReentrant = true
			scaleSliderController.value = newValue
            AgentAttributesController.scaleReentrant = false
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

    static var massReentrant = false
    static var maxAccelerationReentrant = false
    static var maxSpeedReentrant = false
    static var radiusReentrant = false
    static var scaleReentrant = false
    
    private var persistentDefaultsLoaded = false
    
	// MARK: - Initialization
	
	init() {
		super.init(nibName: NSNib.Name(rawValue: "AgentAttributesView"), bundle: nil)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        typealias AttributeSet = (container: NSView?, controller: LogSliderController, label: String)
        let attributeSets: [AttributeSet] = [
            (massSliderContainer, massSliderController, "Mass"),
            (maxAccelerationSliderContainer, maxAccelerationSliderController, "Max Accel"),
            (maxSpeedSliderContainer, maxSpeedSliderController, "Max Speed"),
            (radiusSliderContainer, radiusSliderController, "Radius"),
            (scaleSliderContainer, scaleSliderController, "Scale")
        ]
        
        for s in attributeSets {
            s.controller.sliderName = s.label
            s.controller.delegate = self
			s.controller.addToView(s.container!)
        }

        if !persistentDefaultsLoaded {
            persistentDefaultsLoaded = true
            defaultMass = 0.1
            defaultMaxAcceleration = 100
            defaultMaxSpeed = 100
            defaultRadius = 25
            defaultScale = 1
        }
    }
	
	override func viewWillAppear() {
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

