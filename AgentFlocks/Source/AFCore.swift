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
    static var contextMenuDelegate: AFContextMenuDelegate!
    static var appData: AFDataModel!
    static var sceneInput: AFSceneInput!
    static var sceneUI: AFSceneController!
    static var itemEditorDelegate: AFItemEditorDelegate!
    static var menuBarDelegate: AFMenuBarDelegate!
    static var topBarDelegate: AFTopBarDelegate!
    static var ui: AppDelegate!
    
    static func makeCore(ui: AppDelegate, gameScene: GameScene) -> AFGameSceneDelegate {
        sceneUI = AFSceneController(appData: appData, gameScene: gameScene, ui: ui, contextMenu: AFContextMenu(ui: ui))
        
        appData = AFDataModel()
        sceneUI.appData = self.appData
        
        agentGoalsDelegate = AFAgentGoalsDelegate(appData: appData, sceneUI: sceneUI)
        browserDelegate = AFBrowserDelegate(sceneUI)
        contextMenuDelegate = AFContextMenuDelegate(appData: appData, sceneUI: sceneUI)
        itemEditorDelegate = AFItemEditorDelegate(appData: appData, sceneUI: sceneUI)
        menuBarDelegate = AFMenuBarDelegate(appData: appData, sceneUI: sceneUI)

        sceneInput = AFSceneInput(appData: appData, gameScene: gameScene)
        sceneInput.delegate = sceneUI

        topBarDelegate = AFTopBarDelegate(appData: appData, sceneUI: sceneUI)
        
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
