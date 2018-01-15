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
	@IBOutlet weak var settingsView: CursorView!
	@IBOutlet weak var libraryStackView: NSStackView!
	@IBOutlet weak var sceneView: CursorView!
	
	@IBOutlet weak var contextMenu: NSMenu!
	
	let configuration = Configuration.shared
	let preferencesWindowController = PreferencesController(windowNibName: NSNib.Name.init(rawValue: "PreferencesWindow"))
	
    let topBarController = TopBarController()
	let topBarControllerPadding:CGFloat = 10.0
	
	static let agentEditorController = AgentEditorController()
    static var me: AppDelegate!
	let leftBarWidth:CGFloat = 300.0
	let rightBarWidth:CGFloat = 300.0

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
    var followPathFoward = true

	private var activePopover:NSPopover?
	private var libraryControllers = [Int:ImagesListController]()
    
    var parentOfNewMotivator: AFBehavior?
    
    var behaviorMap = [GKGoal : AFBehavior]()
	
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
		sceneView.cursor = .pointingHand
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
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
    
	func placeAgentFrames(agentName: String) {
        let agent = AFCore.data.entities[agentName].agent
        let ac = AppDelegate.agentEditorController.attributesController
        let gc = AppDelegate.agentEditorController.goalsController

        // Play/pause button image
        gc.playButton.image = agent.isPlaying ? gc.pauseImage : gc.playImage

        // This is where we finally read back out the actual
        // values from the GKAgent and store them in the attributes controller
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

	func showContextMenu(at location: NSPoint) {
		contextMenu.popUp(positioning: nil, at: location, in: sceneView)
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
                AFCore.menuBarDelegate.fileOpen(result)
            } else {
                return
            }
        }
    }
	
	@IBAction func menuFileMenuCloseClicked(_ sender: NSMenuItem) {
		NSLog("Menu: File->Close")
	}
	
	@IBAction func menuFileMenuSaveClicked(_ sender: NSMenuItem) {
        let dialog = NSSavePanel()
        dialog.title                   = "Save script"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = true
        dialog.canCreateDirectories    = true
        dialog.allowedFileTypes        = ["json"]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let result = dialog.url {
                AFCore.menuBarDelegate.fileSave(result)
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
        GameScene.me!.inputState.finalizePath(close: false)
    }
	
    @IBAction func menuTempMenuSelectPathClicked(_ sender: NSMenuItem) {
        GameScene.me!.pathForNextPathGoal = sender.tag
    }
	
	// MARK: - Context Menu callbacks
	
	@IBAction func contextMenuClicked(_ sender: NSMenuItem) {
        switch sender.tag {
        case AFContextMenu.ItemTypes.AddPathToLibrary.rawValue:
           GameScene.me!.inputState.finalizePath(close: true)
            
        case AFContextMenu.ItemTypes.Draw.rawValue:
            topBarController.radioButtonDraw.state = NSControl.StateValue.on
            topBarController.radioButtonPath.state = NSControl.StateValue.on
            topBarController.radioButtonAgent.isEnabled = false
            GameScene.me!.inputState.enter(AFInputState.ModeDraw.self)

        case AFContextMenu.ItemTypes.CloneAgent.rawValue:
            let input = GameScene.me!.inputState!
            let originalEntity = AFCore.data.entities[input.upNodeName!]
            let currentPosition = input.currentPosition

            _ = AFCore.data.createEntity(scene: GameScene.me!, copyFrom: originalEntity, position: currentPosition)
            
        case AFContextMenu.ItemTypes.Place.rawValue:
            topBarController.radioButtonPlace.state = NSControl.StateValue.on
            topBarController.radioButtonAgent.state = NSControl.StateValue.on
            topBarController.radioButtonAgent.isEnabled = true
            GameScene.me!.inputState.enter(AFInputState.ModePlace.self)
            
        case AFContextMenu.ItemTypes.SetObstacleCloneStamp.rawValue:
            GameScene.me!.inputState.setObstacleCloneStamp()
            
        case AFContextMenu.ItemTypes.StampObstacle.rawValue:
            let currentPosition = GameScene.me!.inputState.currentPosition
            GameScene.me!.inputState.stampObstacle(at: currentPosition)

        default:
            fatalError()
        }
	}
	
}

// MARK: - TopBarDelegate

extension AppDelegate: TopBarDelegate {
    
	func topBar(_ controller: TopBarController, actionChangedTo action: TopBarController.Action, for object: TopBarController.Object) {
        switch action {
        case .Place:
            GameScene.me!.inputState.enter(AFInputState.ModePlace.self)
        case .Draw:
            GameScene.me!.inputState.enter(AFInputState.ModeDraw.self)
        case .Edit: break
        }
	}
	
    func topBar(_ controller: TopBarController, obstacleSelected index: Int) {
        if 0..<obstacles.count ~= index {
            NSLog("Obstacle selected")
//
//            GameScene.me!.selectionDelegate.deselectAll()
//
//
//            editedObstacleIndex = index
//            self.removeAgentFrames()
        }
    }
    
    func topBar(_ controller: TopBarController, agentSelected index: Int) {
//        if 0..<agents.count ~= index {
//            NSLog("Agent selected")
//            
//            GameScene.me!.selectionDelegate.deselectAll()
//            agentImageIndex = index
//        }
    }
	
	func topBar(_ controller: TopBarController, library index: Int, stateChanged enabled: Bool) {
		if enabled {
			// library checkbox enabled
			let controller = libraryControllers[index] ?? ImagesListController(withBorder: .noBorder,
																			   andInsets: NSEdgeInsets(top: 0.0, left: 8.0, bottom: 8.0, right: 8.0))
			controller.type = .checkbox
			controller.delegate = self
			
            switch AFBrowserType(rawValue: index)! {
            case .SpriteImages:
                var agentImages = [NSImage]()
                for agent in agents {
                    agentImages.append(agent.image)
                }
                controller.imageData = agentImages

            case .Agents:
                var agentImages = [NSImage]()

                for entity in AFCore.data.entities {
                    let sprite = entity.agent.sprite
                    let cgImage = sprite.texture!.cgImage()
                    let nsImage = NSImage(cgImage: cgImage, size: sprite.size)
                    agentImages.append(nsImage)
                }
                
                controller.imageData = agentImages

            case .Paths:
                var pathImages = [NSImage]()
                AFCore.data.paths.forEach {
                    let s = CGSize(width: 50, height: 50)
                    pathImages.append($0.getImageData(size: s))
                }
                controller.imageData = pathImages

            case .LinkedGoals: fallthrough
                
            default:
                fatalError()
            }

			// Add view to stack container
			libraryControllers[index] = controller
			libraryStackView.addView(controller.view, in: .top)
			
			NSLayoutConstraint(item: controller.view,
							   attribute: .width,
							   relatedBy: .equal,
							   toItem: nil,
							   attribute: .notAnAttribute,
							   multiplier: 1.0,
							   constant: rightBarWidth).isActive = true
			NSLayoutConstraint(item: controller.view,
							   attribute: .height,
							   relatedBy: .equal,
							   toItem: nil,
							   attribute: .notAnAttribute,
							   multiplier: 1.0,
							   constant: rightBarWidth).isActive = true
		}
		else {
			// library checkbox disabled
			if let controller = libraryControllers[index] {
				controller.view.removeFromSuperview()
				libraryControllers.removeValue(forKey: index)
			}
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

    func agentGoalsPlayClicked(_ agentGoalsController: AgentGoalsController, actionPlay: Bool) {
        let name = GameScene.me!.getPrimarySelectionName()!
        let agent = AFCore.data.entities[name].agent
        
        agent.isPlaying = actionPlay
    }
    
    func agentGoalsDeleteItem(_ agentGoalsController: AgentGoalsController) {
        let name = GameScene.me!.getPrimarySelectionName()!
        let agent = AFCore.data.entities[name].agent
        let composite = agent.behavior as! AFCompositeBehavior
        
        if let outlineView = agentGoalsController.outlineView {
            let row = outlineView.selectedRow
            let protoItem = outlineView.item(atRow: row)
            var reloadOutline = false

            if let hotBehavior = protoItem as? AFBehavior {
                reloadOutline = true
                composite.remove(hotBehavior)
            } else if let hotGoal = protoItem as? GKGoal {
                let hotBehavior = composite.findParent(ofGoal: hotGoal)!
                reloadOutline = true
                hotBehavior.remove(hotGoal)
            }
            
            if reloadOutline { outlineView.reloadData() }
        }
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, itemClicked item: Any, inRect rect: NSRect) {
        if let motivator = item as? AFBehavior {
            parentOfNewMotivator = motivator
        } else if let motivator = item as? GKGoal {
            let name = GameScene.me!.getPrimarySelectionName()!
            let agent = AFCore.data.entities[name].agent
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

            let name = GameScene.me!.getPrimarySelectionName()!
            let agent = AFCore.data.entities[name].agent
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
            editorController.editedAFGoal = afGoal
 
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
            let name = GameScene.me!.getPrimarySelectionName()!
            let agent = AFCore.data.entities[name].agent
            let composite = agent.behavior as! AFCompositeBehavior
            
            if state == .on {
                composite.enableBehavior(behavior, on: true)
            } else {
                composite.enableBehavior(behavior, on: false)
            }
            
			for gkGoal in behavior.goalsMap.keys {
				agentGoalsController.outlineView!.reloadItem(gkGoal, reloadChildren: false)
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
    
    func retransmitGoal(controller: ItemEditorController, afGoal: AFGoal) {
        let newGoal = AFGoal.makeGoal(copyFrom: afGoal, weight: afGoal.weight)

        let angle = controller.value(ofSlider: "Angle")
        let distance = controller.value(ofSlider: "Distance")
        let speed = controller.value(ofSlider: "Speed")
        let time = controller.value(ofSlider: "Time")

        // Everyone has a weight
        let weight = Float(controller.value(ofSlider: "Weight")!)

        if let angle = angle { newGoal.angle = Float(angle) }
        if let distance = distance { newGoal.distance = Float(distance) }
        if let speed = speed { newGoal.speed = Float(speed) }
        if let time = time { newGoal.time = Float(time) }

        newGoal.weight = weight

        parentOfNewMotivator!.remove(afGoal)
        parentOfNewMotivator!.setWeightage(weight, for: newGoal)
        controller.editedAFGoal = newGoal

        AgentGoalsController.me!.outlineView.reloadData()
    }
    
    func getParentForNewMotivator() -> AFBehavior {
        if let p = parentOfNewMotivator { return p }
        else {
            let agentName = GameScene.me!.getPrimarySelectionName()!
            let entity = AFCore.data.entities[agentName]
            return (entity.agent.behavior! as! GKCompositeBehavior)[0] as! AFBehavior
        }
    }
	
	func itemEditorApplyPressed(_ controller: ItemEditorController) {
        let selectedNames = GameScene.me!.getSelectedNames()
        guard selectedNames.count > 0 else { return }

        let agentName = GameScene.me!.getPrimarySelectionName()!
        let entity = AFCore.data.entities[agentName]
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
        } else if let _ = controller.editedItem as? GKGoal {
            let afGoal = controller.editedAFGoal!

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
                retransmitGoal(controller: controller, afGoal: afGoal)
            } else {
                afGoal.weight = weight
                parentOfNewMotivator.setWeightage(weight, for: afGoal)
            }
        } else {
            // Add new goal or behavior
            if let type = controller.newItemType {
                var goal: AFGoal?
                var group = GameScene.me!.getSelectedNames()
                let names = Array(group)

                switch type {
                case .toAlignWith:
                    let primarySelection = GameScene.me!.getPrimarySelectionName()!
                    let primarySelected = AFCore.data.entities[primarySelection] as AFEntity

                    goal = AFGoal(toAlignWith: names, maxDistance: Float(distance!), maxAngle: Float(angle!), weight: weight)

                    // Secondary selections align with primary and with each other.
                    // Primary doesn't do anything.
                    for agentName in group {
                        let afAgent = AFCore.data.entities[agentName].agent
                        
                        if afAgent.name != primarySelected.name {
                            afAgent.addGoal(goal!)
                        }
                    }
                    
                    goal = nil
                    
                case .toAvoidObstacles:
                    goal = AFGoal(toAvoidObstacles: Array(AFCore.data.obstacles.keys), time: time!, weight: weight)
                    
                case .toAvoidAgents:
                    let primarySelection = GameScene.me!.getPrimarySelectionName()!
                    let primarySelected = AFCore.data.entities[primarySelection] as AFEntity
                    
                    let agentNames = Array(group)
                    
                    if let ix = group.index(of: primarySelected.agent.name) {
                        group.remove(at: ix)
                    }
                    
                    goal = AFGoal(toAvoidAgents: agentNames, time: time!, weight: weight)
                    primarySelected.agent.addGoal(goal!)
                    
                    goal = nil
                    
                case .toCohereWith:
                    goal = AFGoal(toCohereWith: names, maxDistance: Float(distance!), maxAngle: Float(angle!), weight: weight)
                    for agentName in group {
                        AFCore.data.entities[agentName].agent.addGoal(goal!)
                    }
                    
                    goal = nil
                    
                case .toFleeAgent:
                    let selectedNames = GameScene.me!.getSelectedNames()
                    guard selectedNames.count == 2 else { return }
                    
                    var si = selectedNames.union(Set<String>())
                    si.remove(GameScene.me!.getPrimarySelectionName()!)
                    
                    let nameOfAgentToFlee = si.first!
                    goal = AFGoal(toFleeAgent: nameOfAgentToFlee, weight: weight)
                    
                case .toFollow:
                    let pathIndex = GameScene.me!.pathForNextPathGoal
                    let pathname = AFCore.data.paths[pathIndex].name
                    goal = AFGoal(toFollow: pathname, time: Float(time!), forward: followPathFoward, weight: weight)
                    
                    goal!.pathname = pathname

                case .toInterceptAgent:
                    let selectedNames = GameScene.me!.getSelectedNames()
                    guard selectedNames.count == 2 else { return }

                    let namesAsArray = Array(selectedNames)
                    let secondaryAgentName = namesAsArray[1]
                    goal = AFGoal(toInterceptAgent: secondaryAgentName, time: time!, weight: weight)

                case .toSeekAgent:
                    var selectedNames = GameScene.me!.getSelectedNames()
                    guard selectedNames.count == 2 else { return }

                    let p = selectedNames.remove(GameScene.me!.getPrimarySelectionName()!)
                    selectedNames.remove(p!)
                    
                    let secondaryAgentName = selectedNames.first!
                    goal = AFGoal(toSeekAgent: secondaryAgentName, weight: weight)

                case .toSeparateFrom:
                    goal = AFGoal(toSeparateFrom: names, maxDistance: Float(distance!), maxAngle: Float(angle!), weight: weight)
                    for agentName in group {
                        AFCore.data.entities[agentName].agent.addGoal(goal!)
                    }
                    
                    goal = nil

                case .toStayOn:
                    let pathIndex = GameScene.me!.pathForNextPathGoal
                    let pathname = AFCore.data.paths[pathIndex].name
                    goal = AFGoal(toStayOn: pathname, time: Float(time!), weight: weight)
                    
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

extension AppDelegate: LogSliderDelegate {
    func logSlider(_ controller: LogSliderController, newValue value: Double) {
        if let itemEditorController = controller.parentItemEditorController {
            if itemEditorController.preview {
                let afGoal = itemEditorController.editedAFGoal!
                retransmitGoal(controller: itemEditorController, afGoal: afGoal)
            }
        }
    }
}


// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
	
	func popoverDidClose(_ notification: Notification) {
		activePopover = nil
	}
	
}

// MARK: - ImagesListDelegate

extension AppDelegate: ImagesListDelegate {
	
	func imagesList(_ controller: ImagesListController, imageSelected index: Int) {
		let controllerIndexArray = libraryControllers.filter { (key, value) -> Bool in
			return value == controller
		}.keys
        
		if let controllerIndex = controllerIndexArray.first {
            AFCore.browserDelegate.imageSelected(controllerIndex: controllerIndex, imageIndex: index)
		}
	}
	
	func imagesList(_ controller: ImagesListController, imageIndex index: Int, wasEnabled enabled: Bool) {
		let controllerIndexArray = libraryControllers.filter { (key, value) -> Bool in
			return value == controller
			}.keys
		if let controllerIndex = controllerIndexArray.first {
            AFCore.browserDelegate.imageEnabled(controllerIndex: controllerIndex, imageIndex: index, enabled: enabled)
		}
	}

}
