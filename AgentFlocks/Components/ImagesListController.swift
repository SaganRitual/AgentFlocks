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
	@objc optional func imagesList(_ controller: ImagesListController, imageIndex index: Int, wasEnabled: Bool)
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
	
	var listTitle:String = "Title" {
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
	@IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
	
	// MARK: - Initialization
	
	init() {
		super.init(nibName: NSNib.Name(rawValue: "ImagesListView"), bundle: nil)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init()
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		titleLabel.stringValue = listTitle
		tableView.action = #selector(onItemClicked)
		topMarginConstraint.priority = listTitle.isEmpty ? .required : .defaultHigh
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
