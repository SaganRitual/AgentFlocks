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

import AppKit

class AFData_Script: Codable {
    var entities: AFOrderedMap_Script<String, AFEntity_Script>
    var paths: AFOrderedMap_Script<String, AFPath_Script>
    var obstacles: [String : AFPath_Script]
    
    init(_ data: AFData) {
        entities = AFOrderedMap_Script<String, AFEntity_Script>()
        paths = AFOrderedMap_Script<String, AFPath_Script>()
        obstacles = [:]
        
        data.entities.forEach {
            let entity = AFEntity_Script(entity: $0)
            entities.append(key: entity.name, value: entity)
        }
        
        data.paths.forEach {
            let path = AFPath_Script(afPath: $0)
            paths.append(key: path.name, value: path)
        }
        
        for (key, value) in data.obstacles {
            obstacles[key] = AFPath_Script(afPath: value)
        }
    }
}

class AFData {
    var entities = AFOrderedMap<String, AFEntity>()
    let sceneUI: AFSceneUI
    var paths = AFOrderedMap<String, AFPath>()
    var obstacles = [String : AFPath]()
    
    init(sceneUI: AFSceneUI) {
        self.sceneUI = sceneUI
    }
    
    init(sceneUI: AFSceneUI, prototype: AFData_Script) {
        self.sceneUI = sceneUI
        
        // Order matters here. Obstacles and paths need to be in place
        // before the entities, because the entities have goals that
        // depend on fully formed obstacles & paths.
        prototype.paths.forEach { createPath(prototype: $0) }
        
        prototype.obstacles.forEach { createObstacle(name: $0, prototype: $1) }
        
        prototype.entities.forEach { createEntity(prototype: $0) }
    }
    
    func createEntity(prototype: AFEntity_Script) {
        let entity = sceneUI.makeEntity(prototype: prototype)
        entities.append(key: entity.name, value: entity)
    }
    
    func createEntity(copyFrom: AFEntity, position: CGPoint) -> AFEntity {
        let entity = sceneUI.makeEntity(copyFrom: copyFrom, position: position)
        entities.append(key: entity.name, value: entity)
        return entity
    }
    
    func createEntity(image: NSImage, position: CGPoint) -> AFEntity {
        let entity = sceneUI.makeEntity(image: image, position: position)
        entities.append(key: entity.name, value: entity)
        return entity
    }
    
    func createObstacle(name: String, prototype: AFPath_Script) {
        obstacles[name] = sceneUI.makePath(prototype: prototype)
    }
    
    func createPath(prototype: AFPath_Script) {
        let path = sceneUI.makePath(prototype: prototype)
        paths.append(key: path.name, value: path)
    }
    
    func getAgent(_ name: String) -> AFAgent2D {
        let entity = entities[name]
        return entity.agent
    }
}
