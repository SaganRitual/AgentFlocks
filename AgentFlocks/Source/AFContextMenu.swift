//
// Created by Rob Bishop on 1/13/18
//
// Copyright © 2018 Rob Bishop
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//

import GameplayKit

class AFContextMenuItem: Equatable {
    var enabled = false
    var show = false
    let title: String
    let type: AFContextMenu.ItemTypes
    
    init(type: AFContextMenu.ItemTypes, title: String) {
        self.type = type
        self.title = title
    }
    
    func reset() { enabled = false; show = false }

    static func ==(lhs: AFContextMenuItem, rhs: AFContextMenuItem) -> Bool {
        return lhs.title == rhs.title
    }
}

class AFContextMenu {
    enum ItemTypes: Int {
        case AddPathToLibrary, CloneAgent, Draw, Place, SetObstacleCloneStamp, StampObstacle
    }
    
    private var displayMenu: NSMenu!
    private var items = AFOrderedMap<ItemTypes, AFContextMenuItem>()

    init(ui: AppDelegate) {
        displayMenu = ui.contextMenu
        
        let setup: [ItemTypes : String] = [
            ItemTypes.AddPathToLibrary : "Add path to library",
            ItemTypes.CloneAgent : "Clone",
            ItemTypes.Draw : "Draw",
            ItemTypes.Place : "Place",
            ItemTypes.SetObstacleCloneStamp : "Set obstacle clone stamp",
            ItemTypes.StampObstacle : "Stamp obstacle"
        ]
        
        for (type, title) in setup {
            items.append(key: type, value: AFContextMenuItem(type: type, title: title))
        }
    }
    
    func enableInDisplay(_ item: ItemTypes, _ enable: Bool = true, include: Bool? = nil) {
        items[item].enabled = enable
        if let include = include { items[item].show = include }
    }

    func includeInDisplay(_ item: ItemTypes, _ include: Bool = true, enable: Bool? = nil) {
        items[item].show = include
        if let enable = enable { items[item].enabled = enable }
    }
    
    func reset() { items.forEach { $0.reset() } }
    
    func show(at point: CGPoint) {
        displayMenu.removeAllItems()
        displayMenu.autoenablesItems = false
        
        var anythingToShow = false
        let action = #selector(AppDelegate.contextMenuClicked(_:))

        items.forEach {
            if $0.show {
                anythingToShow = true
                let displayItem = displayMenu.addItem(withTitle: $0.title, action: action, keyEquivalent: "")
                displayItem.isEnabled = $0.enabled
                displayItem.tag = $0.type.rawValue
            }
        }
        
        if anythingToShow {
            (NSApp.delegate as? AppDelegate)?.showContextMenu(at: point)
        }
    }
}

