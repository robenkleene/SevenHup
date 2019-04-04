//
//  ProcessStatusFilterTests.swift
//  Web Console
//
//  Created by Roben Kleene on 12/9/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

@testable import SevenHup
import SodaStream
import XCTest

class ProcessStatusFilterNoProcessTests: XCTestCase {
    lazy var testProcessData: ProcessData = {

        let identifier = Int32(74)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
        let startTime = dateFormatter.date(from: "Wed Dec 16 02:09:32 2015")!
        let commandPath = "/usr/libexec/wdhelper"

        let userInfo = ProcessManagerRouter.getUserInfo()
        let userIdentifier = userInfo.userIdentifier
        guard let username = userInfo.username else {
            XCTFail()
            return ProcessData(identifier: identifier,
                               name: commandPath,
                               userIdentifier: userIdentifier,
                               username: "bad",
                               startTime: startTime)!
        }
        return ProcessData(identifier: identifier,
                           name: commandPath,
                           userIdentifier: userIdentifier,
                           username: username,
                           startTime: startTime)!
    }()

    func testEmptyIdentifiers() {
        let expectation = self.expectation(description: "Process filter finished")
        ProcessStatusFilter.runningProcesses(withIdentifiers: [Int32]()) { (identifierToProcessData, error) -> Void in
            XCTAssertNotNil(error)
            XCTAssertNil(identifierToProcessData)
            expectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testEmptyInput() {
        var processDatas = ProcessStatusFilter.makeProcessDatas(output: "")
        XCTAssertEqual(processDatas.count, 0)
        processDatas = ProcessStatusFilter.makeProcessDatas(output: " ")
        XCTAssertEqual(processDatas.count, 0)
    }

    func testExampleInput() {
        let fileURL = url(forResource: testDataTextPSOutputSmall,
                          withExtension: testDataTextExtension,
                          subdirectory: testDataSubdirectory)!

        let output = makeString(contentsOf: fileURL)!

        let identifierToProcessData = ProcessStatusFilter.makeProcessDatas(output: output)
        XCTAssertEqual(identifierToProcessData.count, 3)
        guard let processData = identifierToProcessData[testProcessData.identifier] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(processData.identifier, testProcessData.identifier)
        XCTAssertEqual(processData.startTime, testProcessData.startTime)
        XCTAssertEqual(processData.name, testProcessData.name)
        XCTAssertEqual(processData.username, testProcessData.username)
        XCTAssertEqual(processData.userIdentifier, testProcessData.userIdentifier)
    }

    func testBadExampleInput() {
        let fileURL = url(forResource: testDataTextPSOutputBad,
                          withExtension: testDataTextExtension,
                          subdirectory: testDataSubdirectory)!

        let output = makeString(contentsOf: fileURL)!

        let identifierToProcessData = ProcessStatusFilter.makeProcessDatas(output: output)
        XCTAssertEqual(identifierToProcessData.count, 1)
        guard let processData = identifierToProcessData[testProcessData.identifier] else {
            XCTAssertTrue(false)
            return
        }

        XCTAssertEqual(processData.identifier, testProcessData.identifier)
        XCTAssertEqual(processData.startTime, testProcessData.startTime)
        XCTAssertEqual(processData.name, testProcessData.name)
        XCTAssertEqual(processData.username, testProcessData.username)
        XCTAssertEqual(processData.userIdentifier, testProcessData.userIdentifier)
    }
}
