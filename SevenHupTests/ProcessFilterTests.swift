//
//  ProcessFilterTests.swift
//  SevenHupTests
//
//  Created by Roben Kleene on 4/3/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

@testable import SevenHup
import SodaStream
import XCTest

class ProcessFilterTests: XCTestCase {
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
    
    func testWithProcess() {
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
        
        waitForExpectations(timeout: testTimeout, handler: nil)
        
        let processFilterExpectation = expectation(description: "Filter processes")
        ProcessFilter.runningProcesses(withIdentifiers: [task.processIdentifier]) {
            (identifierToProcessData, error) -> Void in
            XCTAssertNil(error)
            XCTAssertNotNil(identifierToProcessData)
            guard let identifierToProcessData = identifierToProcessData else {
                XCTAssertTrue(false)
                return
            }
            
            XCTAssertEqual(identifierToProcessData.count, 1)
            guard let processData = identifierToProcessData[task.processIdentifier] else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertEqual(processData.identifier, task.processIdentifier)
            processFilterExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
        
        // Clean up
        
        let interruptExpectation = expectation(description: "Interrupt finished")
        task.wcl_interrupt { (success) -> Void in
            XCTAssertTrue(success)
            interruptExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }
}
