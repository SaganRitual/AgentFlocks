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
    
    init(_ data: AFData) { self.data = data }

    func fileOpen(_ url: URL) {
        //        // Get out of draw mode. Seems weird to be doing this in a function about
        //        // loading a script, but this is the only reasonable place to put it, I think?
        //
        //        GameScene.me!.selectionDelegate = GameScene.me!.selectionDelegatePrimary
        //
        //        do {
        //            let jsonData = try Data(contentsOf: url)
        //            let decoder = JSONDecoder()
        //            let entities_ = try decoder.decode(AFEntities.self, from: jsonData)
        //
        //            let paths_ = try decoder.decode(AFPaths.self, from: jsonData)
        //
        //            for path_ in paths_.paths {
        //                let path = AFPath(prototype: path_)
        //                AFCore.data.paths[path.name] = path
        //                GameScene.me!.pathnames.append(path.name)
        //            }
        //
        //            var selectionSet = false
        //            for entity_ in entities_.entities {
        //                let entity = AFEntity(prototype: entity_)
        //                AFCore.data.entities.append(entity)
        //
        //                if !selectionSet {
        //                    AppDelegate.agentEditorController.goalsController.dataSource = entity
        //                    AppDelegate.agentEditorController.attributesController.delegate = entity.agent
        //                    selectionSet = true
        //                }
        //
        //                let nodeIndex = AFCore.data.entities.count - 1
        //                GameScene.me!.newAgent(nodeIndex)
        //            }
        //        } catch { print(error) }
    }
    
    func fileSave(_ url: URL) {
        //        do {
        //            var entities_ = [AFEntity_Script]()
        //
        //            for entity in AFCore.data.entities {
        //                let entity_ = AFEntity_Script(entity: entity)
        //                entities_.append(entity_)
        //            }
        //
        //            var paths_ = [AFPath_Script]()
        //
        //            for (_, afPath) in AFCore.data.paths {
        //                let afPath_Script = AFPath_Script(afPath: afPath)
        //                paths_.append(afPath_Script)
        //            }
        //
        //            let bigger = jsonOut(entities: entities_, paths: paths_)
        //            let encoder = JSONEncoder()
        //            let script = try encoder.encode(bigger)
        //
        //            do {
        //                try script.write(to: url)
        //            } catch { print(error) }
        //        } catch { print(error) }
    }
}
