//
//  AgentAttributesController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 19/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa
import SpriteKit

protocol AgentAttributesDelegate {
	func agent(_ controller: AgentAttributesController, newValue value:Double, ofAttribute:AgentAttributesController.Attribute)
}

class AgentAttributesController: NSViewController {
	
	enum Attribute { case mass, maxAcceleration, maxSpeed, radius, scale }
	
	// MARK: - Attributes (public)
    
    func getMass() -> Float { return Float(massSliderController.value) }
	
    func setMass(_ mass: Float, fromData: Bool) {
        if fromData {
            // Mass is coming straight from the data, so just set it in the
            // slider; no need for the slider to relay the message further
            massSliderController.value = Double(mass)
        } else {
            // Mass is coming from the slider; send it down to the data; it
            // will call us (and everyone else) back after updating the...data
//            AFCore.coreData.setAttribute(.Mass, to: mass, for: targetAgent)
        }
    }
    
    func getMaxAcceleration() -> Float { return Float(maxAccelerationSliderController.value) }
    
    func setMaxAcceleration(_ maxAcceleration: Float, fromData: Bool) {
        if fromData {
            // Max accel is coming straight from the data, so just set it in the
            // slider; no need for the slider to relay the message further
            maxAccelerationSliderController.value = Double(maxAcceleration)
        } else {
            // Max accel is coming from the slider; send it down to the data; it
            // will call us (and everyone else) back after updating the...data
//            AFCore.coreData.setAttribute(.MaxAcceleration, to: maxAcceleration, for: targetAgent)
        }
    }

    func getMaxSpeed() -> Float { return Float(maxSpeedSliderController.value) }
    
    func setMaxSpeed(_ maxSpeed: Float, fromData: Bool) {
        if fromData {
            // Max speed is coming straight from the data, so just set it in the
            // slider; no need for the slider to relay the message further
            maxSpeedSliderController.value = Double(maxSpeed)
        } else {
            // Max speed is coming from the slider; send it down to the data; it
            // will call us (and everyone else) back after updating the...data
//            AFCore.coreData.setAttribute(.MaxSpeed, to: maxSpeed, for: targetAgent)
        }
    }
    
    func getRadius() -> Float { return Float(radiusSliderController.value) }
    
    func setRadius(_ radius: Float, fromData: Bool) {
        if fromData {
            // Mass is coming straight from the data, so just set it in the
            // slider; no need for the slider to relay the message further
            radiusSliderController.value = Double(radius)
        } else {
            // radius is coming from the slider; send it down to the data; it
            // will call us (and everyone else) back after updating the...data
//            AFCore.coreData.setAttribute(.Radius, to: radius, for: targetAgent)
        }
    }
    
    func getScale() -> Float { return Float(scaleSliderController.value) }
    
    func setScale(_ scale: Float, fromData: Bool) {
        if fromData {
            // Scale is coming straight from the data, so just set it in the
            // slider; no need for the slider to relay the message further
            scaleSliderController.value = Double(scale)
        } else {
            // Scale is coming from the slider; send it down to the data; it
            // will call us (and everyone else) back after updating the...data
//            AFCore.coreData.setAttribute(.Scale, to: scale, for: targetAgent)
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
    
    private var persistentDefaultsLoaded = false

    private var coreData: AFCoreData!
    private var dataNotifications: NotificationCenter!
    private var targetAgent = String()
    private var uiNotifications: NotificationCenter!
    
	// MARK: - Initialization
	
	init() {
        super.init(nibName: NSNib.Name(rawValue: "AgentAttributesView"), bundle: nil)
        
        // Note: we're using the default center here; that's where we all
        // broadcast our ready messages.
        let center = NotificationCenter.default
        let name = Notification.Name(rawValue: AFCoreData.NotificationType.AppCoreReady.rawValue)
        let selector = #selector(coreReady(notification:))
        center.addObserver(self, selector: selector, name: name, object: nil)
	}
    
    @objc func coreReady(notification: Notification) {
        if let info = notification.userInfo, let coreData = info["AFCoreData"] as? AFCoreData {
            // Come back to this: the ui should be publishing its own notifications--
            // we should be waiting for a shout from the UI to tell us where its
            // personal notification center is.
            self.coreData = coreData
            self.uiNotifications = info["UINotifications"] as! NotificationCenter
            self.dataNotifications = info["DataNotifications"] as! NotificationCenter

            let aName = Notification.Name(rawValue: AFSceneController.NotificationType.Selected.rawValue)
            let aSelector = #selector(hasBeenSelected(notification:))
            self.uiNotifications.addObserver(self, selector: aSelector, name: aName, object: nil)
            
            let bName = Notification.Name(rawValue: AFCoreData.NotificationType.SetAttribute.rawValue)
            let bSelector = #selector(attributeHasBeenUpdated(notification:))
            self.dataNotifications.addObserver(self, selector: bSelector, name: bName, object: nil)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
    
    @objc func attributeHasBeenUpdated(notification: Notification) {
        let (attribute, value, _) = notification.object as! (Int, Float, String)
        attributeHasBeenUpdated(attribute, to: value)
    }
    
    func attributeHasBeenUpdated(_ attribute: Int, to newValue: Float) {
        switch AFAgentAttribute(rawValue: attribute)! {
        case .Mass:
            setMass(newValue, fromData: true)
        default: break
        }
    }
    
    
    @objc func hasBeenSelected(notification: Notification) {
        let name = notification.object as! String
        let editor = AFAgentEditor(coreData: coreData, fullPath: coreData.getPathTo(name))

        setMass(editor.mass, fromData: true)
        setMaxAcceleration(editor.maxAcceleration, fromData: true)
        setMaxSpeed(editor.maxSpeed, fromData: true)
        setRadius(editor.radius, fromData: true)
        setScale(editor.scale, fromData: true)
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
        let v = Float(value)
        
		switch controller {
        case massSliderController:            setMass(v, fromData: false)
        case maxAccelerationSliderController: setMaxAcceleration(v, fromData: false)
        case maxSpeedSliderController:        setMaxSpeed(v, fromData: false)
        case radiusSliderController:          setRadius(v, fromData: false)
		case scaleSliderController:           setScale(v, fromData: false)
		default:
			return
		}
	}
	
}

