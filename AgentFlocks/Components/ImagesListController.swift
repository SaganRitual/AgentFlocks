//
//  ImagesListController.swift
//  AgentFlocks
//
//  Created by Gergely Sánta on 14/10/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

protocol ImagesListDelegate {
	func imagesList(_ controller: ImagesListController, selectedIndex index: Int)
}

class ImagesListController: NSViewController {
	
	// MARK: - Attributes (public)
	
	var delegate:ImagesListDelegate?
	
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
		}
	}
	
	// MARK: - Attributes (private)
	
	@IBOutlet private weak var tableView: NSTableView!
	@IBOutlet private weak var titleLabel: NSTextField!
	
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
    }
	
	@objc private func onItemClicked() {
		delegate?.imagesList(self, selectedIndex: self.tableView.clickedRow)
	}
	
	override func keyUp(with event: NSEvent) {
		super.keyUp(with: event)
		if event.keyCode == 36 {
			delegate?.imagesList(self, selectedIndex: self.tableView.selectedRow)
		}
	}
	
}

// MARK: -

extension ImagesListController: NSTableViewDataSource {
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return imageData.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		
		if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImageCellView"), owner: nil) as? NSTableCellView {
			cellView.imageView?.image = imageData[row]
			return cellView
		}
		
		return nil
	}
	
}

// MARK: -

extension ImagesListController: NSTableViewDelegate {
	
}
