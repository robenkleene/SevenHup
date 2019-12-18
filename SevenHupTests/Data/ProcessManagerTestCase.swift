//
//  ProcessManagerTestCase.swift
//  SevenHupTests
//
//  Created by Roben Kleene on 8/6/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import Foundation

@testable import SevenHup
import SodaStream
import XCTest

class ProcessManagerTestCase: XCTestCase {
    class MockProcessManagerStore: ProcessManagerStore {
        let mutableDictionary = NSMutableDictionary()

        func set(_ value: Any?, forKey defaultName: String) {
            guard let value = value else {
                return
            }
            mutableDictionary[defaultName] = value
        }

        func dictionary(forKey defaultName: String) -> [String: Any]? {
            return mutableDictionary[defaultName] as? [String: AnyObject]
        }
    }

    // MARK: Properties

    var processManagerStore: ProcessManagerStore!
    var processManager: ProcessManager!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processManagerStore = MockProcessManagerStore()
        processManager = ProcessManager(processManagerStore: processManagerStore)
        XCTAssert(processManager.count == 0)
    }

    override func tearDown() {
        super.tearDown()
        XCTAssert(processManager.count == 0)
        processManager = nil
    }

    // MARK: Helper

    func makeNotRunning() {
        let userInfo = ProcessManagerRouter.getUserInfo()
        let userIdentifier = userInfo.userIdentifier
        guard let username = userInfo.username else {
            XCTFail()
            return
        }
        for i: pid_t in pid_t.max - 10 ..< pid_t.max {
            let processData = ProcessData(identifier: i,
                                          name: "test",
                                          userIdentifier: userIdentifier,
                                          username: username,
                                          startTime: Date())!
            processManager.add(processData)
        }
    }

    func makeRunningTasks() -> [Process] {
        var tasks = [Process]()
        let userInfo = ProcessManagerRouter.getUserInfo()
        let userIdentifier = userInfo.userIdentifier
        guard let username = userInfo.username else {
            XCTFail()
            return [Process]()
        }
        for _ in 0 ... 2 {
            let commandPath = path(forResource: testDataShellScriptCatName,
                                   ofType: testDataShellScriptExtension,
                                   inDirectory: testDataSubdirectory)!

            let runExpectation = expectation(description: "Task ran")
            var task: Process?
            SDATaskRunner.runTask(withCommandPath: commandPath,
                                         withArguments: nil,
                                         inDirectoryPath: nil,
                                         withEnvironment: nil,
                                         delegate: nil) { success, runTask in
                task = runTask
                XCTAssertTrue(success)
                XCTAssertNotNil(task)
                guard let task = task else {
                    XCTAssertTrue(false)
                    return
                }
                tasks.append(task)
                let processData = ProcessData(identifier: task.processIdentifier,
                                              name: commandPath,
                                              userIdentifier: userIdentifier,
                                              username: username,
                                              startTime: Date())!
                self.processManager.add(processData)
                runExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
        return tasks
    }
}
