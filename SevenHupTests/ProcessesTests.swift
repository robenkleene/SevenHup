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
                                             delegate: nil) { (success) -> Void in
                XCTAssertTrue(success)
                runExpectation.fulfill()
            }
            tasks.append(task)
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

        let taskIdentifiers = tasks.map { $0.processIdentifier }.sorted { $0 < $1 }
        let processFilterExpectation = expectation(description: "Filter processes")

        ProcessFilter.runningProcesses(withIdentifiers: taskIdentifiers) { (identifierToProcessData, error) -> Void in
            guard let identifierToProcessData = identifierToProcessData else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertNil(error)

            XCTAssertEqual(identifierToProcessData.count, 3)

            let processIdentifiers = identifierToProcessData.values.map({ $0.identifier }).sorted { $0 < $1 }
            XCTAssertEqual(processIdentifiers, taskIdentifiers)
            processFilterExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)

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
