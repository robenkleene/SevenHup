//
//  ProcessFilterTests.swift
//  Web Console
//
//  Created by Roben Kleene on 12/9/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import XCTest

@testable import SevenHup
import SodaStream

// MARK: ProcessFilterTests

class ProcessFilterTests: XCTestCase {
    
    func testWithProcesses() {

        var tasks = [Process]()
        for _ in 0...2 {
            let commandPath = path(forResource: testDataShellScriptCatName,
                ofType: testDataShellScriptExtension,
                inDirectory: testDataSubdirectory)!
            
            let runExpectation = expectation(description: "Task ran")
            let task = SDATaskRunner.runTask(withCommandPath: commandPath,
                                             withArguments: nil,
                                             inDirectoryPath: nil,
                                             delegate: nil)
            { (success) -> Void in
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
                                         delegate: nil)
        { (success) -> Void in
            XCTAssertTrue(success)
            runExpectation.fulfill()
        }
        
        waitForExpectations(timeout: testTimeout, handler: nil)
        
        let processFilterExpectation = expectation(description: "Filter processes")
        ProcessFilter.runningProcesses(withIdentifiers: [task.processIdentifier]) { (identifierToProcessData, error) -> Void in
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


// MARK: ProcessFilterNoProcessTests

class ProcessFilterNoProcessTests: XCTestCase {

    lazy var testProcessData: ProcessData = {
        let identifier = Int32(74)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
        let startTime = dateFormatter.date(from: "Wed Dec 16 02:09:32 2015")!
        let commandPath = "/usr/libexec/wdhelper"
        return ProcessData(identifier: identifier,
                           startTime: startTime,
                           commandPath: commandPath)!
    }()

    func testEmptyIdentifiers() {
        let expectation = self.expectation(description: "Process filter finished")
        ProcessFilter.runningProcesses(withIdentifiers: [Int32]()) { (identifierToProcessData, error) -> Void in
            XCTAssertNotNil(error)
            XCTAssertNil(identifierToProcessData)
            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testEmptyInput() {
        var processDatas = ProcessFilter.makeProcessDatas(output: "")
        XCTAssertEqual(processDatas.count, 0)
        processDatas = ProcessFilter.makeProcessDatas(output: " ")
        XCTAssertEqual(processDatas.count, 0)
    }
    
    func testExampleInput() {
        let fileURL = url(forResource: testDataTextPSOutputSmall,
            withExtension: testDataTextExtension,
            subdirectory: testDataSubdirectory)!
        
        let output = makeString(contentsOf: fileURL)!
        
        let identifierToProcessData = ProcessFilter.makeProcessDatas(output: output)
        XCTAssertEqual(identifierToProcessData.count, 3)
        guard let processData = identifierToProcessData[testProcessData.identifier] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(processData.identifier, testProcessData.identifier)
        XCTAssertEqual(processData.startTime, testProcessData.startTime)
        XCTAssertEqual(processData.commandPath, testProcessData.commandPath)
    }

    func testBadExampleInput() {
        let fileURL = url(forResource: testDataTextPSOutputBad,
            withExtension: testDataTextExtension,
            subdirectory: testDataSubdirectory)!
        
        let output = makeString(contentsOf: fileURL)!
        
        let identifierToProcessData = ProcessFilter.makeProcessDatas(output: output)
        XCTAssertEqual(identifierToProcessData.count, 1)
        guard let processData = identifierToProcessData[testProcessData.identifier] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(processData.identifier, testProcessData.identifier)
        XCTAssertEqual(processData.startTime, testProcessData.startTime)
        XCTAssertEqual(processData.commandPath, testProcessData.commandPath)
    }
    

}
