//
// Created by Rob Bishop on 2/6/18
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

import Foundation

class NodeWriter {
    let bigData: AFData
    var key: JSONSubscriptType?
    let pathToParent: [JSONSubscriptType]
    
    init(_ pathToParent: [JSONSubscriptType], core: AFCore) {
        self.bigData = core.bigData
        self.pathToParent = pathToParent
    }
    
    deinit {
        if let key = key {    // That is, if we actually wrote something
            bigData.announce(path: pathToParent + [key])
        }
    }
    
    func write(this value: JSON, to key: JSONSubscriptType) {
        self.key = key
        bigData.data[pathToParent][key] = value
    }
    
    // Non-functional ugliness. I'm ashamed to have written it. But
    // it makes the JSON more readable.
    func write(this value: JSON, to key: JSONSubscriptType, under: JSONSubscriptType) {
        bigData.data[pathToParent][key][under] = value
    }
}

class AFData {
    var core: AFCore!
    var data: JSON = [ "agents": [:], "paths": [:] ]

    var notifications = NotificationCenter()
    
    init() {  }
    
    func announce(path toNode: [JSONSubscriptType]) {
        let u: [String : Any] = ["core": core, "path": toNode]
        let n = Notification.Name(rawValue: "ThereCanBeOnlyOne")
        let nn = Notification(name: n, object: nil, userInfo: u)
        notifications.post(nn)
    }

    func dump() -> String {
        if let rs = data.rawString(.utf8, options: .sortedKeys) { return rs }
        else { return "no string?" }
    }

    func getNodeWriter(for path: [JSONSubscriptType]) -> NodeWriter {
        return NodeWriter(path, core: core)
    }
}
