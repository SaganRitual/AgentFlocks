//
// Created by Rob Bishop on 2/11/18
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

class AFEditor {
    unowned var core: AFCore
    var pathToHere: [JSONSubscriptType]
    
    init(_ pathToHere: [JSONSubscriptType], core: AFCore) {
        self.core  = core
        self.pathToHere = pathToHere
    }
    
    init(_ nodeName: String, core: AFCore) {
        self.core = core
        self.pathToHere = core.getPathTo(nodeName)!
    }

    func getNodeWriter(_ pathToParent: [JSONSubscriptType]) -> NodeWriter {
        return core.bigData.getNodeWriter(pathToParent)
    }
}

extension AFEditor {
    
    var name: String { get { return JSON(pathToHere.last!).stringValue } }
    
}
