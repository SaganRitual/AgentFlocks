//
//  AppDelegate.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 14/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa
import Foundation
import GameplayKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var topbarView: NSView!
	@IBOutlet weak var settingsView: NSView!
	@IBOutlet weak var sceneView: NSView!
	
    let topBarController = TopBarController()
	let topBarControllerPadding:CGFloat = 10.0
	
	static let agentEditorController = AgentEditorController()
    static var me: AppDelegate!
	let leftBarWidth:CGFloat = 250.0
	
	let sceneController = SceneController()
	
	// Data
	typealias AgentGoalType = (name:String, enabled:Bool)
	typealias AgentBehaviorType = (name:String, enabled:Bool, goals:[AgentGoalType])
	typealias AgentType = (name:String, image:NSImage, behaviors:[AgentBehaviorType])

    typealias ObstacleType = (name:String, image:NSImage)
    var agents = [AgentType]()
    var obstacles = [ObstacleType]()
    
    var editedObstacleIndex:Int?
    var stopTime: TimeInterval = 0

	private var activePopover:NSPopover?
    
    var parentOfNewMotivator: AFBehavior?
	
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
        
        AppDelegate.me = self
		
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
    func loadJSON(_ controller: TopBarController) {
        // Get out of draw mode. Seems weird to be doing this in a function about
        // loading a script, but this is the only reasonable place to put it, I think?

        GameScene.me!.selectionDelegate = GameScene.me!.selectionDelegatePrimary

        do {
            if let resourcesPath = Bundle.main.resourcePath {
                let url = URL(string: "file://\(resourcesPath)/setup.json")!
                let jsonData = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let entities_ = try decoder.decode(AFEntities.self, from: jsonData)

                var selectionSet = false

                for entity_ in entities_.entities {
                    let entity = AFEntity(prototype: entity_)
                    GameScene.me!.entities.append(entity)
                    
                    if !selectionSet {
                        AppDelegate.agentEditorController.goalsController.dataSource = entity
                        AppDelegate.agentEditorController.attributesController.delegate = entity.agent
                        selectionSet = true
                    }

                    let nodeIndex = GameScene.me!.entities.count - 1
                    GameScene.me!.newAgent(nodeIndex)
                }
            }
        } catch { print(error) }
   }
	
	func loadAgents() -> [AgentType] {
		
		var foundAgents = [AgentType]()
		if let resourcesPath = Bundle.main.resourcePath {
			do {
				let fileNames = try FileManager.default.contentsOfDirectory(atPath: resourcesPath)
				for fileName in fileNames.sorted() where fileName.hasPrefix("Agent") {
                    print("\(resourcesPath)/\(fileName)")
					if let image = NSImage(contentsOfFile: "\(resourcesPath)/\(fileName)") {
						let agent:AgentType = (name:fileName, image:image, behaviors:[]);
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
        let agent = GameScene.me!.entities[agentIndex].agent
        let ac = AppDelegate.agentEditorController.attributesController
        
        ac.mass = Double(agent.mass)
        ac.maxAcceleration = Double(agent.maxAcceleration)
        ac.maxSpeed = Double(agent.maxSpeed)
        ac.radius = Double(agent.radius)
        ac.scale = Double(agent.scale)
        
		settingsView.addSubview(AppDelegate.agentEditorController.view)
        AppDelegate.agentEditorController.refresh()
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
        GameScene.me!.selectionDelegate = GameScene.me!.selectionDelegateDraw
    }
    
    func pInputClicked(_ controller: TopBarController) {
        GameScene.me!.selectionDelegate = GameScene.me!.selectionDelegatePrimary
    }
    
    func multiSelectClicked(_ controller: TopBarController) {
        // No more multi-select mode; repurpose the button
    }
    
    func singleSelectClicked(_ controller: TopBarController) {
        // No more multi-select mode; repurpose the button
    }
    
    func clearPathClicked(_ controller: TopBarController) {
        GameScene.me!.selectionDelegateDraw.vertices.removeAll()
    }
    
    func topBar(_ controller: TopBarController, obstacleSelected index: Int) {
        if 0..<obstacles.count ~= index {
            NSLog("Obstacle selected")
            editedObstacleIndex = index
            self.removeAgentFrames()
        }
    }
    
    func topBar(_ controller: TopBarController, imageIndex: Int) {
        if 0..<agents.count ~= imageIndex {
            NSLog("Agent selected")
            
            GameScene.me!.selectionDelegate.deselectAll()

            let entity = sceneController.addNode(image: agents[imageIndex].image)
            AppDelegate.agentEditorController.goalsController.dataSource = entity
            AppDelegate.agentEditorController.attributesController.delegate = entity.agent

            let nodeIndex = GameScene.me!.entities.count - 1
            
            GameScene.me!.newAgent(nodeIndex)
            
            self.placeAgentFrames(agentIndex: nodeIndex)
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
            GameScene.me!.lastUpdateTime = 0
        case .Paused:
            NSLog("STOP")
        }
    }

    func topBar(_ controller: TopBarController, speedChangedTo newSpeed: Double) {
        NSLog("Speed: %.2f%%", newSpeed)
        
    }

}

// MARK: - AgentGoalsDelegate

extension AppDelegate: AgentGoalsDelegate {

    func agentGoalsPlayClicked(_ agentGoalsController: AgentGoalsController) {
        print("We're not doing anything with the play button on the agent goals controller")
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, itemClicked item: Any, inRect rect: NSRect) {
        if let motivator = item as? AFBehavior {
            parentOfNewMotivator = motivator
        } else if let motivator = item as? AFGoal {
            parentOfNewMotivator = agentGoalsController.outlineView.parent(forItem: motivator) as? AFBehavior
        }
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, itemDoubleClicked item: Any, inRect rect: NSRect) {
        guard let mainView = window.contentView else { return }
        if item is AFBehavior {
            let behavior = item as! AFBehavior
            
            let editorController = ItemEditorController(withAttributes: ["Weight"])
            editorController.delegate = self
            editorController.editedItem = item

            editorController.setValue(ofSlider: "Weight", to: Double(behavior.weight))
            editorController.preview = true
        
            let itemRect = mainView.convert(rect, from: agentGoalsController.view)
            self.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
        }
        else if item is AFGoal {
            let goal = item as! AFGoal
            
            var attributes = [String]()

            switch goal.goalType {
            case .toAlignWith:    fallthrough
            case .toCohereWith:   fallthrough
            case .toSeparateFrom: attributes = ["Angle", "Distance", "Weight"]

            case .toFleeAgent:    fallthrough
            case .toSeekAgent:    attributes = ["Weight"]

            case .toReachTargetSpeed: fallthrough
            case .toWander:           attributes = ["Speed", "Weight"]

            case .toFollow:         attributes = ["Time", "Weight"]
                
            case .toStayOn:         fallthrough
            case .toAvoidAgents:    fallthrough
            case .toAvoidObstacles: fallthrough
            case .toInterceptAgent: attributes = ["Time", "Weight"]
            }
            
            let editorController = ItemEditorController(withAttributes: attributes)
            editorController.delegate = self
            editorController.editedItem = item
 
            editorController.setValue(ofSlider: "Angle", to: Double(goal.angle))
            editorController.setValue(ofSlider: "Distance", to: Double(goal.distance))
            editorController.setValue(ofSlider: "Speed", to: Double(goal.speed))
            editorController.setValue(ofSlider: "Time", to: Double(goal.time))
            editorController.setValue(ofSlider: "Weight", to: Double(goal.weight))
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
        case .toAlignWith:      fallthrough
        case .toCohereWith:     fallthrough
        case .toSeparateFrom:   attributeList = ["Distance", "Angle"] + attributeList

        case .toAvoidAgents:    fallthrough
        case .toAvoidObstacles: fallthrough
        case .toInterceptAgent: attributeList = ["Time"] + attributeList

        case .toFleeAgent: fallthrough
        case .toSeekAgent: break

        case .toFollow: attributeList = ["Time"] + attributeList
        case .toStayOn: attributeList = ["Time"] + attributeList

        case .toReachTargetSpeed: fallthrough
        case .toWander:           attributeList = ["Speed"] + attributeList
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
    
    private func getParentForNewMotivator() -> AFBehavior {
        return AppDelegate.me!.parentOfNewMotivator!
    }
	
	func itemEditorApplyPressed(_ controller: ItemEditorController) {
        let selectedIndexes = GameScene.me!.getSelectedIndexes()
        guard selectedIndexes.count > 0 else { return }

        let agentIndex = GameScene.me!.getPrimarySelectionIndex()!
        let entity = GameScene.me!.entities[agentIndex]
        let parentOfNewMotivator = getParentForNewMotivator()
        
        let angle = controller.value(ofSlider: "Angle")
        let distance = controller.value(ofSlider: "Distance")
        let speed = controller.value(ofSlider: "Speed")
        let time = controller.value(ofSlider: "Time")
        let weight = controller.value(ofSlider: "Weight")
        
        if let behavior = controller.editedItem as? AFBehavior {
            // Edit existing behavior
            (entity.agent.behavior! as! AFCompositeBehavior).setWeight(Float(weight!), for: behavior)
        } else if let goal = controller.editedItem as? AFGoal {
            // Edit existing goal -- note AFBehavior doesn't give us a way
            // to update the goal. If we want to assign any new values to
            // this goal, we just have to throw it away and make a new one.
            var newGoalRequired = false
            for name in ["Angle", "Distance", "Speed", "Time", "Weight"] {
                if controller.valueChanged(sliderName: name) {
                    newGoalRequired = true
                }
            }

            let weight = Float(weight!)

            // However, the weight of the goal is managed by the behavior.
            // So if all we're updating is the weight, we can just change that
            // directly in the behavior, without creating a new goal.
            if newGoalRequired {
                if let angle = angle { goal.angle = Float(angle) }
                if let distance = distance { goal.distance = Float(distance) }
                if let speed = speed { goal.speed = Float(speed) }
                if let time = time { goal.time = Float(time) }
                
                let newGoal = AFGoal(copyFrom: goal)
                parentOfNewMotivator.remove(goal)
                parentOfNewMotivator.setWeight(weight, for: newGoal)
            } else {
                parentOfNewMotivator.setWeight(weight, for: goal)
            }
        } else {
            // Add new goal or behavior
            if let type = controller.newItemType {
                var goal: AFGoal?
                let group = GameScene.me!.getSelectedAgents()

                switch type {
                case .toAlignWith:
                    for agent in group {
                        goal = AFGoal(toAlignWith: group, maxDistance: Float(distance!), maxAngle: Float(angle!), weight: Float(weight!))
                        (agent as! AFAgent2D).addGoal(goal!)
                    }
                    
                    goal = nil
                    
                case .toAvoidObstacles:
                    var points = [float2]()
                    for vertex in GameScene.me!.selectionDelegateDraw.vertices {
                        let point = float2(Float(vertex.x), Float(vertex.y))
                        points.append(point)
                    }
                    
                    let outline = GKPolygonObstacle(points: points)
                    goal = AFGoal(toAvoidObstacles: [outline], time: time!, weight: Float(weight!))
                    
                case .toAvoidAgents:
                    goal = AFGoal(toAvoidAgents: group, time: time!, weight: Float(weight!))
                    for agent in group {
                        (agent as! AFAgent2D).addGoal(goal!)
                    }
                    
                    goal = nil
                    
                case .toCohereWith:
                    goal = AFGoal(toCohereWith: group, maxDistance: Float(distance!), maxAngle: Float(angle!), weight: Float(weight!))
                    for agent in group {
                        (agent as! AFAgent2D).addGoal(goal!)
                    }
                    
                    goal = nil
                    
                case .toFleeAgent:
                    let selectedIndexes = GameScene.me!.getSelectedIndexes()
                    guard selectedIndexes.count == 2 else { return }
                    
                    var si = selectedIndexes.union(Set<Int>())
                    si.remove(GameScene.me!.getPrimarySelectionIndex()!)
                    
                    let secondarySelectionIndex = si.first!
                    let theAgentToFlee = GameScene.me!.entities[secondarySelectionIndex].agent
                    goal = AFGoal(toFleeAgent: theAgentToFlee, weight: Float(weight!))
                    
                case .toFollow:
                    var points = [GKGraphNode2D]()
                    for vertex in GameScene.me!.selectionDelegateDraw.vertices {
                        let point = GKGraphNode2D(point: vector_float2(Float(vertex.x), Float(vertex.y)))
                        points.append(point)
                    }
                    
                    let path = GKPath(graphNodes: points, radius: 1)
                    goal = AFGoal(toFollow: path, time: Float(time!), forward: true, weight: Float(weight!))
                    
                case .toInterceptAgent:
                    let selectedIndexes = GameScene.me!.getSelectedIndexes()
                    guard selectedIndexes.count == 2 else { return }

                    let indexesAsArray = Array(selectedIndexes)
                    let secondaryAgentIndex = indexesAsArray[1]
                    let theAgentToIntercept = GameScene.me!.entities[secondaryAgentIndex].agent
                    goal = AFGoal(toInterceptAgent: theAgentToIntercept, time: time!, weight: Float(weight!))

                case .toSeekAgent:
                    let selectedIndexes = GameScene.me!.getSelectedIndexes()
                    guard selectedIndexes.count == 2 else { return }

                    let indexesAsArray = Array(GameScene.me!.getSelectedIndexes())
                    let secondaryAgentIndex = indexesAsArray[1]
                    let theAgentToSeek = GameScene.me!.entities[secondaryAgentIndex].agent
                    goal = AFGoal(toSeekAgent: theAgentToSeek, weight: Float(weight!))

                case .toSeparateFrom:
                    goal = AFGoal(toSeparateFrom: group, maxDistance: Float(distance!), maxAngle: Float(angle!), weight: Float(weight!))
                    for agent in group {
                        (agent as! AFAgent2D).addGoal(goal!)
                    }
                    
                    goal = nil

                case .toStayOn:
                    var points = [GKGraphNode2D]()
                    for vertex in GameScene.me!.selectionDelegateDraw.vertices {
                        let point = GKGraphNode2D(point: vector_float2(Float(vertex.x), Float(vertex.y)))
                        points.append(point)
                    }
                    
                    let path = GKPath(graphNodes: points, radius: 1)
                    goal = AFGoal(toStayOn: path, time: 1, weight: 100)

                case .toReachTargetSpeed:
                    goal = AFGoal(toReachTargetSpeed: Float(speed!), weight: Float(weight!))
                    
                case .toWander:
                    goal = AFGoal(toWander: Float(speed!), weight: Float(weight!))
                }

                if goal != nil {
                    parentOfNewMotivator.addGoal(goal!)
                }
            } else {
                let behavior = AFBehavior(agent: entity.agent)
                behavior.weight = Float(weight!)
                (parentOfNewMotivator as! AFCompositeBehavior).addBehavior(behavior)
            }
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

