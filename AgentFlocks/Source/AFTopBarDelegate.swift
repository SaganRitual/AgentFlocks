//
// Created by Rob Bishop on 1/15/18
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

class AFTopBarDelegate {
    unowned let data: AFData
    unowned let inputState: AFInputState
    
    init(data: AFData, inputState: AFInputState) {
        self.data = data
        self.inputState = inputState
    }
    
    func actionPlace() {
        inputState.enter(AFInputState.ModePlace.self)
    }
    
    func actionDraw() {
        inputState.enter(AFInputState.ModeDraw.self)
    }
    
    func getActiveAgentImages() -> [NSImage] {
        var agentImages = [NSImage]()
        
        data.entities.forEach {
            let sprite = $0.agent.sprite
            let cgImage = sprite.texture!.cgImage()
            let nsImage = NSImage(cgImage: cgImage, size: sprite.size)
            agentImages.append(nsImage)
        }
        
        return agentImages
    }
    
    func getActivePathImages() -> [NSImage] {
        var pathImages = [NSImage]()
        
        data.paths.forEach {
            let s = CGSize(width: 50, height: 50)
            pathImages.append($0.getImageData(size: s))
        }
        
        return pathImages
    }
    
    func obstacleRadioButton() {
        // Probably will do away with the radio buttons
    }
    
    func pause() { inputState.gameScene.pause() }
    func play() { inputState.gameScene.play() }
    
    func setSpeed(_ speed: Double) {
        print("setSpeed() not implemented yet")
    }
}
