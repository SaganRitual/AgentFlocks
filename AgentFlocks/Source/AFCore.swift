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
    static var data: AFData!
    static var inputState: AFInputState!
    static var itemEditorDelegate: AFItemEditorDelegate!
    static var menuBarDelegate: AFMenuBarDelegate!
    static var topBarDelegate: AFTopBarDelegate!
    
    static func makeCore(gameScene: GameScene) {
        inputState = AFInputState(gameScene: gameScene, ui: AppDelegate.me!)
        
        data = AFData(inputState: inputState)
        inputState.data = self.data
        
        agentGoalsDelegate = AFAgentGoalsDelegate(data: data, inputState: inputState)
        browserDelegate = AFBrowserDelegate(inputState)
        contextMenuDelegate = AFContextMenuDelegate(data: data, inputState: inputState)
        itemEditorDelegate = AFItemEditorDelegate(data: data, inputState: inputState)
        menuBarDelegate = AFMenuBarDelegate(data: data, inputState: inputState)
        topBarDelegate = AFTopBarDelegate(data: data, inputState: inputState)
        
        AppDelegate.me!.coreAgentGoalsDelegate = agentGoalsDelegate
        AppDelegate.me!.coreBrowserDelegate = browserDelegate
        AppDelegate.me!.coreContextMenuDelegate = contextMenuDelegate
        AppDelegate.me!.coreItemEditorDelegate = itemEditorDelegate
        AppDelegate.me!.coreMenuBarDelegate = menuBarDelegate
        AppDelegate.me!.coreTopBarDelegate = topBarDelegate
    }
}
