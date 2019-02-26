//
//  ProcessManagerTests.swift
//  Web Console
//
//  Created by Roben Kleene on 12/7/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

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
    }

    override func tearDown() {
        super.tearDown()
        processManager = nil
    }
}

class ProcessManagerTests: ProcessManagerTestCase {
    func testRemoveAll() {
        for i: Int32 in 1...10 {
            let processData = ProcessData(identifier: i,
                                          startTime: Date(),
                                          commandPath: "test")!
            processManager.add(processData)
        }
        XCTAssertEqual(processManager.count, 10)
        let processManagerTwo = ProcessManager(processManagerStore: processManagerStore)
        XCTAssertEqual(processManagerTwo.count, 10)
        processManager.removeAll()
        XCTAssertEqual(processManager.count, 0)
        let processManagerThree = ProcessManager(processManagerStore: processManagerStore)
        XCTAssertEqual(processManagerThree.count, 0)
    }

    func testProcessManager() {
        XCTAssertEqual(processManager.count, 0)
        let processData = ProcessData(identifier: 1,
                                      startTime: Date(),
                                      commandPath: "test")!

        let testProcessManagerHasProcessData: (_ processManager: ProcessManager) -> Bool = { processManager in
            let returnedProcessData = processManager.processData(forIdentifier: processData.identifier)!
            XCTAssertNotNil(returnedProcessData)
            XCTAssertEqual(returnedProcessData, processData)

            let returnedProcessDatas = processManager.processDatas()
            XCTAssertEqual(returnedProcessDatas.count, 1)
            XCTAssertEqual(returnedProcessDatas[0], processData)

            XCTAssertNil(processManager.processData(forIdentifier: 999))
            return true
        }

        processManager.add(processData)
        XCTAssertEqual(processManager.count, 1)
        let processManagerHasProcessDataResult = testProcessManagerHasProcessData(processManager)
        XCTAssertTrue(processManagerHasProcessDataResult)

        // Initialize a second `ProcessManager` with the existing `ProcessManagerStore`
        // this will test that the new `ProcessManager` is initialized with the
        // `ProcessData`s already stored in the `ProcessManagerStore`.
        let processManagerTwo = ProcessManager(processManagerStore: processManagerStore)
        let processManagerHasProcessDataResultTwo = testProcessManagerHasProcessData(processManagerTwo)
        XCTAssertTrue(processManagerHasProcessDataResultTwo)

        // Remove the processes and make sure nil is returned
        _ = processManager.removeProcess(forIdentifier: processData.identifier)
        XCTAssertEqual(processManager.count, 0)

        let testProcessManagerHasNoProcessData: (_ processManager: ProcessManager) -> Bool = { processManager in
            XCTAssertNil(processManager.processData(forIdentifier: processData.identifier))

            let returnedProcessDatas = processManager.processDatas()
            XCTAssertEqual(returnedProcessDatas.count, 0)

            XCTAssertNil(processManager.processData(forIdentifier: 999))
            return true
        }

        let processManagerHasNoProcessDataResult = testProcessManagerHasNoProcessData(processManager)
        XCTAssertTrue(processManagerHasNoProcessDataResult)
        let processManagerThree = ProcessManager(processManagerStore: processManagerStore)
        let processManagerHasNoProcessDataResultTwo = testProcessManagerHasNoProcessData(processManagerThree)
        XCTAssertTrue(processManagerHasNoProcessDataResultTwo)
    }

    func testRunningProcessDats() {
        let tasks = makeRunningTasks()
        let processDatas = processManager.processDatas()
        XCTAssertTrue(processDatas.count > 0)
        let processDataIdentifiers = processDatas.map({ $0.identifier })
        let taskIdentifiers = tasks.map({ $0.processIdentifier })
        XCTAssertEqual(Set(processDataIdentifiers), Set(taskIdentifiers))

        for task in tasks {
            XCTAssertTrue(task.isRunning)
        }

        let runningProcessesExpectation = expectation(description: "Running processes")
        processManager.runningProcessDatas { _, error in
            XCTAssertNil(error)
            for task in tasks {
                XCTAssertTrue(task.isRunning)
                let processDatas = self.processManager.processDatas()
                XCTAssertTrue(processDatas.count > 0)
                let processDataIdentifiers = processDatas.map({ $0.identifier })
                let taskIdentifiers = tasks.map({ $0.processIdentifier })
                XCTAssertEqual(Set(processDataIdentifiers), Set(taskIdentifiers))
            }
            runningProcessesExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        let killProcessesExpectation = expectation(description: "Kill processes")
        processManager.killAndRemoveRunningProcessDatas { _, error in
            XCTAssertNil(error)
            for task in tasks {
                XCTAssertFalse(task.isRunning)
                let processDatas = self.processManager.processDatas()
                XCTAssertTrue(processDatas.count == 0)
            }
            killProcessesExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        // This should be an error
        let killProcessesExpectationTwo = expectation(description: "Running processes two")
        processManager.killAndRemoveRunningProcessDatas { _, error in
            XCTAssertNotNil(error)
            guard let error = error else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertEqual(error.code, noIdentifiersErrorCode)
            killProcessesExpectationTwo.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    // MARK: Helper

    func makeRunningTasks() -> [Process] {
        var tasks = [Process]()
        for _ in 0 ... 2 {
            let commandPath = path(forResource: testDataShellScriptCatName,
                                   ofType: testDataShellScriptExtension,
                                   inDirectory: testDataSubdirectory)!

            let runExpectation = expectation(description: "Task ran")
            var task: Process?
            task = SDATaskRunner.runTask(withCommandPath: commandPath,
                                         withArguments: nil,
                                         inDirectoryPath: nil,
                                         delegate: nil) { (success) -> Void in
                XCTAssertTrue(success)
                XCTAssertNotNil(task)
                guard let task = task else {
                    XCTAssertTrue(false)
                    return
                }
                tasks.append(task)
                let processData = ProcessData(identifier: task.processIdentifier,
                                              startTime: Date(),
                                              commandPath: commandPath)!
                self.processManager.add(processData)
                runExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
        return tasks
    }
}
