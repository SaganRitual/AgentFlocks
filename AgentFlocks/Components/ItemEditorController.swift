//
//  ItemEditorController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 22/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

protocol ItemEditorDelegate {
	func itemEditorApplyPressed(_ controller: ItemEditorController)
}

class ItemEditorController: NSViewController {
	
	// MARK: - Attributes (public)
	
	var delegate:ItemEditorDelegate?
	var editedItem:Any?
    var newItemType:AgentGoalsController.GoalType?
	
	@objc dynamic var preview:Bool = false
	
	// MARK: - Attributes (private)
	
	@IBOutlet private weak var sliderStackView: NSStackView!
	private var orderedSliderNames = [String]()
	private var sliders = [String:SliderController]()
	
	// MARK: - Initialization
	
    init(withAttributes attributes:[String]) {
		super.init(nibName: NSNib.Name(rawValue: "ItemEditorView"), bundle: nil)
		for valueName in attributes {
			// User lowercased attribute name as key
			let key = valueName.lowercased()
			
			// Create slider controller
			let sliderController = SliderController()
			sliderController.sliderName = valueName
			
			// Add controller to our dictionary
			// And key to the ordered array list (in order to preserve order)
			sliders[key] = sliderController
			orderedSliderNames.append(key)
		}
	}
	
	convenience init() {
        self.init(withAttributes: ["Value"])
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		for key in orderedSliderNames {
			if let sliderController = sliders[key] {
				sliderStackView.addView(sliderController.view, in: .trailing)
			}
		}
    }
	
	// MARK: - Public methods
    func valueChanged(sliderName: String) -> Bool {
        if let sliderController = sliders[sliderName.lowercased()] {
            return sliderController.valueChanged
        }
        
        return false
    }
	
	// MARK: Value
	func value(ofSlider sliderName:String) -> Double? {
		if let sliderController = sliders[sliderName.lowercased()] {
			return sliderController.value
		}
		return nil
	}
	
	func setValue(ofSlider sliderName:String, to value: Double) {
		if let sliderController = sliders[sliderName.lowercased()] {
			sliderController.value = value
		}
	}
	
	// MARK: Maximum value
	func maxValue(ofSlider sliderName:String) -> Double? {
		if let sliderController = sliders[sliderName.lowercased()] {
			return sliderController.maxValue
		}
		return nil
	}
	
	func setMaxValue(ofSlider sliderName:String, to value: Double) {
		if let sliderController = sliders[sliderName.lowercased()] {
			sliderController.maxValue = value
		}
	}
	
	// MARK: Maximum value
	func incrementValue(ofSlider sliderName:String) -> Double? {
		if let sliderController = sliders[sliderName.lowercased()] {
			return sliderController.incrementValue
		}
		return nil
	}
	
	func setIncrementValue(ofSlider sliderName:String, to value: Double) {
		if let sliderController = sliders[sliderName.lowercased()] {
			sliderController.incrementValue = value
		}
	}
	
	// MARK: - Actions and methods (private)
	
	@IBAction private func applyButtonPressed(_ sender: NSButton) {
		delegate?.itemEditorApplyPressed(self)
	}
	
}
