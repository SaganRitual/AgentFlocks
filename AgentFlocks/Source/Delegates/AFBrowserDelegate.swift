//
// Created by Rob Bishop on 1/14/18
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

// The order matters here! Each one is connected to a specific list view.
// I haven't yet figured out why Gergely is passing me a 1-based index.
enum AFBrowserType: Int { case SpriteImages = 1, Agents, Paths, LinkedGoals }

class AFBrowserDelegate {
    let sceneUI: AFSceneController
    var agentImageIndex = 0
    
    init(_ sceneUI: AFSceneController) { self.sceneUI = sceneUI }
    
    func imageSelected(controllerIndex: Int, imageIndex: Int) {
        switch AFBrowserType(rawValue: controllerIndex)! {
        case .SpriteImages:
            self.agentImageIndex = imageIndex
            
        case .Agents: break
//            self.agentImageIndex = imageIndex
//            sceneUI.select(imageIndex, primary: true)

        case .Paths:
            break
            
        case .LinkedGoals:
            break
        }
    }
    
    func imageEnabled(controllerIndex: Int, imageIndex: Int, enabled: Bool) {
        
    }

}
