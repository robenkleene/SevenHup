//
//  ProcessIntegrationTest.swift
//  Web Console
//
//  Created by Roben Kleene on 1/1/16.
//  Copyright © 2016 Roben Kleene. All rights reserved.
//

@testable import SevenHup
import SodaStream
import XCTest

class ProcessIntegrationTests: ProcessManagerTestCase {
    var processManagerRouter: ProcessManagerRouter!

    // MARK: setUp & tearDown

    override func setUp() {
        super.setUp()
        processManagerRouter = ProcessManagerRouter(processManager: processManager)
    }

    override func tearDown() {
        processManagerRouter = nil
        super.tearDown()
    }

    // MARK: Tests

    func testWithProcesses() {
        // Start the processes

        let commandPath = path(forResource: testDataShellScriptCatName,
                               ofType: testDataShellScriptExtension,
                               inDirectory: testDataSubdirectory)!

        let processesToMake = 3
        var tasks = [Process]()
        for _ in 1 ... 3 {
            let runExpectation = expectation(description: "Task ran")
            let task = SDATaskRunner.runTask(withCommandPath: commandPath,
                                             withArguments: nil,
                                             inDirectoryPath: nil,
                                             withEnvironment: nil,
                                             delegate: processManagerRouter) { (success) -> Void in
                XCTAssertTrue(success)
                runExpectation.fulfill()
            }
            tasks.append(task)
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        // Confirm the `ProcessManager` has the processes

        let taskIdentifiers = tasks.map { $0.processIdentifier }
        let processDatas = processManager.processDatas()
        XCTAssertEqual(processDatas.count, processesToMake)

        for task in tasks {
            guard let processDataByIdentifier = processManager.processData(forIdentifier: task.processIdentifier) else {
                XCTAssertTrue(false)
                break
            }
            XCTAssertEqual(processDataByIdentifier.identifier, task.processIdentifier)
        }

        // Confirm the `ProcessFilter` has the processes

        let processFilterExpectation = expectation(description: "Filter processes")
        ProcessFilter.runningProcesses(withIdentifiers: taskIdentifiers) { (identifierToProcessData, error) -> Void in
            guard let identifierToProcessData = identifierToProcessData else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertNil(error)

            XCTAssertEqual(identifierToProcessData.count, processesToMake)

            let processIdentifiers = identifierToProcessData.values.map { $0.identifier }.sorted { $0 < $1 }
            XCTAssertEqual(processIdentifiers, taskIdentifiers)
            processFilterExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        // Terminate the process

        let killProcessExpectation = expectation(description: "Kill process")
        ProcessKiller.kill(processDatas) { _ in
            killProcessExpectation.fulfill()
        }

        // Wait for the process to terminate

        // TODO: Migrate to `killProcessData` when a better implementation
        // of `killProcessData` exists. Right now, the completion handler of
        // `killProcessData` can fire before the process has been terminated!
        wait(forTerminationOf: tasks)

        // Confirm the processes have been removed from the `ProcessManager`

        let processDatasTwo = processManager.processDatas()
        XCTAssertEqual(processDatasTwo.count, 0)

        // Confirm that the `ProcessFilter` no longer has the process

        let filterExpectationFour = expectation(description: "Process filter")
        ProcessFilter.runningProcessMap(matching: processDatas) { (identifierToProcessData, error) -> Void in
            XCTAssertNil(error)
            guard let identifierToProcessData = identifierToProcessData else {
                XCTAssertTrue(false)
                return
            }

            XCTAssertEqual(identifierToProcessData.count, 0)
            filterExpectationFour.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testWithProcess() {
        let commandPath = path(forResource: testDataShellScriptCatName,
                               ofType: testDataShellScriptExtension,
                               inDirectory: testDataSubdirectory)!

        let runExpectation = expectation(description: "Task ran")
        let task = SDATaskRunner.runTask(withCommandPath: commandPath,
                                         withArguments: nil,
                                         inDirectoryPath: nil,
                                         withEnvironment: nil,
                                         delegate: processManagerRouter) { (success) -> Void in
            XCTAssertTrue(success)
            runExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        // Test that the `ProcessManager` has the process

        let processDatas = processManager.processDatas()
        XCTAssertEqual(processDatas.count, 1)
        let processData = processDatas[0]
        let processDataByIdentifier = processManager.processData(forIdentifier: task.processIdentifier)
        XCTAssertEqual(processData, processDataByIdentifier)
        XCTAssertEqual(processData.identifier, task.processIdentifier)

        // Test that the `ProcessFilter` has the process

        let filterExpectation = expectation(description: "Process filter")
        ProcessFilter.runningProcessMap(matching: [processData]) { (identifierToProcessData, error) -> Void in
            XCTAssertNil(error)
            guard let identifierToProcessData = identifierToProcessData,
                let runningProcessData = identifierToProcessData[processData.identifier] else {
                XCTAssertTrue(false)
                return
            }

            XCTAssertEqual(runningProcessData.identifier, processData.identifier)
            filterExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        // Test that the `ProcessFilter` does not have a process in the past

        let filterExpectationTwo = expectation(description: "Process filter")

        let oneSecondInThePast = Date(timeIntervalSinceNow: -1.0)

        guard let inThePastProcessData = ProcessData(identifier: processData.identifier,
                                                     name: processData.name,
                                                     userIdentifier: processData.userIdentifier,
                                                     username: processData.username,
                                                     startTime: oneSecondInThePast) else {
            XCTAssertTrue(false)
            return
        }

        ProcessFilter.runningProcessMap(matching: [inThePastProcessData]) { (identifierToProcessData, error) -> Void in
            XCTAssertNil(error)
            guard let identifierToProcessData = identifierToProcessData else {
                XCTAssertTrue(false)
                return
            }

            XCTAssertEqual(identifierToProcessData.count, 0)
            filterExpectationTwo.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        // Test that the `ProcessFilter` does have a process in the future

        let filterExpectationThree = expectation(description: "Process filter")

        let oneSecondInTheFuture = Date(timeIntervalSinceNow: 1.0)
        guard let inTheFutureProcessData = ProcessData(identifier: processData.identifier,
                                                       name: processData.name,
                                                       userIdentifier: processData.userIdentifier,
                                                       username: processData.username,
                                                       startTime: oneSecondInTheFuture) else {
            XCTAssertTrue(false)
            return
        }

        var runningProcessData: ProcessData!
        ProcessFilter.runningProcessMap(matching: [inTheFutureProcessData]) {
            (identifierToProcessData, error) -> Void in
            XCTAssertNil(error)
            guard
                let identifierToProcessData = identifierToProcessData,
                let localRunningProcessData = identifierToProcessData[processData.identifier] else {
                XCTAssertTrue(false)
                return
            }

            XCTAssertEqual(localRunningProcessData.identifier, processData.identifier)
            runningProcessData = localRunningProcessData
            filterExpectationThree.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        // Terminate the process

        let killProcessExpectation = expectation(description: "Kill process")
        ProcessKiller.kill([runningProcessData]) { success in
            XCTAssertTrue(success)
            killProcessExpectation.fulfill()
        }

        // Wait for the process to terminate

        // TODO: Migrate to `killProcessData` when a better implementation
        // of `killProcessData` exists. Really the completion handler of
        // `killProcessData` not fire until the process has been terminated.
        wait(forTerminationOf: [task])
        // Seems the callback to remove the process data doesn't always fire in time either
        let loopUntil = NSDate(timeIntervalSinceNow: testTimeoutInterval)
        while processManager.processDatas().count != 0, loopUntil.timeIntervalSinceNow > 0 {
            RunLoop.current.run(mode: RunLoop.Mode.default, before: loopUntil as Date)
        }

        // Confirm the process has been removed from the `ProcessManager`
        let processDatasTwo = processManager.processDatas()
        XCTAssertEqual(processDatasTwo.count, 0)
        XCTAssertNil(processManager.processData(forIdentifier: task.processIdentifier))

        // Confirm that the `ProcessFilter` no longer has the process
        let filterExpectationFour = expectation(description: "Process filter")
        ProcessFilter.runningProcessMap(matching: [processData]) { (identifierToProcessData, error) -> Void in
            XCTAssertNil(error)
            guard let identifierToProcessData = identifierToProcessData else {
                XCTAssertTrue(false)
                return
            }

            XCTAssertEqual(identifierToProcessData.count, 0)
            filterExpectationFour.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }
}
