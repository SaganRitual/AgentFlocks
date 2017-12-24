//
//  AppDelegate.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 14/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

class UglyGlobals {
    static var appDelegate: AppDelegate!
    static var agentEditorController: AgentEditorController!
    
    static var editedAgentIndex:Int?
    static var editedObstacleIndex:Int?

    static var agents = [AppDelegate.AgentType]()
    
    static var topBarController = TopBarController()

    static var obstacleImages = [NSImage]()
}

class Barf {
    
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var topbarView: NSView!
	@IBOutlet weak var settingsView: NSView!
	@IBOutlet weak var sceneView: NSView!
	
	let topBarControllerPadding:CGFloat = 10.0
	
	let agentEditorController = AgentEditorController()
	let leftBarWidth:CGFloat = 250.0
	
	let sceneController = SceneController()
	
	// Data
	typealias AgentGoalType = (name:String, enabled:Bool)
	typealias AgentBehaviorType = (name:String, enabled:Bool, goals:[AgentGoalType])
	typealias AgentType = (name:String, image:NSImage, behaviors:[AgentBehaviorType])
	
	private var activePopover:NSPopover?
	
	func applicationWillFinishLaunching(_ notification: Notification) {
		
		if let screenFrame = NSScreen.main?.frame {
			self.window.setFrame(screenFrame, display: true)
		}
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
		#if DEBUG
		// Visualise constraints when something is wrong
		UserDefaults.standard.set(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
		#endif
        
        UglyGlobals.appDelegate = self
        UglyGlobals.agentEditorController = agentEditorController

		UglyGlobals.agents = loadAgents()
		
		var agentImages = [NSImage]()
		
		for agent in UglyGlobals.agents {
			agentImages.append(agent.image)
		}
//        agentEditorController.goalsController.dataSource = self
//        agentEditorController.goalsController.delegate = self
		
//		UglyGlobals.topBarController.animatePopovers = true
//		UglyGlobals.topBarController.flocksMenuAtMousePosition = true
		UglyGlobals.topBarController.agentImages = agentImages
		UglyGlobals.topBarController.obstacleImages = UglyGlobals.obstacleImages
		
		// Add TopBar to the main window content
		topbarView.addSubview(UglyGlobals.topBarController.view)
		// Set TopBar's layout (stitch to top and to both sides)
		UglyGlobals.topBarController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint(item: UglyGlobals.topBarController.view,
		                   attribute: .top,
		                   relatedBy: .equal,
		                   toItem: topbarView,
		                   attribute: .top,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: UglyGlobals.topBarController.view,
		                   attribute: .left,
		                   relatedBy: .equal,
		                   toItem: topbarView,
		                   attribute: .left,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: topbarView,
		                   attribute: .right,
		                   relatedBy: .equal,
		                   toItem: UglyGlobals.topBarController.view,
		                   attribute: .right,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: topbarView,
		                   attribute: .bottom,
		                   relatedBy: .equal,
		                   toItem: UglyGlobals.topBarController.view,
		                   attribute: .bottom,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		
		// Add SceneView to the main window content
		sceneView.addSubview(sceneController.view)
		// Set SceneView's layout
		sceneController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint(item: sceneController.view,
		                   attribute: .top,
		                   relatedBy: .equal,
		                   toItem: sceneView,
		                   attribute: .top,
		                   multiplier: 1.0,
		                   constant: 0.0).isActive = true
		NSLayoutConstraint(item: sceneController.view,
		                   attribute: .left,
		                   relatedBy: .equal,
		                   toItem: sceneView,
		                   attribute: .left,
		                   multiplier: 1.0,
		                   constant: 0.0).isActive = true
		NSLayoutConstraint(item: sceneView,
		                   attribute: .right,
		                   relatedBy: .equal,
		                   toItem: sceneController.view,
		                   attribute: .right,
		                   multiplier: 1.0,
		                   constant: 0.0).isActive = true
		NSLayoutConstraint(item: sceneView,
		                   attribute: .bottom,
		                   relatedBy: .equal,
		                   toItem: sceneController.view,
		                   attribute: .bottom,
		                   multiplier: 1.0,
		                   constant: 0.0).isActive = true
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	// MARK: - Custom methods
	
	func loadAgents() -> [AgentType] {
		
		var foundAgents = [AgentType]()
		if let resourcesPath = Bundle.main.resourcePath {
			do {
				let fileNames = try FileManager.default.contentsOfDirectory(atPath: resourcesPath)
				for fileName in fileNames.sorted() where fileName.hasPrefix("Agent") {
					if let image = NSImage(contentsOfFile: "\(resourcesPath)/\(fileName)") {
						var agent:AgentType = (name:fileName, image:image, behaviors:[]);
						for index1 in 1...5 {
							var behavior:AgentBehaviorType = (name: "Behavior\(index1)", enabled:true, goals:[])
							for index2 in 1...3 {
								let goal:AgentGoalType = (name: "Goal\(index2)", enabled:true)
								behavior.goals.append(goal)
							}
							agent.behaviors.append(behavior)
						}
						foundAgents.append(agent)
					}
				}
			} catch {
				NSLog("Cannot read images from path '\(resourcesPath)'")
			}
		}
		
		return foundAgents
	}

	func placeAgentFrames(agentIndex: Int) {
		
		// TODO: Set values of agentAttributesController based on agent with index 'agentIndex'
		
		settingsView.addSubview(agentEditorController.view)
		agentEditorController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint(item: agentEditorController.view,
		                   attribute: .top,
		                   relatedBy: .equal,
		                   toItem: settingsView,
		                   attribute: .top,
		                   multiplier: 1.0,
		                   constant: 0.0).isActive = true
		NSLayoutConstraint(item: agentEditorController.view,
		                   attribute: .left,
		                   relatedBy: .equal,
		                   toItem: settingsView,
		                   attribute: .left,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: settingsView,
		                   attribute: .right,
		                   relatedBy: .equal,
		                   toItem: agentEditorController.view,
		                   attribute: .right,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: settingsView,
		                   attribute: .bottom,
		                   relatedBy: .equal,
		                   toItem: agentEditorController.view,
		                   attribute: .bottom,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: agentEditorController.view,
		                   attribute: .width,
		                   relatedBy: .equal,
		                   toItem: nil,
		                   attribute: .notAnAttribute,
		                   multiplier: 1.0,
		                   constant: leftBarWidth).isActive = true
	}
	
	func removeAgentFrames() {
		agentEditorController.view.removeFromSuperview()
		agentEditorController.view.translatesAutoresizingMaskIntoConstraints = true
	}
	
	/*private*/ func showPopover(withContentController contentController:NSViewController, forRect rect:NSRect, preferredEdge: NSRectEdge) {
		
		guard let mainView = window.contentView else { return }
		
		// Create popover
		let popover = NSPopover()
		popover.behavior = .transient
		popover.animates = false
		popover.delegate = self
		popover.contentViewController = contentController
		
		// Show popover
		popover.show(relativeTo: rect, of: mainView, preferredEdge: preferredEdge)
		activePopover = popover
	}
	
}

// MARK: - ItemEditorDelegate

extension AppDelegate: ItemEditorDelegate {
	
	func itemEditorApplyPressed(_ controller: ItemEditorController) {
		guard let agentIndex = UglyGlobals.editedAgentIndex else { return }
		
		if let _ = controller.editedItem {
			// Edit existing behavior:
			// TODO: Identify item in database and change it.
			// Values:
			//   controller.weight
			//   controller.preview
		}
		else {
			// Add new behavior
			let selectedIndex = agentEditorController.selectedIndex()
			UglyGlobals.agents[agentIndex].behaviors.insert((name: "New behavior", enabled: true, goals: []), at: selectedIndex+1)
			agentEditorController.refresh()
		}
		activePopover?.close()
	}
	
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
	
	func popoverDidClose(_ notification: Notification) {
		activePopover = nil
	}
	
}

