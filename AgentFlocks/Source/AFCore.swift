//
// Created by Rob Bishop on 1/16/18
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

class AFCore {
    static var agentGoalsDelegate: AFAgentGoalsDelegate!
    static var browserDelegate: AFBrowserDelegate!
    static var contextMenu: AFContextMenu!
    static var contextMenuDelegate: AFContextMenuDelegate!
    static var data: AFData!
    static var sceneInput: AFSceneInput!
    static var sceneUI: AFSceneUI!
    static var itemEditorDelegate: AFItemEditorDelegate!
    static var menuBarDelegate: AFMenuBarDelegate!
    static var topBarDelegate: AFTopBarDelegate!
    static var ui: AppDelegate!
    
    static func makeCore(ui: AppDelegate, gameScene: GameScene) -> AFGameSceneDelegate {
        contextMenu = AFContextMenu(ui: ui)
        sceneUI = AFSceneUI(gameScene: gameScene, ui: ui, contextMenu: contextMenu)
        
        data = AFData(sceneUI: sceneUI)
        sceneUI.data = self.data
        
        agentGoalsDelegate = AFAgentGoalsDelegate(data: data, sceneUI: sceneUI)
        browserDelegate = AFBrowserDelegate(sceneUI)
        contextMenuDelegate = AFContextMenuDelegate(data: data, sceneUI: sceneUI)
        itemEditorDelegate = AFItemEditorDelegate(data: data, sceneUI: sceneUI)
        menuBarDelegate = AFMenuBarDelegate(data: data, sceneUI: sceneUI)
        sceneInput = AFSceneInput(data: data, sceneUI: sceneUI, gameScene: gameScene)
        topBarDelegate = AFTopBarDelegate(data: data, sceneUI: sceneUI)
        
        // Here, "ui" just means the AppDelegate
        AFCore.ui = ui
        ui.coreAgentGoalsDelegate = agentGoalsDelegate
        ui.coreBrowserDelegate = browserDelegate
        ui.coreContextMenuDelegate = contextMenuDelegate
        ui.coreItemEditorDelegate = itemEditorDelegate
        ui.coreMenuBarDelegate = menuBarDelegate
        ui.coreTopBarDelegate = topBarDelegate
        
        // We don't add this one to AppDelegate, because it's owned by
        // GameScene. We return it so AppDelegate can plug it into
        // GameScene.
        return sceneInput
    }
}
