//
//  ImagesListController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 14/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

@objc protocol ImagesListDelegate {
	func imagesList(_ controller: ImagesListController, imageSelected index: Int)
	@objc optional func imagesList(_ controller: ImagesListController, imageDoubleClicked index: Int)
	@objc optional func imagesList(_ controller: ImagesListController, imageIndex index: Int, wasEnabled enabled: Bool)
}

class ImagesListController: NSViewController {
	
	enum ListType {
		case common
		case checkbox
	}
	
	// MARK: - Attributes (public)
	
	var delegate:ImagesListDelegate?
	
	var type = ListType.common {
		didSet {
			if let tableView = self.tableView {
				tableView.reloadData()
			}
		}
	}
	
	var imageData = [NSImage]() {
		didSet {
			if let table = tableView {
				table.reloadData()
			}
		}
	}
	
	var listTitle:String = "" {
		didSet {
			if let label = titleLabel {
				label.stringValue = listTitle
			}
			if let constraint = topMarginConstraint {
				constraint.priority = listTitle.isEmpty ? .required : .defaultHigh
			}
		}
	}
	
	// MARK: - Attributes (private)
	
	@IBOutlet private weak var tableView: NSTableView!
	@IBOutlet private weak var titleLabel: NSTextField!
	@IBOutlet private weak var topMarginConstraint: NSLayoutConstraint!
	
	private var withBorder = false
	private var borderType = NSBorderType.noBorder
	private var edgeInsets = NSEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
	
	// MARK: - Initialization
	
	init() {
		super.init(nibName: NSNib.Name(rawValue: "ImagesListView"), bundle: nil)
	}
	
	convenience init(withBorder border: NSBorderType) {
		self.init()
		withBorder = true
		borderType = border
	}

	convenience init(withBorder border: NSBorderType, andInsets insets:NSEdgeInsets) {
		self.init()
		withBorder = true
		borderType = border
		edgeInsets = insets
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		titleLabel.stringValue = listTitle
		tableView.action = #selector(onItemClicked)
		topMarginConstraint.priority = listTitle.isEmpty ? .required : .defaultHigh
		
		if withBorder {
			let boxView = NSBox()
			boxView.borderType = borderType
			boxView.titlePosition = .noTitle
			boxView.fillColor = NSColor.clear
			boxView.contentViewMargins = NSSize(width: 0.0, height: 0.0)
			
			let contentView = self.view
			self.view = boxView
			contentView.removeFromSuperview()
			
			contentView.translatesAutoresizingMaskIntoConstraints = false

			boxView.addSubview(contentView)
			NSLayoutConstraint(item: contentView,
							   attribute: .top,
							   relatedBy: .equal,
							   toItem: boxView,
							   attribute: .top,
							   multiplier: 1.0,
							   constant: edgeInsets.top).isActive = true
			NSLayoutConstraint(item: boxView,
							   attribute: .bottom,
							   relatedBy: .equal,
							   toItem: contentView,
							   attribute: .bottom,
							   multiplier: 1.0,
							   constant: edgeInsets.bottom).isActive = true
			NSLayoutConstraint(item: contentView,
							   attribute: .left,
							   relatedBy: .equal,
							   toItem: boxView,
							   attribute: .left,
							   multiplier: 1.0,
							   constant: edgeInsets.left).isActive = true
			NSLayoutConstraint(item: boxView,
							   attribute: .right,
							   relatedBy: .equal,
							   toItem: contentView,
							   attribute: .right,
							   multiplier: 1.0,
							   constant: edgeInsets.right).isActive = true
		}
    }
	
	
	override func keyUp(with event: NSEvent) {
		super.keyUp(with: event)
		if event.keyCode == AFKeyCodes.enter.rawValue {
			delegate?.imagesList(self, imageSelected: self.tableView.selectedRow)
		}
	}
	
	// MARK: - Actions and methods (private)
	
	@objc private func onItemClicked() {
		delegate?.imagesList(self, imageSelected: self.tableView.clickedRow)
	}

	@objc private func onItemDoubleClicked() {
		delegate?.imagesList?(self, imageDoubleClicked: self.tableView.clickedRow)
	}
	
	@objc private func onItemChecked(_ sender: Any) {
		if let checkButton = sender as? NSButton {
			delegate?.imagesList?(self, imageIndex: checkButton.tag, wasEnabled: checkButton.state == .on)
			// TODO: Uncomment following line to also select the line (select chen checkbox clicked)
			//self.tableView.selectRowIndexes(IndexSet(integer: checkButton.tag), byExtendingSelection: false)
		}
	}
	
}

// MARK: -

extension ImagesListController: NSTableViewDataSource {
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return imageData.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		
		if type == .checkbox {
			if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImageCheckCellView"), owner: nil) as? ImagesListCheckCellView {
				cellView.imageView?.image = imageData[row]
				cellView.checkButton.state = .off
				cellView.checkButton.tag = row
				cellView.checkButton.action = #selector(onItemChecked(_:))
				cellView.checkButton.target = self
				return cellView
			}
		}
		else {
			if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImageCellView"), owner: nil) as? NSTableCellView {
				cellView.imageView?.image = imageData[row]
				return cellView
			}
		}
		
		return nil
	}
	
}

// MARK: -

extension ImagesListController: NSTableViewDelegate {
	
}

// MARK: - Custom components used in Images list

class ImagesListCheckCellView: NSTableCellView {
	
	@IBOutlet weak var checkButton: NSButton!
	
}
