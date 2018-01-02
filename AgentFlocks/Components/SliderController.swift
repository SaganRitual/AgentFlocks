//
//  SliderController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 15/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

protocol SliderDelegate {
	func slider(_ controller: SliderController, newValue value:Double)
}

class SliderController: NSViewController {
	
	// MARK: - Attributes (public)
	
	// Name of the slider (name of value the slider changes)
	@objc dynamic var sliderName:String = "Name"
	
	// Allowed minimum and maximum value
	@objc dynamic var minValue:Double = 0.0 {
		didSet {
			if self.value < minValue {
				self.value = minValue
			}
		}
	}
	@objc dynamic var maxValue:Double = 100 {
		didSet {
			if self.value > maxValue {
				self.value = maxValue
			}
		}
	}
	
	// Slider value
	private var _value:Double = 1.0
	@objc dynamic var value:Double {
		get {
			return _value
		}
		set {
			if newValue < minValue {
				_value = minValue
			}
			else if newValue > maxValue {
				_value = maxValue
			}
			else {
				_value = newValue - newValue.remainder(dividingBy: incrementValue)
			}
		}
	}
	
	// Maximum allowed value (its maximum value and one unit when changed by stepper)
	private var _incrementValue:Double = 0.1
	var incrementValue:Double {
		get {
			return _incrementValue
		}
		set {
			_incrementValue = newValue
			if let slider = slider {
				slider.altIncrementValue = _incrementValue
			}
			if let stepper = maxStepper {
				stepper.increment = _incrementValue
			}
		}
	}
	@objc dynamic var maxMaxValue:Double = 1e6

	var delegate:SliderDelegate?
	
	// MARK: - Attributes (private)
	
	@IBOutlet private weak var slider: NSSlider!
	@IBOutlet private weak var valueEntry: NSTextField!
	@IBOutlet private weak var maxStepper: NSStepper!
	@IBOutlet private weak var maxValueEntry: NSTextField!
	
	// MARK: - Initialization
	
	init() {
		ValueTransformer.setValueTransformer(SliderValueTransformer(), forName: .sliderValueTransformer)
		super.init(nibName: NSNib.Name(rawValue: "SliderView"), bundle: nil)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		slider.altIncrementValue = incrementValue
		maxStepper.increment = incrementValue
		valueEntry.formatter = SliderValueFormatter()
    }
	
	// MARK: - Public methods
	
	func addToView(_ superview: NSView) {
		superview.addSubview(self.view)
		self.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint(item: superview,
		                   attribute: .top,
		                   relatedBy: .equal,
		                   toItem: self.view,
		                   attribute: .top,
		                   multiplier: 1.0,
		                   constant: 0.0).isActive = true
		NSLayoutConstraint(item: superview,
		                   attribute: .bottom,
		                   relatedBy: .equal,
		                   toItem: self.view,
		                   attribute: .bottom,
		                   multiplier: 1.0,
		                   constant: 0.0).isActive = true
		NSLayoutConstraint(item: superview,
		                   attribute: .left,
		                   relatedBy: .equal,
		                   toItem: self.view,
		                   attribute: .left,
		                   multiplier: 1.0,
		                   constant: 0.0).isActive = true
		NSLayoutConstraint(item: self.view,
		                   attribute: .right,
		                   relatedBy: .equal,
		                   toItem: superview,
		                   attribute: .right,
		                   multiplier: 1.0,
		                   constant: 0.0).isActive = true
	}
	
	// MARK: - Actions and methods (private)
	
	@IBAction func sliderDidMove(_ sender: NSSlider) {
		delegate?.slider(self, newValue: sender.doubleValue)
	}
	
	@IBAction func valueDidChange(_ sender: NSTextField) {
		delegate?.slider(self, newValue: value)
	}
	
}

// MARK: - Value formatter

class SliderValueFormatter: Formatter {
	
	override func string(for obj: Any?) -> String? {
		guard let value = obj as? String else { return "" }
		return value
	}
	
	override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
		obj?.pointee = string as AnyObject
		return true
	}
	
	override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

		if partialString.isEmpty {
			return true
		}

		// Deny change if other than number or dot entered
		var onlyNumbersAndDot = CharacterSet.decimalDigits
		onlyNumbersAndDot.insert(charactersIn: ".")
		if partialString.rangeOfCharacter(from: onlyNumbersAndDot.inverted) != nil {
			return false
		}

		// If number starts with 0, don't allow to enter additional characters
		if partialString.hasPrefix("0") && (partialString.count > 1) {
			return false
		}

		// This is a floating point number, do not allow more than one dots
		let allDots = partialString.filter { $0 == "." }
		if allDots.count > 1 {
			return false
		}

		// Correct the string for converting to Double
		let stringNumber = partialString.hasSuffix(".") ? "\(partialString)0" : partialString

		// Try to convert to Double
		return (Double(stringNumber) == nil) ? false : true
	}
	
}

// MARK: - Value transformer for XIB

class SliderValueTransformer: ValueTransformer {
	
	// Transformer used in slider. It's transforming Double to String and vice versa
	
	override class func transformedValueClass() -> AnyClass {
		return String.self as! AnyClass
	}
	
	override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		// Transforms Double to String
		guard let doubleValue = value as? Double else { return "" }
		return "\(doubleValue)"
	}
	
	override func reverseTransformedValue(_ value: Any?) -> Any? {
		// Transforms String to Double
		guard let stringValue = value as? String else { return 0.0 }
		// Correct the string for converting to Double
		let correctedValue = stringValue.hasSuffix(".") ? stringValue + "0" : stringValue
		if let doubleValue = Double(correctedValue) {
			return doubleValue
		}
		return 0.0
	}
	
}

extension NSValueTransformerName {
	static let sliderValueTransformer = NSValueTransformerName(rawValue: "SliderValueTransformer")
}
