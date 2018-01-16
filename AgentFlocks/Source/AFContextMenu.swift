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
    
    private lazy var displayMenu: NSMenu! = AppDelegate.me!.contextMenu
    private var items = AFOrderedMap<ItemTypes, AFContextMenuItem>()
    private static let me = AFContextMenu()

    init() {
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
    
    static func enableInDisplay(_ item: ItemTypes, _ enable: Bool = true, include: Bool? = nil) {
        me.enableInDisplay(item, enable, include: include)
    }
    
    func enableInDisplay(_ item: ItemTypes, _ enable: Bool = true, include: Bool? = nil) {
        items[item].enabled = enable
        if let include = include { items[item].show = include }
    }
    
    static func includeInDisplay(_ item: ItemTypes, _ include: Bool = true, enable: Bool? = nil) {
        me.includeInDisplay(item, include, enable: enable)
    }

    func includeInDisplay(_ item: ItemTypes, _ include: Bool = true, enable: Bool? = nil) {
        items[item].show = include
        if let enable = enable { items[item].enabled = enable }
    }
    
    static func reset() { me.reset() }
    func reset() { items.forEach { $0.reset() } }
    
    static func show(at point: CGPoint) { me.show(at: point)}
    
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

class AFContextMenuDelegate {
    unowned let data: AFData
    unowned let inputState: AFInputState
    
    init(data: AFData, inputState: AFInputState) {
        self.data = data
        self.inputState = inputState
    }
    
    func itemCloneAgent() {
        let originalEntity = AFCore.data.entities[inputState.upNodeName!]
        let currentPosition = inputState.currentPosition
        
        _ = data.createEntity(scene: inputState.gameScene, copyFrom: originalEntity, position: currentPosition)
    }
    
    func itemAddPathToLibrary() {
        inputState.finalizePath(close: true)
    }
    
    func itemDraw() {
        inputState.enter(AFInputState.ModeDraw.self)
    }
    
    func itemPlace() {
        inputState.enter(AFInputState.ModePlace.self)
    }
    
    func itemSetObstacleCloneStamp() {
        inputState.setObstacleCloneStamp()
    }
    
    func itemStampObstacle() {
        inputState.stampObstacle()
    }
}
