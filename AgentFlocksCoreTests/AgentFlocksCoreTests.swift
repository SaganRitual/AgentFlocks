//
// Created by Rob Bishop on 2/10/18
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
import XCTest

class AgentFlocksCoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSmoke() {
        let core = AFCore()
        let agent = core.createAgent()
        print(agent.name)
        
        do {
            let jpat = String("[0-9A-Z]{8}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{12}")
            let pat = try NSRegularExpression(pattern: jpat, options: [])
            let desc = agent.name
            let range = NSMakeRange(0, desc.count)
            let m = pat.matches(in: desc, options: [], range: range)
            XCTAssertEqual(m.count, 1)
        } catch { print(error); XCTAssert(false) }
    }
/*
    @objc func nodeChanged(notification: Notification) {
        if let info = notification.userInfo, let path = info["path"] as? [JSONSubscriptType], let _ = info["core"] as? AFCore {
            print("Node changed, path:", path)
        } else {
            XCTAssert(false, "Notification, but nothing recognized in it.")
        }
    }
    
    func testNotifications() {
        let core = AFCore()
        
        unowned let notifier = core.bigData.notifier
        
        let firstID = NSNotification.Name(rawValue: "ThereCanBeOnlyOne")
        notifier.addObserver(self, selector: #selector(nodeChanged(notification:)), name: firstID, object: nil)
        
        let aAgent = core.createAgent()
        aAgent.isPaused = true
        aAgent.mass = 42.42
        aAgent.radius = Float.pi
        
        let bAgent = core.createAgent()
        bAgent.scale = 17
        bAgent.maxAcceleration = 22.22
        bAgent.maxSpeed = 44.76
        
        var composite = aAgent.createComposite()
        var behavior = composite.createBehavior()
        _ /* goal */ = behavior.createGoal()
        
        composite = bAgent.createComposite()
        behavior = composite.createBehavior()
        _ /* goal */ = behavior.createGoal()
        
        print("end of test", core.bigData.data)
        XCTAssert(true, "Output looks good")
    }
    
    func testBasicHierarchy() {
        let core = AFCore()
        
        let agent = core.createAgent()
        let composite = agent.createComposite()
        let behavior = composite.createBehavior()
        _ /* goal */ = behavior.createGoal()
        
        print("end of test", core.bigData.data)
        XCTAssert(true, "Output looks good")
    }
    
    
    func testRealisticHierarchy() {
        let core = AFCore()
        
        _ = core.createAgent()
        
        print("end of test", core.bigData.data)
        XCTAssert(true, "Output looks good")
    }
    
    func testEditorRW() {
        let core = AFCore()
        let agent = core.createAgent()
        print("after createAgent()", core.bigData.data)
        agent.isPaused = true
        agent.mass = 42.42
        agent.radius = Float.pi
        print("after fiddling", core.bigData.data)
        print(agent.isPaused)
        print(agent.mass)
        print(agent.radius)
        agent.mass = 4.43
        print(agent.mass)
        XCTAssert(true, "Output looks good")
    }
    
    func testGoals() {
        let core = AFCore()
        
        _ = core.createAgent()
        
        print("end of test", core.bigData.data)
        XCTAssert(false, "Output looks good")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
*/
}
