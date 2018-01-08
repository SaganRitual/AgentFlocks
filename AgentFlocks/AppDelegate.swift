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
	
	let configuration = Configuration.shared
	let preferencesWindowController = PreferencesController(windowNibName: NSNib.Name.init(rawValue: "PreferencesWindow"))
	
    let topBarController = TopBarController()
	let topBarControllerPadding:CGFloat = 10.0
	
	static let agentEditorController = AgentEditorController()
    static var me: AppDelegate!
	let leftBarWidth:CGFloat = 300.0
	
	let sceneController = SceneController()
	
	// Data
	typealias AgentGoalType = (name:String, enabled:Bool)
	typealias AgentBehaviorType = (name:String, enabled:Bool, goals:[AgentGoalType])
	typealias AgentType = (name:String, image:NSImage, behaviors:[AgentBehaviorType])

    typealias ObstacleType = (name:String, image:NSImage)
    var agents = [AgentType]()
    var obstacles = [ObstacleType]()
    
    var editedObstacleIndex:Int?
    var agentImageIndex = 0
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
    
    class jsonOut: Encodable {
        let entities: [AFEntity_Script]
        let paths: [AFPath_Script]
        
        init(entities: [AFEntity_Script], paths: [AFPath_Script]) {
            self.entities = entities
            self.paths = paths
        }
    }
	
	func loadAgents() -> [AgentType] {
		
		var foundAgents = [AgentType]()
		if let resourcesPath = Bundle.main.resourcePath {
			do {
				let fileNames = try FileManager.default.contentsOfDirectory(atPath: resourcesPath)
				for fileName in fileNames.sorted() where fileName.hasPrefix("Agent") {
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
		popover.behavior = .applicationDefined
		popover.animates = false
		popover.delegate = self
		popover.contentViewController = contentController
		
		// Show popover
		popover.show(relativeTo: rect, of: mainView, preferredEdge: preferredEdge)
		activePopover = popover
	}
    
    // MARK: - File i/o
    
    func loadJSON(url: URL) {
        // Get out of draw mode. Seems weird to be doing this in a function about
        // loading a script, but this is the only reasonable place to put it, I think?
        
        GameScene.me!.selectionDelegate = GameScene.me!.selectionDelegatePrimary
        
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let entities_ = try decoder.decode(AFEntities.self, from: jsonData)
            
            let paths_ = try decoder.decode(AFPaths.self, from: jsonData)
            
            for path_ in paths_.paths {
                let path = AFPath(prototype: path_)
                GameScene.me!.paths[path.name] = path
                GameScene.me!.pathnames.append(path.name)
            }
            
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
        } catch { print(error) }
    }
    
    func saveJSON(url: URL) {
        do {
            var entities_ = [AFEntity_Script]()
            
            for entity in GameScene.me!.entities {
                let entity_ = AFEntity_Script(entity: entity)
                entities_.append(entity_)
            }
            
            var paths_ = [AFPath_Script]()
            
            for (_, afPath) in GameScene.me!.paths {
                let afPath_Script = AFPath_Script(afPath: afPath)
                paths_.append(afPath_Script)
            }
            
            let bigger = jsonOut(entities: entities_, paths: paths_)
            let encoder = JSONEncoder()
            let script = try encoder.encode(bigger)
            
            do {
                try script.write(to: url)
            } catch { print(error) }
        } catch { print(error) }
    }

	// MARK: - Menu callbacks
	
	@IBAction func menuPreferencesClicked(_ sender: NSMenuItem) {
		if let preferencesWindow = preferencesWindowController.window {
			self.window.beginSheet(preferencesWindow)
		}
	}
	
	@IBAction func menuFileMenuNewClicked(_ sender: NSMenuItem) {
		NSLog("Menu: File->New")
	}
	
	@IBAction func menuFileMenuOpenClicked(_ sender: NSMenuItem) {
		NSLog("Menu: File->Open")
        
        let dialog = NSOpenPanel()
        dialog.title                   = "Load script"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = true
        dialog.canChooseDirectories    = false
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["json"]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let result = dialog.url {
                loadJSON(url: result)
            } else {
                return
            }
        }
    }
	
	@IBAction func menuFileMenuCloseClicked(_ sender: NSMenuItem) {
		NSLog("Menu: File->Close")
	}
	
	@IBAction func menuFileMenuSaveClicked(_ sender: NSMenuItem) {
		NSLog("Menu: File->Save")
        
        let dialog = NSSavePanel()
        dialog.title                   = "Save script"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = true
        dialog.canCreateDirectories    = true
        dialog.allowedFileTypes        = ["json"]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let result = dialog.url {
                saveJSON(url: result)
            }
        }
	}
	
	@IBAction func menuFileMenuSaveAsClicked(_ sender: NSMenuItem) {
		NSLog("Menu: File->SaveAs")
	}
	
	@IBAction func menuFileMenuRevertToSavedClicked(_ sender: NSMenuItem) {
		NSLog("Menu: File->Revert to Saved")
	}
    @IBAction func menuTempMenuRegisterPathClicked(_ sender: NSMenuItem) {
        GameScene.me!.selectionDelegateDraw.finalizePath(close: false)
    }
    
    
    @IBAction func menuTempMenuSelectPathClicked(_ sender: NSMenuItem) {
        GameScene.me!.pathForNextPathGoal = sender.tag
    }
}

// MARK: - TopBarDelegate

extension AppDelegate: TopBarDelegate {
    
	func topBar(_ controller: TopBarController, actionChangedTo action: TopBarController.Action, for object: TopBarController.Object) {
        GameScene.me!.selectionDelegate.deselectAll()
        
        switch action {
        case .Place:
            GameScene.me!.selectionDelegate = GameScene.me!.selectionDelegatePrimary
        case .Draw:
            GameScene.me!.selectionDelegate = GameScene.me!.selectionDelegateDraw
        case .Edit: break
        }
	}
	
    func topBar(_ controller: TopBarController, obstacleSelected index: Int) {
        if 0..<obstacles.count ~= index {
            NSLog("Obstacle selected")
            
            GameScene.me!.selectionDelegate.deselectAll()


            editedObstacleIndex = index
            self.removeAgentFrames()
        }
    }
    
    func topBar(_ controller: TopBarController, agentSelected index: Int) {
        if 0..<agents.count ~= index {
            NSLog("Agent selected")
            
            GameScene.me!.selectionDelegate.deselectAll()
            agentImageIndex = index
        }
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
        NSLog("Speed: %f", newSpeed)
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
        } else if let motivator = item as? GKGoal {
            let index = GameScene.me!.getPrimarySelectionIndex()!
            let agent = GameScene.me!.entities[index].agent
            let composite = agent.behavior as! AFCompositeBehavior
            
            parentOfNewMotivator = composite.findParent(ofGoal: motivator)
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
        else if item is GKGoal {
            let gkGoal = item as! GKGoal

            let index = GameScene.me!.getPrimarySelectionIndex()!
            let agent = GameScene.me!.entities[index].agent
            let composite = agent.behavior as! AFCompositeBehavior
            let behavior = composite.findParent(ofGoal: gkGoal)
            let afGoal = behavior!.goalsMap[gkGoal]!
            
            var attributes = [String]()

            switch afGoal.goalType {
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
 
            editorController.setValue(ofSlider: "Angle", to: Double(afGoal.angle), resetDirtyFlag: true)
            editorController.setValue(ofSlider: "Distance", to: Double(afGoal.distance), resetDirtyFlag: true)
            editorController.setValue(ofSlider: "Speed", to: Double(afGoal.speed), resetDirtyFlag: true)
            editorController.setValue(ofSlider: "Time", to: Double(afGoal.time), resetDirtyFlag: true)
            editorController.setValue(ofSlider: "Weight", to: Double(afGoal.weight), resetDirtyFlag: true)
            editorController.preview = true
        
            let itemRect = mainView.convert(rect, from: agentGoalsController.view)
            self.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
        }
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, item: Any, setState state: NSControl.StateValue) {
        if let behavior = item as? AFBehavior {
            let index = GameScene.me!.getPrimarySelectionIndex()!
            let agent = GameScene.me!.entities[index].agent
            let composite = agent.behavior as! AFCompositeBehavior
            
            if state == .on {
                composite.enableBehavior(behavior, on: true)
                agentGoalsController.outlineView!.expandItem(item)
            } else {
                composite.enableBehavior(behavior, on: false)
                agentGoalsController.outlineView!.collapseItem(item)
            }
        }
        else if let gkGoal = item as? GKGoal {
            let behavior = agentGoalsController.outlineView.parent(forItem: item) as! AFBehavior
            let afGoal = behavior.goalsMap[gkGoal]!

            behavior.enableGoal(afGoal, on: state == .on)
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
        case .toSeparateFrom:   attributeList = ["Angle", "Distance"] + attributeList

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
    
    func getParentForNewMotivator() -> AFBehavior {
        if let p = parentOfNewMotivator { return p }
        else {
            let agentIndex = GameScene.me!.getPrimarySelectionIndex()!
            let entity = GameScene.me!.entities[agentIndex]
            return (entity.agent.behavior! as! GKCompositeBehavior)[0] as! AFBehavior
        }
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
        
        // Behaviors and goals always have a weight, thus a weight slider
        let weight = Float(controller.value(ofSlider: "Weight")!)
        
        if let behavior = controller.editedItem as? AFBehavior {
            // Edit existing behavior
            behavior.weight = weight
            (entity.agent.behavior! as! AFCompositeBehavior).setWeight(weight, for: behavior)
        } else if let gkGoal = controller.editedItem as? GKGoal {
            let index = GameScene.me!.getPrimarySelectionIndex()!
            let agent = GameScene.me!.entities[index].agent
            let composite = agent.behavior as! AFCompositeBehavior
            let behavior = composite.findParent(ofGoal: gkGoal)
            let afGoal = behavior!.goalsMap[gkGoal]!

            // Edit existing goal -- note AFBehavior doesn't give us a way
            // to update the goal. If we want to assign any new values to
            // this goal, we just have to throw it away and make a new one.
            var replacementGoalRequired = false
            for name in ["Angle", "Distance", "Speed", "Time"] {
                if controller.valueChanged(sliderName: name) {
                    replacementGoalRequired = true; break
                }
            }

            // However, the weight of the goal is managed by the behavior.
            // So if all we're updating is the weight, we can just change that
            // directly in the behavior, without creating a new goal.
            if replacementGoalRequired {
                let newGoal = AFGoal.makeGoal(copyFrom: afGoal)
                
                newGoal.weight = weight

                if let angle = angle { newGoal.angle = Float(angle) }
                if let distance = distance { newGoal.distance = Float(distance) }
                if let speed = speed { newGoal.speed = Float(speed) }
                if let time = time { newGoal.time = Float(time) }
                
                parentOfNewMotivator.remove(afGoal)
                parentOfNewMotivator.setWeightage(weight, for: newGoal)
            } else {
                afGoal.weight = weight
                parentOfNewMotivator.setWeightage(weight, for: afGoal)
            }
        } else {
            // Add new goal or behavior
            if let type = controller.newItemType {
                var goal: AFGoal?
                var group = GameScene.me!.getSelectedAgents()
                
                var names = [String]()
                for agent in group {
                    names.append((agent as! AFAgent2D).name)
                }

                switch type {
                case .toAlignWith:
                    let primarySelection = GameScene.me!.getPrimarySelectionIndex()!
                    let primarySelected = GameScene.me!.entities[primarySelection] as AFEntity

                    goal = AFGoal(toAlignWith: names, maxDistance: Float(distance!), maxAngle: Float(angle!), weight: weight)

                    // Secondary selections align with primary and with each other.
                    // Primary doesn't do anything.
                    for agent in group {
                        let afAgent = agent as! AFAgent2D
                        
                        if afAgent.name != primarySelected.name {
                            afAgent.addGoal(goal!)
                        }
                    }
                    
                    goal = nil
                    
                case .toAvoidObstacles:
                    let pathIndex = GameScene.me!.pathForNextPathGoal
                    let pathname = GameScene.me!.pathnames[pathIndex]
                    let afPath = GameScene.me!.paths[pathname]!
                    let outline = afPath.makeObstacle()
                    
                    goal = AFGoal(toAvoidObstacles: [outline], time: time!, weight: weight)
                    
                    goal!.pathname = pathname
                    
                case .toAvoidAgents:
                    let primarySelection = GameScene.me!.getPrimarySelectionIndex()!
                    let primarySelected = GameScene.me!.entities[primarySelection] as AFEntity
                    
                    var agentNames = [String]()
                    for gkAgent in group {
                        let afAgent = gkAgent as! AFAgent2D
                        agentNames.append(afAgent.name)
                    }
                    
                    for (i, _) in group.enumerated() {
                        let agent = group[i] as! AFAgent2D
                        if agent.name == primarySelected.agent.name {
                            group.remove(at: i)
                            break;
                        }
                    }
                    
                    goal = AFGoal(toAvoidAgents: agentNames, time: time!, weight: weight)
                    primarySelected.agent.addGoal(goal!)
                    
                    goal = nil
                    
                case .toCohereWith:
                    goal = AFGoal(toCohereWith: names, maxDistance: Float(distance!), maxAngle: Float(angle!), weight: weight)
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
                    let nameOfAgentToFlee = GameScene.me!.entities[secondarySelectionIndex].agent.name
                    goal = AFGoal(toFleeAgent: nameOfAgentToFlee, weight: weight)
                    
                case .toFollow:
                    let pathIndex = GameScene.me!.pathForNextPathGoal
                    let pathname = GameScene.me!.pathnames[pathIndex]
                    let afPath = GameScene.me!.paths[pathname]!
                    goal = AFGoal(toFollow: afPath.gkPath!, time: Float(time!), forward: true, weight: weight)
                    
                    goal!.pathname = pathname
                    
                case .toInterceptAgent:
                    let selectedIndexes = GameScene.me!.getSelectedIndexes()
                    guard selectedIndexes.count == 2 else { return }

                    let indexesAsArray = Array(selectedIndexes)
                    let secondaryAgentIndex = indexesAsArray[1]
                    let targetAgentName = GameScene.me!.entities[secondaryAgentIndex].agent.name
                    goal = AFGoal(toInterceptAgent: targetAgentName, time: time!, weight: weight)

                case .toSeekAgent:
                    var selectedIndexes = GameScene.me!.getSelectedIndexes()
                    guard selectedIndexes.count == 2 else { return }

                    let p = selectedIndexes.remove(GameScene.me!.getPrimarySelectionIndex()!)
                    selectedIndexes.remove(p!)
                    
                    let secondaryAgentIndex = selectedIndexes.first!
                    let targetAgentName = GameScene.me!.entities[secondaryAgentIndex].agent.name
                    goal = AFGoal(toSeekAgent: targetAgentName, weight: weight)

                case .toSeparateFrom:
                    goal = AFGoal(toSeparateFrom: names, maxDistance: Float(distance!), maxAngle: Float(angle!), weight: weight)
                    for agent in group {
                        (agent as! AFAgent2D).addGoal(goal!)
                    }
                    
                    goal = nil

                case .toStayOn:
                    let pathIndex = GameScene.me!.pathForNextPathGoal
                    let pathname = GameScene.me!.pathnames[pathIndex]
                    let afPath = GameScene.me!.paths[pathname]!
                    goal = AFGoal(toStayOn: afPath.gkPath!, time: Float(time!), weight: weight)
                    
                    goal!.pathname = pathname

                case .toReachTargetSpeed:
                    goal = AFGoal(toReachTargetSpeed: Float(speed!), weight: weight)
                    
                case .toWander:
                    goal = AFGoal(toWander: Float(speed!), weight: weight)
                }

                if goal != nil {
                    parentOfNewMotivator.addGoal(goal!)
                }
            } else {
                let behavior = AFBehavior(agent: entity.agent)
                behavior.weight = weight
                (entity.agent.behavior as! AFCompositeBehavior).setWeight(behavior.weight, for: behavior)
            }
		}

        AppDelegate.agentEditorController.refresh()
		activePopover?.close()
	}
	
	func itemEditorCancelPressed(_ controller: ItemEditorController) {
		activePopover?.close()
	}
	
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
	
	func popoverDidClose(_ notification: Notification) {
		activePopover = nil
	}
	
}

