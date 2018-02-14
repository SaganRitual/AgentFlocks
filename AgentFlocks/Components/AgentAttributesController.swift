//
//  AgentAttributesController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 19/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import SpriteKit

protocol AgentAttributesDelegate {
	func agent(_ controller: AgentAttributesController, newValue value:Double, ofAttribute:AgentAttributesController.Attribute)
}

class AgentAttributesController: NSViewController {
	
	enum Attribute { case mass, maxAcceleration, maxSpeed, radius, scale }
	
	// MARK: - Attributes (public)
    
    func getIsPaused() -> Bool { return false }
    
    func setIsPaused(_ isPaused: Bool, fromData: Bool) {
//        guard isPausedReentrancy == false else { return }
//        isPausedReentrancy = true
//
//        if fromData { isPausedSliderController.value = isPaused }
//        else { AFAgentEditor(core.getPathTo(targetAgent!)!, core: core).isPaused = isPaused }
//
//        isPausedReentrancy = false
    }

    func getMass() -> Float { return Float(massSliderController.value) }
	
    func setMass(_ mass: Float, fromData: Bool) {
        guard massReentrancy == false else { return }
        massReentrancy = true

        if fromData {
            // Max accel is coming straight from the data, so just set it in the
            // slider; no need for the slider to relay the message further
            massSliderController.value = Double(mass)
        } else {
            // Max accel is coming from the slider; send it down to the data; it
            // will call us (and everyone else) back after updating the...data
            let t = targetAgent!
            AFAgentEditor(core.getPathTo(t)!, core: core).mass = mass
        }

        massReentrancy = false
    }
    
    func getMaxAcceleration() -> Float { return Float(maxAccelerationSliderController.value) }
    
    func setMaxAcceleration(_ maxAcceleration: Float, fromData: Bool) {
        guard maxAccelerationReentrancy == false else { return }
        maxAccelerationReentrancy = true
        
        if fromData {
            // Max accel is coming straight from the data, so just set it in the
            // slider; no need for the slider to relay the message further
            maxAccelerationSliderController.value = Double(maxAcceleration)
        } else {
            // Max accel is coming from the slider; send it down to the data; it
            // will call us (and everyone else) back after updating the...data
            let t = targetAgent!
            AFAgentEditor(core.getPathTo(t)!, core: core).maxAcceleration = maxAcceleration
        }
        
        maxAccelerationReentrancy = false
    }

    func getMaxSpeed() -> Float { return Float(maxSpeedSliderController.value) }
    
    func setMaxSpeed(_ maxSpeed: Float, fromData: Bool) {
        guard maxSpeedReentrancy == false else { return }
        maxSpeedReentrancy = true
        
        if fromData {
            // Max speed is coming straight from the data, so just set it in the
            // slider; no need for the slider to relay the message further
            maxSpeedSliderController.value = Double(maxSpeed)
        } else {
            // Max speed is coming from the slider; send it down to the data; it
            // will call us (and everyone else) back after updating the...data
            let t = targetAgent!
            AFAgentEditor(core.getPathTo(t)!, core: core).maxSpeed = maxSpeed
        }
        
        maxSpeedReentrancy = false
    }
    
    func getRadius() -> Float { return Float(radiusSliderController.value) }
    
    func setRadius(_ radius: Float, fromData: Bool) {
        guard radiusReentrancy == false else { return }
        radiusReentrancy = true
        
        if fromData {
            // Mass is coming straight from the data, so just set it in the
            // slider; no need for the slider to relay the message further
            radiusSliderController.value = Double(radius)
        } else {
            // radius is coming from the slider; send it down to the data; it
            // will call us (and everyone else) back after updating the...data
            let t = targetAgent!
            AFAgentEditor(core.getPathTo(t)!, core: core).radius = radius
        }
        
        radiusReentrancy = false
    }
    
    func getScale() -> Float { return Float(scaleSliderController.value) }
    
    func setScale(_ scale: Float, fromData: Bool) {
        guard scaleReentrancy == false else { return }
        scaleReentrancy = true
        
        if fromData {
            // Mass is coming straight from the data, so just set it in the
            // slider; no need for the slider to relay the message further
            scaleSliderController.value = Double(scale)
        } else {
            // radius is coming from the slider; send it down to the data; it
            // will call us (and everyone else) back after updating the...data
            let t = targetAgent!
            AFAgentEditor(core.getPathTo(t)!, core: core).scale = scale
        }

        scaleReentrancy = false
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
    
    private var isPausedReentrancy = false
    private var massReentrancy = false
    private var maxAccelerationReentrancy = false
    private var maxSpeedReentrancy = false
    private var radiusReentrancy = false
    private var scaleReentrancy = false

    private var persistentDefaultsLoaded = false

    private var core: AFCore!
    private var dataNotifications: Foundation.NotificationCenter!
    private var targetAgent: String?
    private var uiNotifications: Foundation.NotificationCenter!

	// MARK: - Initialization
	
	init() {
        super.init(nibName: NSNib.Name(rawValue: "AgentAttributesView"), bundle: nil)
	}
    
    func inject(_ injector: AFCore.AFDependencyInjector) -> Bool {
        var iStillNeedSomething = false
        
        if let un = injector.uiNotifications { self.uiNotifications = un }
        else { injector.someoneStillNeedsSomething = true; iStillNeedSomething = true }
        
        if let cn = injector.dataNotifications { self.dataNotifications = cn }
        else { injector.someoneStillNeedsSomething = true; iStillNeedSomething = true }

        // Once everything is ready, we can start listening for UI activity
        if !iStillNeedSomething {
            self.core = injector.core

            let aSelector = #selector(hasBeenSelected(notification:))
            self.uiNotifications.addObserver(self, selector: aSelector, name: .Selected, object: nil)

            let cSelector = #selector(hasBeenDeselected(notification:))
            self.uiNotifications.addObserver(self, selector: cSelector, name: .Deselected, object: nil)

            // Data notifier
            let bSelector = #selector(nodeChanged(notification:))
            self.dataNotifications.addObserver(self, selector: bSelector, name: .CoreTreeUpdate, object: nil)
        }
        
        return iStillNeedSomething
    }
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}

    private func getAgentEditor(notification: Foundation.Notification) -> AFAgentEditor? {
        guard AFData.Notifier.isDataNotifier(notification) else {
            return AFSceneController.Notification.Decode(notification).editor as? AFAgentEditor
        }
        
        let n = AFData.Notifier(notification)
        return AFAgentEditor(n.pathToNode, core: core)
    }
    
    @objc func nodeChanged(notification: Foundation.Notification) {
        func helper(_ lhs: JSONSubscriptType, _ rhs: String) -> Bool { return JSON(lhs).stringValue == rhs }
        
        // Ignore the various notifications that we don't care about.
        
        // No agent selected
        guard let targetAgent = self.targetAgent else { return }
        
        // If I (the agent) am not mentioned in the change path, then the notification
        // has nothing to do with me. Just ignore it.
        let n = AFData.Notifier(notification)
        guard n.pathToNode.contains(where: { helper($0, targetAgent) }) else { return }
        
        // Something in the motivators below me has changed. I only care about agent attributes.
        let ix_ = n.pathToNode.first(where: { helper($0, targetAgent) })!
        let ix = JSON(ix_).intValue
        guard n.pathToNode.count == (ix + 2) else { return }

        // If we don't recognize the attribute name, throw a spanner in it
        let thisNode = String(describing: n.pathToNode.last!)
        guard let attribute = AFAgentAttribute(rawValue: thisNode) else { fatalError() }
        
        let editor = AFAgentEditor(n.pathToNode, core: core)
        loadAttribute(attribute, from: editor)
    }
    
    func loadAttribute(_ attribute: AFAgentAttribute, from editor: AFAgentEditor) {
        switch attribute {
        case .isPaused:        setIsPaused(editor.isPaused, fromData: true)
        case .mass:            setMass(editor.mass, fromData: true)
        case .maxAcceleration: setMaxAcceleration(editor.maxAcceleration, fromData: true)
        case .maxSpeed:        setMaxSpeed(editor.maxSpeed, fromData: true)
        case .radius:          setRadius(editor.radius, fromData: true)
        case .scale:           setScale(editor.scale, fromData: true)
        }
    }
    
    @objc func hasBeenSelected(notification: Foundation.Notification) {
        guard let name = AFSceneController.Notification.Decode(notification).name else { fatalError() }
        targetAgent = name
        
        let editor = core.getAgentEditor(for: JSON(name))
        Array<AFAgentAttribute>([.isPaused, .mass, .maxAcceleration, .maxSpeed, .radius, .scale]).forEach {
            loadAttribute($0, from: editor)
        }
    }
    
    @objc func hasBeenDeselected(notification: Foundation.Notification) { targetAgent = nil }
	
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
        case scaleSliderController:           setScale(v, fromData: false); print("logSlider", v)
		default:
			return
		}
	}
	
}

