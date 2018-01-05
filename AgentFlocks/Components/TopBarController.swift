//
//  TopBarController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 14/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

protocol TopBarDelegate {
	func topBarDrawPath(_ controller: TopBarController)
    func finishPathClicked(_ controller: TopBarController)
    func path0Clicked(_ controller: TopBarController)
    func path1Clicked(_ controller: TopBarController)
    func path2Clicked(_ controller: TopBarController)
    func path3Clicked(_ controller: TopBarController)
    func path4Clicked(_ controller: TopBarController)
    func path5Clicked(_ controller: TopBarController)
    func loadJSON(_ controller: TopBarController)
    func saveJSON(_ controller: TopBarController)
	func topBar(_ controller: TopBarController, obstacleSelected index:Int)
	func topBar(_ controller: TopBarController, imageIndex:Int)
	func topBar(_ controller: TopBarController, flockSelected flock:TopBarController.FlockType)
	func topBar(_ controller: TopBarController, statusChangedTo newStatus: TopBarController.Status)
	func topBar(_ controller: TopBarController, speedChangedTo newSpeed:Double)
}

class TopBarController: NSViewController {
	
	enum Status {
		case Running
		case Paused
	}
	
	enum FlockType {
		case Agents5
		case Agents10
		case Agents15
		case Custom
	}

	// MARK: - Attributes (private)

	@IBOutlet private weak var playPauseButton: NSButton!
	@IBOutlet private weak var sliderContainerView: NSView!
	
	private let playImage = NSImage(named: NSImage.Name(rawValue: "Play"))
	private let pauseImage = NSImage(named: NSImage.Name(rawValue: "Pause"))
	
	private var activePopover:NSPopover?
	
	typealias FlockEntity = (type:FlockType, name:String)
	private let flocks:[FlockEntity] = [	(.Agents5,	"5 agents"),
	                                    	(.Agents10,	"10 agents"),
	                                    	(.Agents15,	"15 agents"),
	                                    	(.Custom,	"Custom...") ]
	
	private let speedSliderController = LogSliderController()

	// MARK: - Attributes (public)
	
	var delegate:TopBarDelegate?

	var agentImages = [NSImage]()
	var obstacleImages = [NSImage]()
	
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
		
		// Set play to the same value (this invokes UI actualization)
		self.play = self.play ? true : false
		
		speedSliderController.sliderName = "Speed:"
		speedSliderController.delegate = self
		
		// Add speed slider view to topbar
		speedSliderController.addToView(sliderContainerView)
	}

	// MARK: - Actions and methods (private)
	
	private func showPopover(withTitle title:String, andImages images:[NSImage], forButton button:NSButton) {
		
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
		let entryRect = button.convert(button.bounds, to: mainView)
		
		// Show popover
		popover.show(relativeTo: entryRect, of: mainView, preferredEdge: .minY)
		activePopover = popover
	}
	
	@objc private func flockMenuItemSelected(_ sender: AnyObject) {
		if let index = sender.tag,
			0..<flocks.count ~= index
		{
			delegate?.topBar(self, flockSelected: flocks[index].type)
		}
	}
    
    @IBAction func path0Clicked(_ sender: NSButton) {
        delegate?.path0Clicked(self)
    }
    @IBAction func path1Clicked(_ sender: NSButton) {
        delegate?.path1Clicked(self)
    }
    @IBAction func path2Clicked(_ sender: NSButton) {
        delegate?.path2Clicked(self)
    }
    @IBAction func path3Clicked(_ sender: NSButton) {
        delegate?.path3Clicked(self)
    }
    @IBAction func path4Clicked(_ sender: NSButton) {
        delegate?.path4Clicked(self)
    }
    @IBAction func path5Clicked(_ sender: NSButton) {
        delegate?.path5Clicked(self)
    }
    @IBAction func loadFileClicked(_ sender: NSButton) {
        delegate?.loadJSON(self)
    }

    @IBAction func saveFileClicked(_ sender: NSButton) {
        delegate?.saveJSON(self)
    }

    @IBAction private func drawPathClicked(_ sender: NSButton) {
		delegate?.topBarDrawPath(self)
	}
	
    @IBAction func finishPathClicked(_ sender: NSButton) {
        delegate?.finishPathClicked(self)
    }
    
    @IBAction func recallAgents(_ sender: NSButton) {
        for entity in GameScene.me!.entities {
            let spriteContainer = entity.agent.spriteContainer
            
            entity.agent.position.x = 0
            entity.agent.position.y = 0
            spriteContainer.position = CGPoint.zero
        }
    }
	
	@IBAction private func placeAgentClicked(_ sender: NSButton) {
		self.showPopover(withTitle: "Agents", andImages: self.agentImages, forButton: sender)
	}
	
	@IBAction private func playClicked(_ sender: NSButton) {
        GameScene.me!.isPaused = !GameScene.me!.isPaused
		self.play = !self.play
		delegate?.topBar(self, statusChangedTo: self.play ? TopBarController.Status.Running : TopBarController.Status.Paused)
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
			delegate?.topBar(self, imageIndex: imageIndex)
		}
		else if controller.listTitle.compare("Obstacles") == .orderedSame {
			delegate?.topBar(self, obstacleSelected: imageIndex)
		}
	}
	
}
