//
//  AppDelegate.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 14/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

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
	
    let agentEditorController = AgentEditorController()
	let leftBarWidth:CGFloat = 300.0
	let rightBarWidth:CGFloat = 300.0

    var sceneController = SceneController()
	
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
    
    var coreAgentGoalsDelegate: AFAgentGoalsDelegate!
    var coreBrowserDelegate: AFBrowserDelegate!
    var coreContextMenuDelegate: AFContextMenuDelegate!
    var coreItemEditorDelegate: AFItemEditorDelegate!
    var coreMenuBarDelegate: AFMenuBarDelegate!
    var coreTopBarDelegate: AFTopBarDelegate!
    
    var uiNotifications = Foundation.NotificationCenter()
    
    var agentGoalsDataSource: AgentGoalsDataSource!
    var gameScene: GameScene!
    static var me: AppDelegate!
	
	func applicationWillFinishLaunching(_ notification: Foundation.Notification) {
		
		if let screenFrame = NSScreen.main?.frame {
			self.window.setFrame(screenFrame, display: true)
		}
	}
	
	func applicationDidFinishLaunching(_ aNotification: Foundation.Notification) {
		
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
        
        window.acceptsMouseMovedEvents = true
        
        agentEditorController.goalsController.delegate = self
        
        topBarController.delegate = self
        
        topBarController.agentImages = agentImages
        topBarController.obstacleImages = obstacleImages
        
        setupTopBarView()
        setupSceneView()

        AppDelegate.me = self
        GameScene.me.gameSceneDelegate = AFCore.makeCore(ui: AppDelegate.me, gameScene: GameScene.me)
	}

    func inject(_ injector: AFCore.AFDependencyInjector) {
        var iStillNeedSomething = false
        
        if let gs = injector.gameScene { gameScene = gs }
        else { injector.someoneStillNeedsSomething = true; iStillNeedSomething = true }
        
        if let mr = injector.agentGoalsDataSource { self.agentEditorController.goalsController.dataSource = mr }
        else { injector.someoneStillNeedsSomething = true; iStillNeedSomething = true }

        iStillNeedSomething = agentEditorController.attributesController.inject(injector) || iStillNeedSomething
        
        // Once we have all our external dependencies setup, we can
        // take care of our post-init.
        if !iStillNeedSomething {
            injector.uiNotifications = self.uiNotifications
            
            coreAgentGoalsDelegate = injector.agentGoalsDelegate
            coreBrowserDelegate = injector.browserDelegate
            coreContextMenuDelegate = injector.contextMenuDelegate
            coreItemEditorDelegate = injector.itemEditorDelegate
            coreMenuBarDelegate = injector.menuBarDelegate
            coreTopBarDelegate = injector.topBarDelegate
            
            // Ignore selections until I can get the new agent up and running
            
            let select = NSNotification.Name(rawValue: AFSceneController.NotificationType.Selected.rawValue)
            self.uiNotifications.addObserver(self, selector: #selector(itemSelected(notification:)), name: select, object: nil)
            
            let deselect = NSNotification.Name(rawValue: AFSceneController.NotificationType.Deselected.rawValue)
            self.uiNotifications.addObserver(self, selector: #selector(itemDeselected(notification:)), name: deselect, object: nil)

            // Strange, I had to paste this line from removeAgentFrames() in order to
            // get the agent editing panels to display. I could take some guesses
            // about what difference this makes, but I'll just wait to ask Gergely
            // next time I talk to him.
            agentEditorController.view.translatesAutoresizingMaskIntoConstraints = true
        }
    }
    
    @objc func itemSelected(notification: Foundation.Notification) {
        let decoded = AFSceneController.Notification.Decode(notification)

        if let name = AFSceneController.Notification.Decode(notification).name,
            let isPrimarySelection = decoded.isPrimarySelection,
            isPrimarySelection == true {

            let adapter = AFNodeAdapter(gameScene: gameScene, name: name)
            placeAgentFrames(node: adapter.node)
        }
    }
    
    @objc func itemDeselected(notification: Foundation.Notification) {
        if let name = AFSceneController.Notification.Decode(notification).name {
            if AFNodeAdapter(gameScene: gameScene, name: name).isPrimarySelection {
                agentEditorController.attributesController.resetSliderControllers()
                removeAgentFrames()
            }
        } else { fatalError("Notification missing name field") }
    }
    
    func setupSceneView() {
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
    
    func setupTopBarView() {
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
    }
	
	func applicationWillTerminate(_ aNotification: Foundation.Notification) {
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
    
    func placeAgentFrames(node: SKNode) {

		settingsView.addSubview(agentEditorController.view)
        agentEditorController.refresh()
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
//                AFCore.menuBarDelegate.fileOpen(result)
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
                coreMenuBarDelegate.fileSave(result)
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
        coreMenuBarDelegate.tempRegisterPath()
    }
	
    @IBAction func menuTempMenuSelectPathClicked(_ sender: NSMenuItem) {
        coreMenuBarDelegate.tempSelectPath(ix: sender.tag)
    }
	
	// MARK: - Context Menu callbacks
	
	@IBAction func contextMenuClicked(_ sender: NSMenuItem) {
        switch AFContextMenu.ItemTypes(rawValue: sender.tag)! {
        case .AddPathToLibrary:
            coreContextMenuDelegate.itemAddPathToLibrary()
            
        case .Draw:
            topBarController.radioButtonDraw.state = NSControl.StateValue.on
            topBarController.radioButtonPath.state = NSControl.StateValue.on
            topBarController.radioButtonAgent.isEnabled = false

        case .CloneAgent:
            coreContextMenuDelegate.itemCloneAgent()
            
        case .Place:
            topBarController.radioButtonPlace.state = NSControl.StateValue.on
            topBarController.radioButtonAgent.state = NSControl.StateValue.on
            topBarController.radioButtonAgent.isEnabled = true
            
        case .StampObstacle:
            coreContextMenuDelegate.itemStampObstacle()
        }
	}
	
}

// MARK: - TopBarDelegate

extension AppDelegate: TopBarDelegate {
    
    func recallAgents() {
    }
    
	func topBar(_ controller: TopBarController, actionChangedTo action: TopBarController.Action, for object: TopBarController.Object) {
        switch action {
        case .Place:
            coreTopBarDelegate.actionPlace()
        case .Draw:
            coreTopBarDelegate.actionDraw()
        case .Edit: break
        }
	}
	
    func topBar(_ controller: TopBarController, obstacleSelected index: Int) {
        // no longer used
    }
    
    func topBar(_ controller: TopBarController, agentSelected index: Int) {
        // no longer used
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
                controller.imageData = coreTopBarDelegate.getActiveAgentImages()

            case .Paths:
                controller.imageData = coreTopBarDelegate.getActivePathImages()

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
        case .Running: coreTopBarDelegate.play()
        case .Paused: coreTopBarDelegate.pause()
        }
    }

    func topBar(_ controller: TopBarController, speedChangedTo newSpeed: Double) {
        coreTopBarDelegate.setSpeed(newSpeed)
    }
	
}

// MARK: - AgentGoalsDelegate

extension AppDelegate: AgentGoalsDelegate {

    func agentGoalsPlayClicked(_ agentGoalsController: AgentGoalsController, actionPlay: Bool) {
        coreAgentGoalsDelegate.play(actionPlay)
    }
    
    func agentGoalsDeleteItem(_ agentGoalsController: AgentGoalsController) {
        if let outlineView = agentGoalsController.outlineView {
            let row = outlineView.selectedRow
            let protoItem = outlineView.item(atRow: row)
            
            coreAgentGoalsDelegate.deleteItem(protoItem! as! String)
            outlineView.reloadData()
        }
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, itemClicked item: Any, inRect rect: NSRect) {
        coreAgentGoalsDelegate.itemClicked(item)
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, itemDoubleClicked item: Any, inRect rect: NSRect) {
        guard let mainView = window.contentView else { return }
        
        let attributeNames = ["Angle", "Distance", "Speed", "Time", "Weight"]
        let attributes = coreAgentGoalsDelegate.getEditableAttributes(for: item, names: attributeNames)
        let editorController = ItemEditorController(withAttributes: Array(attributes.keys), agentEditorController: agentEditorController)

        editorController.delegate = self
        editorController.editedItem = item

        attributeNames.forEach {
            if attributes.contains($0) {
                editorController.setValue(ofSlider: $0, to: attributes[$0]!, resetDirtyFlag: true)
            }
        }
    
        let itemRect = mainView.convert(rect, from: agentGoalsController.view)
        self.showPopover(withContentController: editorController, forRect: itemRect, preferredEdge: .minX)
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, item: Any, setState state: NSControl.StateValue) {
        let parent = agentGoalsController.outlineView.parent(forItem: item)
        coreAgentGoalsDelegate.enableItem(item, parent: parent, on: state == .on)
        
//
//        if let updatedItems = coreAgentGoalsDelegate.enableItem(item, parent: parent, on: state == .on) {
//            updatedItems.forEach { agentGoalsController.outlineView!.reloadItem($0, reloadChildren: false) }
//        }
    }

    func agentGoals(_ agentGoalsController: AgentGoalsController, newBehaviorShowForRect rect: NSRect) {
        guard let mainView = window.contentView else { return }
    
        let editorController = ItemEditorController(withAttributes: ["Weight"], agentEditorController: agentEditorController)
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
    
        let editorController = ItemEditorController(withAttributes: attributeList, agentEditorController: agentEditorController)
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

class ItemEditorSlidersState {
    typealias SliderState = (value: Double, didChange: Bool)
    
    var angle: SliderState?
    var distance: SliderState?
    var forward = true
    var editedItem: Any?
    var newItemType: AgentGoalsController.GoalType?
    var speed: SliderState?
    var time: SliderState?
    
    var weight: SliderState
    
    init(_ controller: ItemEditorController) {
        editedItem = controller.editedItem
        newItemType = controller.newItemType
        forward = controller.followPathForward
        
        if let angle = controller.value(ofSlider: "Angle") {
            let didChange = controller.valueChanged(sliderName: "Angle")
            self.angle = (value: angle, didChange: didChange)
        }
        
        if let distance = controller.value(ofSlider: "Distance") {
            let didChange = controller.valueChanged(sliderName: "Distance")
            self.distance = (value: distance, didChange: didChange)
        }
        
        if let speed = controller.value(ofSlider: "Speed") {
            let didChange = controller.valueChanged(sliderName: "Speed")
            self.speed = (value: speed, didChange: didChange)
        }
        
        if let time = controller.value(ofSlider: "Time") {
            let didChange = controller.valueChanged(sliderName: "Time")
            self.time = (value: time, didChange: didChange)
        }
        
        let weight = controller.value(ofSlider: "Weight")!
        let didChange = controller.valueChanged(sliderName: "Weight")
        self.weight = (value: weight, didChange: didChange)
    }
}

extension AppDelegate: ItemEditorDelegate {
   
    func itemEditorApplyPressed(_ controller: ItemEditorController) {
        coreItemEditorDelegate.refreshMotivators(state: ItemEditorSlidersState(controller))
        controller.refreshAffectedControllers()
        activePopover?.close()
    }
	
	func itemEditorCancelPressed(_ controller: ItemEditorController) {
		activePopover?.close()
	}
    
    func itemEditorActivated(_ controller: ItemEditorController) {
        let state = ItemEditorSlidersState(controller)
        let type = state.newItemType
        
        coreItemEditorDelegate.itemEditorActivated(goalType: type)
    }
	
    func itemEditorDeactivated(_ controller: ItemEditorController) {
        coreItemEditorDelegate.itemEditorDeactivated()
    }
}

extension AppDelegate: LogSliderDelegate {
    func logSlider(_ controller: LogSliderController, newValue value: Double) {
        if let itemEditorController = controller.parentItemEditorController {
            if itemEditorController.preview {
                let state = ItemEditorSlidersState(itemEditorController)
                let newSetting = (value: value, didChange: true)
                
                switch controller.sliderName {
                case "Angle": state.angle = newSetting
                case "Distance": state.distance = newSetting
                case "Speed": state.speed = newSetting
                case "Time": state.time = newSetting
                case "Weight": state.weight = newSetting
                default: fatalError()
                }

                coreItemEditorDelegate.sliderChanged(state: ItemEditorSlidersState(itemEditorController))
            }
        }
    }
}


// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
	
	func popoverDidClose(_ notification: Foundation.Notification) {
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
            coreBrowserDelegate.imageSelected(controllerIndex: controllerIndex, imageIndex: index)
		}
	}
	
	func imagesList(_ controller: ImagesListController, imageIndex index: Int, wasEnabled enabled: Bool) {
		let controllerIndexArray = libraryControllers.filter { (key, value) -> Bool in
			return value == controller
			}.keys
		if let controllerIndex = controllerIndexArray.first {
            coreBrowserDelegate.imageEnabled(controllerIndex: controllerIndex, imageIndex: index, enabled: enabled)
		}
	}

}
