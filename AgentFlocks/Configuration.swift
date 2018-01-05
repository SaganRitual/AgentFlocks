//
//  Configuration.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 05/01/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

class Configuration: NSObject {
	
	// This object is a singleton
	// It allows access to it only through the following class property:
	static let shared = Configuration()
	
	// Object overrides constructor and makes it private so there's no
	// option to create it in other way.
	// There's only one object: Configuration.shared
	
	// MARK: - Configuration values
	
	// These two dummy values are bound to preferences window's
	// two checkboxes. Because of this binding they
	// must be KVC-compliant which is achieved by "@objc dynamic"
	
	@objc dynamic var firstDummyValue = true {
		didSet {
			#if DEBUG
				NSLog("firstDummyValue: \(firstDummyValue)")
			#endif
			self.saveConfiguration()
		}
	}
	
	@objc dynamic var secondDummyValue = false {
		didSet {
			#if DEBUG
				NSLog("secondDummyValue: \(secondDummyValue)")
			#endif
			self.saveConfiguration()
		}
	}
	
	@objc dynamic var thirdDummyValue = true {
		didSet {
			#if DEBUG
				NSLog("thirdDummyValue: \(thirdDummyValue)")
			#endif
			self.saveConfiguration()
		}
	}
	
	// MARK: - Initialization
	
	// Hide initializer, so object can't be created elsewhere
	// only by this class
	private override init() {
		super.init()
		// Load configuration
		loadConfiguration()
	}
	
	// MARK: - Public methods
	
	func saveConfiguration() {
		UserDefaults.standard.set(firstDummyValue, forKey: "firstDummyValue")
		UserDefaults.standard.set(secondDummyValue, forKey: "secondDummyValue")
		UserDefaults.standard.set(thirdDummyValue, forKey: "thirdDummyValue")
		UserDefaults.standard.synchronize()
	}
	
	// MARK: - Private methods
	
	func loadConfiguration() {
		let userDefaults = UserDefaults.standard
		if let boolValue = userDefaults.value(forKey: "firstDummyValue") as? Bool {
			firstDummyValue = boolValue
		}
		if let boolValue = userDefaults.value(forKey: "secondDummyValue") as? Bool {
			secondDummyValue = boolValue
		}
		if let boolValue = userDefaults.value(forKey: "thirdDummyValue") as? Bool {
			thirdDummyValue = boolValue
		}
	}
	
}

