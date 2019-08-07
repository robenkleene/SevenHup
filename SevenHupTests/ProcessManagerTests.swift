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

class ProcessManagerTests: ProcessManagerTestCase {
    func testRemoveAll() {
        makeNotRunning()
        XCTAssertEqual(processManager.count, 10)
        let processManagerTwo = ProcessManager(processManagerStore: processManagerStore)
        XCTAssertEqual(processManagerTwo.count, 10)
        processManager.removeAll()
        XCTAssertEqual(processManager.count, 0)
        let processManagerThree = ProcessManager(processManagerStore: processManagerStore)
        XCTAssertEqual(processManagerThree.count, 0)
    }

    func testRemoveNotRunning() {
        makeNotRunning()
        XCTAssertEqual(processManager.count, 10)
        let processManagerTwo = ProcessManager(processManagerStore: processManagerStore)
        XCTAssertEqual(processManagerTwo.count, 10)

        let killProcessesExpectation = expectation(description: "Kill processes")
        processManager.killAndRemoveRunningProcessDatas { identifierToProcessData, error in
            guard let identifierToProcessData = identifierToProcessData else {
                XCTFail()
                return
            }
            XCTAssert(identifierToProcessData.isEmpty)
            XCTAssertNil(error)
            killProcessesExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
        XCTAssertEqual(processManager.count, 0)
        let processManagerThree = ProcessManager(processManagerStore: processManagerStore)
        XCTAssertEqual(processManagerThree.count, 0)
    }

    func testProcessManager() {
        let userInfo = ProcessManagerRouter.getUserInfo()
        let userIdentifier = userInfo.userIdentifier
        guard let username = userInfo.username else {
            XCTFail()
            return
        }
        XCTAssertEqual(processManager.count, 0)
        let processData = ProcessData(identifier: 1,
                                      name: "test",
                                      userIdentifier: userIdentifier,
                                      username: username,
                                      startTime: Date())!

        let testProcessManagerHasProcessData: (_ processManager: ProcessManager) -> Bool = { processManager in
            let returnedProcessData = processManager.processData(forIdentifier: processData.identifier)!
            XCTAssertNotNil(returnedProcessData)
            XCTAssertEqual(returnedProcessData, processData)

            let returnedProcessDatas = processManager.getProcessDatas()
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
        processManager.removeProcess(forIdentifier: processData.identifier)
        XCTAssertEqual(processManager.count, 0)

        let testProcessManagerHasNoProcessData: (_ processManager: ProcessManager) -> Bool = { processManager in
            XCTAssertNil(processManager.processData(forIdentifier: processData.identifier))

            let returnedProcessDatas = processManager.getProcessDatas()
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

    func testRunningProcessDatas() {
        let tasks = makeRunningTasks()
        let processDatas = processManager.getProcessDatas()
        XCTAssertTrue(processDatas.count > 0)
        let processDataIdentifiers = processDatas.map { $0.identifier }
        let taskIdentifiers = tasks.map { $0.processIdentifier }
        XCTAssertEqual(Set(processDataIdentifiers), Set(taskIdentifiers))

        for task in tasks {
            XCTAssertTrue(task.isRunning)
        }

        let runningProcessesExpectation = expectation(description: "Running processes")
        processManager.runningProcessDatas { _, error in
            XCTAssertNil(error)
            for task in tasks {
                XCTAssertTrue(task.isRunning)
                let processDatas = self.processManager.getProcessDatas()
                XCTAssertTrue(processDatas.count > 0)
                let processDataIdentifiers = processDatas.map { $0.identifier }
                let taskIdentifiers = tasks.map { $0.processIdentifier }
                XCTAssertEqual(Set(processDataIdentifiers), Set(taskIdentifiers))
            }
            runningProcessesExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        let killProcessesExpectation = expectation(description: "Kill processes")
        var completionCount = 0
        processManager.killAndRemoveRunningProcessDatas { _, error in
            XCTAssertEqual(completionCount, 0)
            completionCount += 1
            XCTAssertNil(error)
            for task in tasks {
                XCTAssertFalse(task.isRunning)
                let processDatas = self.processManager.getProcessDatas()
                XCTAssertTrue(processDatas.count == 0)
            }
            killProcessesExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        let killProcessesExpectationTwo = expectation(description: "Running processes two")
        var completionCountTwo = 0
        processManager.killAndRemoveRunningProcessDatas { identifierToProcessData, error in
            XCTAssertEqual(completionCountTwo, 0)
            completionCountTwo += 1
            guard let identifierToProcessData = identifierToProcessData else {
                XCTFail()
                return
            }
            XCTAssertEqual(identifierToProcessData.count, 0)
            XCTAssertNil(error)
            killProcessesExpectationTwo.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testRunningProcessDatasAndNotRunning() {
        let tasks = makeRunningTasks()
        makeNotRunning()

        let killProcessesExpectation = expectation(description: "Kill processes")
        var completionCount = 0
        processManager.killAndRemoveRunningProcessDatas { _, error in
            XCTAssertEqual(completionCount, 0)
            completionCount += 1
            XCTAssertNil(error)
            for task in tasks {
                XCTAssertFalse(task.isRunning)
                let processDatas = self.processManager.getProcessDatas()
                XCTAssertTrue(processDatas.count == 0)
            }
            killProcessesExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }
}
