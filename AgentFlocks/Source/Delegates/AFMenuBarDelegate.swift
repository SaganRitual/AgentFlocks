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

class AFMenuBarDelegate {
    let data: AFData
    unowned let inputState: AFInputState
    
    init(data: AFData, inputState: AFInputState) {
        self.data = data
        self.inputState = inputState
    }
}

// MARK: File menu

extension AFMenuBarDelegate {
    func fileOpen(_ url: URL) {
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let data_ = try decoder.decode(AFData_Script.self, from: jsonData)

            for i in 0 ..< data_.paths.keys.count {
                let path_ = data_.paths.keys[i]
                let path = AFPath(prototype: data_.paths.map[path_]!)
                AFCore.data.paths.append(key: path.name, value: path)
            }

            var selectionSet = false
            for entity_ in data_.entities {
                let entity = AFEntity(prototype: entity_)
                AFCore.data.entities.append(key: entity.name, value: entity)

                if !selectionSet {
                    AppDelegate.agentEditorController.goalsController.dataSource = entity
                    AppDelegate.agentEditorController.attributesController.delegate = entity.agent
                    selectionSet = true
                }
            }
        } catch { print(error) }
    }
    
    func fileSave(_ url: URL) {
        do {
            let encoder = JSONEncoder()
            let script = try encoder.encode(AFData_Script(data))

            do {
                try script.write(to: url)
            } catch { print(error) }
        } catch { print(error) }
    }
}

// MARK: Temp menu

extension AFMenuBarDelegate {
    func tempRegisterPath() {
        inputState.finalizePath(close: false)
    }
    
    func tempSelectPath(ix: Int) {
        inputState.pathForNextPathGoal = ix
    }
}
