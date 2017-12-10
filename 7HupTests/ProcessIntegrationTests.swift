//
//  ProcessIntegrationTest.swift
//  Web Console
//
//  Created by Roben Kleene on 1/1/16.
//  Copyright © 2016 Roben Kleene. All rights reserved.
//

import XCTest

@testable import Web_Console

class ProcessManagerRouter: NSObject, WCLTaskRunnerDelegate {

    let processManager: ProcessManager
    
    init(processManager: ProcessManager) {
        self.processManager = processManager
    }
    
    // MARK: WCLTaskRunnerDelegate
    
    func taskDidFinish(_ task: Process) {
        _ = processManager.removeProcess(forIdentifier: task.processIdentifier)
    }
    
    func task(_ task: Process,
        didRunCommandPath commandPath: String,
        arguments: [String]?,
        directoryPath: String?)
    {
        if let
            commandPath = task.launchPath,
            let processInfo = Web_Console.ProcessInfo(identifier: task.processIdentifier,
                startTime: Date(),
                commandPath: commandPath)
        {
            processManager.add(processInfo)
        }
    }
    
}

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
        for _ in 1...3 {
            
            let runExpectation = expectation(description: "Task ran")
            let task = WCLTaskRunner.runTask(withCommandPath: commandPath,
                withArguments: nil,
                inDirectoryPath: nil,
                delegate: processManagerRouter)
                { (success) -> Void in
                    XCTAssertTrue(success)
                    runExpectation.fulfill()
            }
            tasks.append(task)
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        
        // Confirm the `ProcessManager` has the processes
        
        let taskIdentifiers = tasks.map({ $0.processIdentifier })
        let processInfos = processManager.processInfos()
        XCTAssertEqual(processInfos.count, processesToMake)
        
        for task in tasks {
            guard let processInfoByIdentifier = processManager.processInfo(forIdentifier: task.processIdentifier) else {
                XCTAssertTrue(false)
                break
            }
            XCTAssertEqual(processInfoByIdentifier.identifier, task.processIdentifier)
        }
        
        // Confirm the `ProcessFilter` has the processes
        
        let processFilterExpectation = expectation(description: "Filter processes")
        ProcessFilter.runningProcesses(withIdentifiers: taskIdentifiers) { (identifierToProcessInfo, error) -> Void in
            guard let identifierToProcessInfo = identifierToProcessInfo else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertNil(error)
            
            XCTAssertEqual(identifierToProcessInfo.count, processesToMake)
            
            let processIdentifiers = identifierToProcessInfo.values.map({ $0.identifier }).sorted { $0 < $1 }
            XCTAssertEqual(processIdentifiers, taskIdentifiers)
            processFilterExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
        
        // Terminate the process
        
        let killProcessExpectation = expectation(description: "Kill process")
        ProcessKiller.kill(processInfos) { success in
            killProcessExpectation.fulfill()
        }
        
        // Wait for the process to terminate
        
        // TODO: Migrate to `killProcessInfo` when a better implementation
        // of `killProcessInfo` exists. Right now, the completion handler of
        // `killProcessInfo` can fire before the process has been terminated!
        wait(forTerminationOf: tasks)
        
        // Confirm the processes have been removed from the `ProcessManager`
        
        let processInfosTwo = processManager.processInfos()
        XCTAssertEqual(processInfosTwo.count, 0)
        
        // Confirm that the `ProcessFilter` no longer has the process
        
        let filterExpectationFour = expectation(description: "Process filter")
        ProcessFilter.runningProcessMap(matching: processInfos) { (identifierToProcessInfo, error) -> Void in
            XCTAssertNil(error)
            guard let identifierToProcessInfo = identifierToProcessInfo else {
                XCTAssertTrue(false)
                return
            }
            
            XCTAssertEqual(identifierToProcessInfo.count, 0)
            filterExpectationFour.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }
    
    func testWithProcess() {

        let commandPath = path(forResource: testDataShellScriptCatName,
            ofType: testDataShellScriptExtension,
            inDirectory: testDataSubdirectory)!
        
        let runExpectation = expectation(description: "Task ran")
        let task = WCLTaskRunner.runTask(withCommandPath: commandPath,
            withArguments: nil,
            inDirectoryPath: nil,
            delegate: processManagerRouter)
            { (success) -> Void in
                
                XCTAssertTrue(success)
                runExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
        
        // Test that the `ProcessManager` has the process

        let processInfos = processManager.processInfos()
        XCTAssertEqual(processInfos.count, 1)
        let processInfo = processInfos[0]
        let processInfoByIdentifier = processManager.processInfo(forIdentifier: task.processIdentifier)
        XCTAssertEqual(processInfo, processInfoByIdentifier)
        XCTAssertEqual(processInfo.identifier, task.processIdentifier)

        // Test that the `ProcessFilter` has the process

        let filterExpectation = expectation(description: "Process filter")
        ProcessFilter.runningProcessMap(matching: [processInfo]) { (identifierToProcessInfo, error) -> Void in
            XCTAssertNil(error)
            guard let identifierToProcessInfo = identifierToProcessInfo,
                let runningProcessInfo = identifierToProcessInfo[processInfo.identifier] else
            {
                XCTAssertTrue(false)
                return
            }
            
            XCTAssertEqual(runningProcessInfo.identifier, processInfo.identifier)
            filterExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
        
        // Test that the `ProcessFilter` does not have a process in the past

        let filterExpectationTwo = expectation(description: "Process filter")

        let oneSecondInThePast = Date(timeIntervalSinceNow: -1.0)
        guard let inThePastProcessInfo = Web_Console.ProcessInfo(identifier: processInfo.identifier,
            startTime: oneSecondInThePast,
            commandPath: processInfo.commandPath) else
        {
            XCTAssertTrue(false)
            return
        }

        ProcessFilter.runningProcessMap(matching: [inThePastProcessInfo]) { (identifierToProcessInfo, error) -> Void in
            XCTAssertNil(error)
            guard let identifierToProcessInfo = identifierToProcessInfo else {
                XCTAssertTrue(false)
                return
            }
            
            XCTAssertEqual(identifierToProcessInfo.count, 0)
            filterExpectationTwo.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        // Test that the `ProcessFilter` does have a process in the future
        
        let filterExpectationThree = expectation(description: "Process filter")
        
        let oneSecondInTheFuture = Date(timeIntervalSinceNow: 1.0)
        guard let inTheFutureProcessInfo = Web_Console.ProcessInfo(identifier: processInfo.identifier,
            startTime: oneSecondInTheFuture,
            commandPath: processInfo.commandPath) else
        {
            XCTAssertTrue(false)
            return
        }
        
        var runningProcessInfo: Web_Console.ProcessInfo!
        ProcessFilter.runningProcessMap(matching: [inTheFutureProcessInfo]) { (identifierToProcessInfo, error) -> Void in
            XCTAssertNil(error)
            guard let identifierToProcessInfo = identifierToProcessInfo,
                let localRunningProcessInfo = identifierToProcessInfo[processInfo.identifier] else
            {
                XCTAssertTrue(false)
                return
            }
            
            XCTAssertEqual(localRunningProcessInfo.identifier, processInfo.identifier)
            runningProcessInfo = localRunningProcessInfo
            filterExpectationThree.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        // Terminate the process 
        
        let killProcessExpectation = expectation(description: "Kill process")
        ProcessKiller.kill([runningProcessInfo]) { success in
            XCTAssertTrue(success)
            killProcessExpectation.fulfill()
        }
        
        // Wait for the process to terminate

        // TODO: Migrate to `killProcessInfo` when a better implementation
        // of `killProcessInfo` exists. Really the completion handler of 
        // `killProcessInfo` not fire until the process has been terminated.
        wait(forTerminationOf: [task])
        
        // Confirm the process has been removed from the `ProcessManager`

        let processInfosTwo = processManager.processInfos()
        XCTAssertEqual(processInfosTwo.count, 0)
        XCTAssertNil(processManager.processInfo(forIdentifier: task.processIdentifier))

        // Confirm that the `ProcessFilter` no longer has the process
        
        let filterExpectationFour = expectation(description: "Process filter")
        ProcessFilter.runningProcessMap(matching: [processInfo]) { (identifierToProcessInfo, error) -> Void in
            XCTAssertNil(error)
            guard let identifierToProcessInfo = identifierToProcessInfo else {
                XCTAssertTrue(false)
                return
            }
            
            XCTAssertEqual(identifierToProcessInfo.count, 0)
            filterExpectationFour.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

}
