//
//  ProcessManagerTests.swift
//  Web Console
//
//  Created by Roben Kleene on 12/7/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import XCTest

@testable import SevenHup

class ProcessManagerTestCase: XCTestCase {
    class MockProcessManagerStore: ProcessManagerStore {
        let mutableDictionary = NSMutableDictionary()

        func set(_ value: Any?, forKey defaultName: String) {
            guard let value = value else {
                return
            }
            mutableDictionary[defaultName] = value
        }

        func dictionary(forKey defaultName: String) -> [String : Any]? {
            return mutableDictionary[defaultName] as? [String : AnyObject]
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

    func testProcessManager() {
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

}
