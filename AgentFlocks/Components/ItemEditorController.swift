//
//  ItemEditorController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 22/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

class ItemEditorController: NSViewController {
	
	// MARK: - Attributes (public)
	
	var editedItem:Any?
    var followPathForward = true
    var newItemType:AgentGoalsController.GoalType?
    var isNewItem = true
	
	@objc dynamic var preview:Bool = false
	
    @IBAction func forwardCheckClicked(_ sender: NSButton) {
        followPathForward = (sender.state == .on)
    }
    
	// MARK: - Attributes (private)
	
	@IBOutlet private weak var sliderStackView: NSStackView!
	private var orderedSliderNames = [String]()
	private var sliders = [String:LogSliderController]()
    private var agentGoalsController: AgentGoalsController!
    private var agentEditorController: AgentEditorController!
	
	// MARK: - Initialization
	
    init(withAttributes attributes:[String], agentEditorController: AgentEditorController) {
        self.agentEditorController = agentEditorController
        self.agentGoalsController = agentEditorController.goalsController
        
		super.init(nibName: NSNib.Name(rawValue: "ItemEditorView"), bundle: nil)
		for valueName in attributes {
			// User lowercased attribute name as key
			let key = valueName.lowercased()
			
			// Create slider controller
			let sliderController = LogSliderController()
			sliderController.sliderName = valueName
            sliderController.delegate = AppDelegate.me
			
			// Add controller to our dictionary
			// And key to the ordered array list (in order to preserve order)
			sliders[key] = sliderController
			orderedSliderNames.append(key)
		}
	}
	
	convenience init(agentEditorController: AgentEditorController) {
        self.init(withAttributes: ["Value"], agentEditorController: agentEditorController)
	}
	
	required convenience init?(coder: NSCoder) {
		fatalError()
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		for key in orderedSliderNames {
			if let sliderController = sliders[key] {
				sliderStackView.addView(sliderController.view, in: .trailing)
                sliderController.parentItemEditorController = self
			}
		}
        
    }

	// MARK: - Public methods
    func refreshAffectedControllers() {
        agentGoalsController.outlineView.reloadData()
        agentEditorController.refresh()
    }

    func valueChanged(sliderName: String) -> Bool {
        if let sliderController = sliders[sliderName.lowercased()] {
            return sliderController.valueChanged
        }
        
        return false
    }
	
	// MARK: Exponent value
	func exponentValue(ofSlider sliderName:String) -> Int? {
		if let sliderController = sliders[sliderName.lowercased()] {
			return sliderController.exponentValue
		}
		return nil
	}
	
	func setExponentValue(ofSlider sliderName:String, to value: Int) {
		if let sliderController = sliders[sliderName.lowercased()] {
			sliderController.exponentValue = value
		}
	}
	
	// MARK: Value
	func value(ofSlider sliderName:String) -> Double? {
		if let sliderController = sliders[sliderName.lowercased()] {
			return sliderController.value
		}
		return nil
	}
	
    func setValue(ofSlider sliderName:String, to value: Double, resetDirtyFlag: Bool = false) {
		if let sliderController = sliders[sliderName.lowercased()] {
			sliderController.value = value
            
            if resetDirtyFlag { sliderController.valueChanged = false }
		}
	}

	// MARK: - Actions and methods (private)
	
	@IBAction private func applyButtonPressed(_ sender: NSButton) {
        let p = AFNotificationPacket.GoalsControlPanelApply(self)
        let q = AFNotificationPacket.pack(p)
        let n = Foundation.Notification(name: .GoalsControlPanelApply, object: nil, userInfo: q)
        AppDelegate.me.uiNotifications.post(n)
	}
	
	@IBAction func cancelButtonPressed(_ sender: NSButton) {
        let p = AFNotificationPacket.GoalsControlPanelCancel(self)
        let q = AFNotificationPacket.pack(p)
        let n = Foundation.Notification(name: .GoalsControlPanelCancel, object: nil, userInfo: q)
        AppDelegate.me.uiNotifications.post(n)
	}
	
}
