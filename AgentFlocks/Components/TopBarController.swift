//
//  TopBarController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 14/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

protocol TopBarDelegate {
	func topBar(_ controller: TopBarController, actionChangedTo action: TopBarController.Action, for object: TopBarController.Object)
	func topBar(_ controller: TopBarController, obstacleSelected index:Int)
	func topBar(_ controller: TopBarController, agentSelected index:Int)
	func topBar(_ controller: TopBarController, library index:Int, stateChanged enabled:Bool)
	func topBar(_ controller: TopBarController, statusChangedTo newStatus: TopBarController.Status)
	func topBar(_ controller: TopBarController, speedChangedTo newSpeed:Double)
}

class TopBarController: NSViewController {
	
	enum Status {
		case Running
		case Paused
	}
	
	enum Action {
		case Place
		case Draw
		case Edit
	}
	
	enum Object {
		case Agent
		case Path
		case Obstacle
	}
	
	// MARK: - Attributes (private)

	@IBOutlet private weak var imageView: ActiveImageView!
	@IBOutlet private weak var recallAgentsButton: NSButton!
	@IBOutlet private weak var playPauseButton: NSButton!
	@IBOutlet private weak var sliderContainerView: NSView!
    
    @IBOutlet weak var radioButtonVerbBox: NSBox!
    @IBOutlet weak var radioButtonVerbView: NSView!
    @IBOutlet weak var radioButtonPlace: NSButton!
    @IBOutlet weak var radioButtonEdit: NSButton!
    @IBOutlet weak var radioButtonDraw: NSButton!
    
    @IBOutlet weak var radioButtonAgent: NSButton!
    @IBOutlet weak var radioButtonObstacle: NSButton!
    @IBOutlet weak var radioButtonPath: NSButton!
    
    
	private var action = Action.Place
	private var object = Object.Agent

	private let playImage = NSImage(named: NSImage.Name(rawValue: "Play"))
	private let pauseImage = NSImage(named: NSImage.Name(rawValue: "Pause"))
	
	private var activePopover:NSPopover?
	
	private(set) var activeAgentImage:NSImage?
	private(set) var activeObstacleImage:NSImage?
	
	private let speedSliderController = LogSliderController()

	// MARK: - Attributes (public)
	
	var delegate:TopBarDelegate?

	var agentImages = [NSImage]() {
		didSet {
			activeAgentImage = agentImages.first
		}
	}
	var obstacleImages = [NSImage]() {
		didSet {
			activeObstacleImage = obstacleImages.first
		}
	}
	
	var speed:Double {
		get {
			return speedSliderController.value
		}
		set {
			speedSliderController.value = newValue
		}
	}
	
	var play:Bool = true {
		didSet {
			if let image = play ? pauseImage : playImage {
				playPauseButton.image = image
			}
		}
	}

	// MARK: - Initialization
	
	init() {
		super.init(nibName: NSNib.Name(rawValue: "TopBarView"), bundle: nil)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		imageView!.delegate = self
		
		// Set play to the same value (this invokes UI actualization)
		self.play = self.play ? true : false
		
		speedSliderController.sliderName = "Speed:"
		speedSliderController.delegate = self
		
		// Add speed slider view to topbar
		speedSliderController.addToView(sliderContainerView)
		
		actualizeLayout()
	}

	// MARK: - Actions and methods (private)
	
	private func actualizeLayout() {
		switch object {
		case .Agent:
			imageView.image = self.activeAgentImage
			imageView.isHidden = false
		case .Obstacle:
			imageView.image = self.activeObstacleImage
			imageView.isHidden = false
		case .Path:
			imageView.isHidden = true
		}
        
        switch action {
        case .Draw:
            if radioButtonAgent.state == NSControl.StateValue.on {
                self.object = .Path
                radioButtonAgent.state = NSControl.StateValue.off
                radioButtonPath.state = NSControl.StateValue.on
            }
            radioButtonAgent.isEnabled = false
        case .Place:
            radioButtonAgent.isEnabled = true
        case .Edit: break
        }
	}
	
	private func showPopover(withTitle title:String, andImages images:[NSImage], forView view:NSView) {
		
		guard let mainView = NSApp.mainWindow?.contentView else { return }
        
		// Create popover content
		let contentController = ImagesListController()
		contentController.listTitle = title
		contentController.imageData = images
		contentController.delegate = self
		
		// Create popover
		let popover = NSPopover()
		popover.behavior = .transient
		popover.animates = false
		popover.delegate = self
		popover.contentViewController = contentController
		
		// Convert point to main window coordinates
		let entryRect = view.convert(view.bounds, to: mainView)
		
		// Show popover
		popover.show(relativeTo: entryRect, of: mainView, preferredEdge: .minY)
		activePopover = popover
	}
	
	// MARK: - Actions and methods (public)
	
	func setImageFrame(enabled: Bool) {
		imageView.imageFrameStyle = enabled ? .grayBezel : .none
	}

	@IBAction func actionRadioButtonChecked(_ sender: NSButton) {
		switch sender.tag {
		case 2:
			action = .Draw
		case 3:
			action = .Edit
		default:
			action = .Place
		}
		actualizeLayout()
		delegate?.topBar(self, actionChangedTo: action, for: object)
	}
	
	@IBAction func objectRadioButtonChecked(_ sender: NSButton) {
		switch sender.tag {
		case 2:
			object = .Path
		case 3:
			object = .Obstacle
		default:
			object = .Agent
		}
		actualizeLayout()
		delegate?.topBar(self, actionChangedTo: action, for: object)
	}
	
    @IBAction func recallAgents(_ sender: NSButton) {
        for entity in GameScene.me!.entities {
            let spriteContainer = entity.agent.spriteContainer
            
            entity.agent.position.x = 0
            entity.agent.position.y = 0
            spriteContainer.position = CGPoint.zero
        }
    }
	
	@IBAction func libraryCheckButtonChecked(_ sender: NSButton) {
		delegate?.topBar(self, library: sender.tag, stateChanged: sender.state == .on)
	}

	@IBAction private func playClicked(_ sender: NSButton) {
        GameScene.me!.isPaused = !GameScene.me!.isPaused
		self.play = !self.play
		delegate?.topBar(self, statusChangedTo: self.play ? TopBarController.Status.Running : TopBarController.Status.Paused)
	}
	
}

// MARK: -

extension TopBarController: ActiveImageViewDelegate {
	
	func imageView(mouseUpWithEvent event: NSEvent) {
		if object == .Agent {
			self.showPopover(withTitle: "Agents", andImages: self.agentImages, forView: imageView!)
		}
		else if object == .Obstacle {
			self.showPopover(withTitle: "Obstacles", andImages: self.obstacleImages, forView: imageView!)
		}
	}
	
}

// MARK: -

extension TopBarController: LogSliderDelegate {
	
	func logSlider(_ controller: LogSliderController, newValue value: Double) {
		self.speed = value
		delegate?.topBar(self, speedChangedTo: self.speed)
	}
	
}

// MARK: -

extension TopBarController: NSPopoverDelegate {
	
	func popoverDidClose(_ notification: Notification) {
		activePopover = nil
	}
	
}

// MARK: -

extension TopBarController: ImagesListDelegate {
	
	func imagesList(_ controller: ImagesListController, imageIndex: Int) {
		if let popover = activePopover {
			popover.close()
		}
		if controller.listTitle.compare("Agents") == .orderedSame {
			if imageIndex < self.agentImages.count {
				self.activeAgentImage = self.agentImages[imageIndex]
			}
			self.imageView.image = self.activeAgentImage
			delegate?.topBar(self, agentSelected: imageIndex)
		}
		else if controller.listTitle.compare("Obstacles") == .orderedSame {
			if imageIndex < self.obstacleImages.count {
				self.activeObstacleImage = self.obstacleImages[imageIndex]
			}
			self.imageView.image = self.activeObstacleImage
			delegate?.topBar(self, obstacleSelected: imageIndex)
		}
	}
	
}
