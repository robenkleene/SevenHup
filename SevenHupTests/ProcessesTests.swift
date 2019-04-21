//
//  ProcessesTests.swift
//  SevenHupTests
//
//  Created by Roben Kleene on 4/1/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import XCTest

@testable import SevenHup
import SodaStream

class ProcessesTests: XCTestCase {
    func testWithProcesses() {
        var tasks = [Process]()
        for _ in 0 ... 2 {
            let commandPath = path(forResource: testDataShellScriptCatName,
                                   ofType: testDataShellScriptExtension,
                                   inDirectory: testDataSubdirectory)!

            let runExpectation = expectation(description: "Task ran")
            let task = SDATaskRunner.runTask(withCommandPath: commandPath,
                                             withArguments: nil,
                                             inDirectoryPath: nil,
                                             withEnvironment: nil,
                                             delegate: nil) { (success) -> Void in
                XCTAssertTrue(success)
                runExpectation.fulfill()
            }
            tasks.append(task)
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        let taskIdentifiers = tasks.map { $0.processIdentifier }.sorted { $0 < $1 }
        let processFilterExpectation = expectation(description: "Filter processes")

        var finished = false
        var runningIdentifierToProcessData: [pid_t: ProcessData]!
        var alternativeIdentifierToProcessData: [pid_t: ProcessData]!
        ProcessFilter.runningProcesses(withIdentifiers: taskIdentifiers) { (identifierToProcessData, error) -> Void in
            guard let identifierToProcessData = identifierToProcessData else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertNil(error)
            XCTAssertEqual(identifierToProcessData.count, 3)

            runningIdentifierToProcessData = identifierToProcessData
            finished = true
            processFilterExpectation.fulfill()
        }

        let alternativeProcessFilterExpectation = expectation(description: "Filter processes")
        ProcessFilter.alternativeRunningProcesses(withIdentifiers:
            taskIdentifiers) { (identifierToProcessData, error) -> Void in
            guard let identifierToProcessData = identifierToProcessData else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertNil(error)
            XCTAssertEqual(identifierToProcessData.count, 3)

            alternativeIdentifierToProcessData = identifierToProcessData
            // Confirm that the other method of getting running processes is faster
            XCTAssertTrue(finished)
            alternativeProcessFilterExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        let runningProcessIdentifiers = runningIdentifierToProcessData.values.map({ $0.identifier }).sorted { $0 < $1 }
        let alternativeProcessIdentifiers = alternativeIdentifierToProcessData.values.map({
            $0.identifier
        }).sorted { $0 < $1 }
        XCTAssertEqual(alternativeProcessIdentifiers, taskIdentifiers)
        XCTAssertEqual(runningProcessIdentifiers, taskIdentifiers)

        for identifier in runningProcessIdentifiers {
            let processData = runningIdentifierToProcessData[identifier]
            let alternativeProcessData = runningIdentifierToProcessData[identifier]
            XCTAssertEqual(processData, alternativeProcessData)
        }

        // Clean up

        for task in tasks {
            let interruptExpectation = expectation(description: "Interrupt finished")
            task.wcl_interrupt { (success) -> Void in
                XCTAssertTrue(success)
                interruptExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: testTimeout, handler: nil)
    }
}
