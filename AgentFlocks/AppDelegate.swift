//
//  AppDelegate.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 14/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var topbarView: NSView!
	@IBOutlet weak var settingsView: NSView!
	@IBOutlet weak var sceneView: NSView!
	
    let topBarController = TopBarController()
	let topBarControllerPadding:CGFloat = 10.0
	
	static let agentEditorController = AgentEditorController()
	let leftBarWidth:CGFloat = 250.0
	
	let sceneController = SceneController()
	
	// Data
	typealias AgentGoalType = (name:String, enabled:Bool)
	typealias AgentBehaviorType = (name:String, enabled:Bool, goals:[AgentGoalType])
	typealias AgentType = (name:String, image:NSImage, behaviors:[AgentBehaviorType])

    typealias ObstacleType = (name:String, image:NSImage)
    var agents = [AgentType]()
    var obstacles = [ObstacleType]()
    
    static var editedAgentIndex:Int?
    var editedObstacleIndex:Int?

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
		
        agents = loadAgents()
        obstacles = loadObstacles()
        
		var agentImages = [NSImage]()
        var obstacleImages = [NSImage]()
		
		for agent in agents {
			agentImages.append(agent.image)
		}

        for obstacle in obstacles {
            obstacleImages.append(obstacle.image)
        }
        
        AppDelegate.agentEditorController.goalsController.dataSource = self
        AppDelegate.agentEditorController.goalsController.delegate = self
        
        topBarController.delegate = self
        
        topBarController.agentImages = agentImages
        topBarController.obstacleImages = obstacleImages

		// Add TopBar to the main window content
        topbarView.addSubview(topBarController.view)
		// Set TopBar's layout (stitch to top and to both sides)
        topBarController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint(item: topBarController.view,
		                   attribute: .top,
		                   relatedBy: .equal,
		                   toItem: topbarView,
		                   attribute: .top,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: topBarController.view,
		                   attribute: .left,
		                   relatedBy: .equal,
		                   toItem: topbarView,
		                   attribute: .left,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: topbarView,
		                   attribute: .right,
		                   relatedBy: .equal,
		                   toItem: topBarController.view,
		                   attribute: .right,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: topbarView,
		                   attribute: .bottom,
		                   relatedBy: .equal,
		                   toItem: topBarController.view,
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
    
    func loadObstacles() -> [ObstacleType] {
    
             var foundObstacles = [ObstacleType]()
             if let resourcesPath = Bundle.main.resourcePath {
                do {
                    let fileNames = try FileManager.default.contentsOfDirectory(atPath: resourcesPath)
                    for fileName in fileNames.sorted() where fileName.hasPrefix("Obstacle") {
                        if let image = NSImage(contentsOfFile: "\(resourcesPath)/\(fileName)") {
                            foundObstacles.append((name:fileName, image:image))
                        }
                    }
                } catch {
                    NSLog("Cannot read images from path '\(resourcesPath)'")
                }
        }

        return foundObstacles
    }
    
	func placeAgentFrames(agentIndex: Int) {
		
		// TODO: Set values of agentAttributesController based on agent with index 'agentIndex'
		
		settingsView.addSubview(AppDelegate.agentEditorController.view)
		AppDelegate.agentEditorController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint(item: AppDelegate.agentEditorController.view,
		                   attribute: .top,
		                   relatedBy: .equal,
		                   toItem: settingsView,
		                   attribute: .top,
		                   multiplier: 1.0,
		                   constant: 0.0).isActive = true
		NSLayoutConstraint(item: AppDelegate.agentEditorController.view,
		                   attribute: .left,
		                   relatedBy: .equal,
		                   toItem: settingsView,
		                   attribute: .left,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: settingsView,
		                   attribute: .right,
		                   relatedBy: .equal,
		                   toItem: AppDelegate.agentEditorController.view,
		                   attribute: .right,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: settingsView,
		                   attribute: .bottom,
		                   relatedBy: .equal,
		                   toItem: AppDelegate.agentEditorController.view,
		                   attribute: .bottom,
		                   multiplier: 1.0,
		                   constant: topBarControllerPadding).isActive = true
		NSLayoutConstraint(item: AppDelegate.agentEditorController.view,
		                   attribute: .width,
		                   relatedBy: .equal,
		                   toItem: nil,
		                   attribute: .notAnAttribute,
		                   multiplier: 1.0,
		                   constant: leftBarWidth).isActive = true
	}
	
	func removeAgentFrames() {
		AppDelegate.agentEditorController.view.removeFromSuperview()
		AppDelegate.agentEditorController.view.translatesAutoresizingMaskIntoConstraints = true
	}
	
	private func showPopover(withContentController contentController:NSViewController, forRect rect:NSRect, preferredEdge: NSRectEdge) {
		
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

// MARK: - TopBarDelegate

extension AppDelegate: TopBarDelegate {
    
    func topBarDrawPath(_ controller: TopBarController) {
        NSLog("Draw path...")
        self.removeAgentFrames()
    }
    func topBar(_ controller: TopBarController, obstacleSelected index: Int) {
        if 0..<obstacles.count ~= index {
            NSLog("Obstacle selected")
            editedObstacleIndex = index
            self.removeAgentFrames()
        }
    }
    
    func topBar(_ controller: TopBarController, agentSelected index: Int) {
        if 0..<agents.count ~= index {
            NSLog("Agent selected")
            AppDelegate.editedAgentIndex = index
            let entity = sceneController.addNode(image: agents[index].image)
            AppDelegate.agentEditorController.goalsController.dataSource = entity
            AppDelegate.agentEditorController.attributesController.delegate = entity.agent
            
            self.placeAgentFrames(agentIndex: index)
        }
    }

    func topBar(_ controller: TopBarController, flockSelected flock: TopBarController.FlockType) {
        NSLog("Flock selected: \(flock)")
        self.removeAgentFrames()
    }

    func topBar(_ controller: TopBarController, statusChangedTo newStatus: TopBarController.Status) {
        switch newStatus {
        case .Running:
            NSLog("START")
        case .Paused:
            NSLog("STOP")
        }
        self.removeAgentFrames()
    }

    func topBar(_ controller: TopBarController, speedChangedTo newSpeed: Double) {
        NSLog("Speed: %.2f%%", newSpeed)
        
    }

}

// MARK: - AgentGoalsDataSource

extension AppDelegate: AgentGoalsDataSource {

    func agentGoals(_ agentGoalsController: AgentGoalsController, numberOfChildrenOfItem item: Any?) -> Int {
        if let behaviorItem = item as? AgentBehaviorType {
            // Child item: behavior
            return behaviorItem.goals.count
        }
        // Root item
        return (AppDelegate.editedAgentIndex == nil) ? 0 : agents[AppDelegate.editedAgentIndex!].behaviors.count
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemExpandable item: Any) -> Bool {
        if item is AgentBehaviorType {
            return true
        }
        return false
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, child index: Int, ofItem item: Any?) -> Any {
        if let behaviorItem = item as? AgentBehaviorType {
            // Child item: AgentGoalType
            return behaviorItem.goals[index]
        }
        // Root item
        if let agentIndex = AppDelegate.editedAgentIndex {
            // Child item: AgentBehaviorType
            return agents[agentIndex].behaviors[index]
        }
        // Child item: AgentBehaviorType
        return agents[0].behaviors[0]
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, labelOfItem item: Any) -> String {
        if let behaviorItem = item as? AgentBehaviorType {
            return behaviorItem.name
        }
        else if let goalItem = item as? AgentGoalType {
            return goalItem.name
        }
        return ""
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, isItemEnabled item: Any) -> Bool {
        if let behaviorItem = item as? AgentBehaviorType {
            return behaviorItem.enabled
        }
        else if let goalItem = item as? AgentGoalType {
            return goalItem.enabled
        }
        return false
    }

}

// MARK: - AgentGoalsDelegate

extension AppDelegate: AgentGoalsDelegate {

    func agentGoalsPlayClicked(_ agentGoalsController: AgentGoalsController) {
        guard let agentIndex = AppDelegate.editedAgentIndex else { return }
    
        let entity = sceneController.addNode(image: agents[agentIndex].image)
        AppDelegate.agentEditorController.goalsController.dataSource = entity
        
            self.removeAgentFrames()
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, itemDoubleClicked item: Any, inRect rect: NSRect) {
        guard let mainView = window.contentView else { return }
        if item is AFBehavior {
            
            let editorController = ItemEditorController(withAttributes: ["Weight"])
            editorController.delegate = self
            editorController.editedItem = item
            
            // TODO: Set behavior values
            editorController.setValue(ofSlider: "Weight", to: 5.6)
            editorController.preview = true
        
            let itemRect = mainView.convert(rect, from: agentGoalsController.view)
            self.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
        }
        else if item is AFGoal {
            // TODO: Get Goal's type (Wander, Align, Cohere or Avoid) from item
            // based on that information create ItemEditorController with type's specific attributes
            let editorController = ItemEditorController(withAttributes: ["Distance", "Angle", "Weight"])
            editorController.delegate = self
            editorController.editedItem = item
 
            // TODO: Set goal values
            editorController.setValue(ofSlider: "Distance", to: 3.2)
            editorController.setValue(ofSlider: "Angle", to: 4.8)
            editorController.setValue(ofSlider: "Weight", to: 5.6)
            editorController.preview = true
        
            let itemRect = mainView.convert(rect, from: agentGoalsController.view)
            self.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
        }
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, item: Any, setState state: NSControl.StateValue) {
        if let behaviorItem = item as? AgentBehaviorType {
            let enabled = (state == .on) ? true : false
            NSLog("Behavior '\(behaviorItem.name)' " + (enabled ? "enabled" : "disabled"))
        }
        else if let goalItem = item as? AgentGoalType {
            let enabled = (state == .on) ? true : false
            NSLog("Goal '\(goalItem.name)' " + (enabled ? "enabled" : "disabled"))
            
        }
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, newBehaviorShowForRect rect: NSRect) {
        guard let mainView = window.contentView else { return }
    
        let editorController = ItemEditorController(withAttributes: ["Weight"])
        editorController.delegate = self
        editorController.newItemType = nil

        let itemRect = mainView.convert(rect, from: agentGoalsController.view)
        self.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, newGoalShowForRect rect: NSRect, goalType type: AgentGoalsController.GoalType) {
        guard let mainView = window.contentView else { return }
    
        var attributeList = ["Weight"]
        switch type {
        case .Align:
            attributeList = ["Distance", "Angle"] + attributeList
        case .Avoid:
            attributeList = ["Avoid"] + attributeList
        case .Cohere:
            attributeList = ["Cohere"] + attributeList
        case .Flee: break
        case .FollowPath: break
        case .Intercept: break
        case .Seek: break
        case .Separate: break
        case .StayOnPath: break
        case .TargetSpeed: break
        case .Wander:
            attributeList = ["Speed"] + attributeList
        }
    
        let editorController = ItemEditorController(withAttributes: attributeList)
        editorController.delegate = self
        editorController.newItemType = type
    
        let itemRect = mainView.convert(rect, from: agentGoalsController.view)
        self.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, dragIdentifierForItem item: Any) -> String? {
        if let behaviorItem = item as? AgentBehaviorType {
            return behaviorItem.name
        } else if let goalItem = item as? AgentGoalType {
            return goalItem.name
        } else {
            return nil
        }
    }
    
    func agentGoals(_ agentGoalsController: AgentGoalsController, validateDrop info: NSDraggingInfo, toParentItem parentItem: Any?, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if index == NSOutlineViewDropOnItemIndex {
            // Don't allow to drop on item
            return NSDragOperation.init(rawValue: 0)
        }
        return NSDragOperation.move
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        return false
    }
}

            
// MARK: - ItemEditorDelegate

extension AppDelegate: ItemEditorDelegate {
    
    private func getParentForNewMotivator(rootMotivator: AFMotivatorCollection, selectionIndex: Int) -> AFMotivatorCollection {
        if selectionIndex == -1 {
            return rootMotivator
        }
        
        var collectionIndex = 0
        var currentIndex = 0
        var parentForNewMotivator = rootMotivator.getChild(at: 0) as! AFBehavior

        while currentIndex < selectionIndex {
            currentIndex += 1 + parentForNewMotivator.howManyChildren()
            collectionIndex += 1

            parentForNewMotivator = rootMotivator.getChild(at: collectionIndex) as! AFBehavior
        }
        
        return parentForNewMotivator
    }
	
	func itemEditorApplyPressed(_ controller: ItemEditorController) {
		guard let agentIndex = AppDelegate.editedAgentIndex else { return }

        let entity = GameScene.selfScene!.entities[agentIndex] as! AFEntity
        let selected = AgentGoalsController.selfController.selectedIndex()
        let parentOfNewMotivator = getParentForNewMotivator(rootMotivator: entity.agent.motivator!, selectionIndex: selected)
        
//        let angle = controller.value(ofSlider: "Angle")
//        let distance = controller.value(ofSlider: "Distance")
        let speed = controller.value(ofSlider: "Speed")
        let weight = controller.value(ofSlider: "Weight")
        

        if controller.editedItem == nil {
            // Add new goal or behavior
            if let type = controller.newItemType {
                var goal: AFGoal?

                switch type {
                case .Align:  break;
                case .Avoid:  break;
                case .Cohere: break;
                case .Flee:   break
                case .FollowPath:   break
                case .Intercept:   break
                case .Seek:   break
                case .Separate:   break
                case .StayOnPath:   break
                case .TargetSpeed:   break
                case .Wander: goal = AFGoal(toWander: Float(speed!), weight: Float(weight!))
                }

                if goal != nil {
                    (parentOfNewMotivator as! AFBehavior).addGoal(goal!)
                }
            } else {
                let behavior = AFBehavior()
                behavior.weight = Float(weight!)
                (parentOfNewMotivator as! AFCompositeBehavior).addBehavior(behavior)
            }
		}
		else {
            // Edit existing goal or behavior
            
		}

        AppDelegate.agentEditorController.refresh()
		activePopover?.close()
	}
	
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
	
	func popoverDidClose(_ notification: Notification) {
		activePopover = nil
	}
	
}

