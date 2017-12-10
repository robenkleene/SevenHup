//
//  ProcessManagerTests.swift
//  Web Console
//
//  Created by Roben Kleene on 12/7/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import XCTest

@testable import Web_Console

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
        let processInfo = Web_Console.ProcessInfo(identifier: 1,
            startTime: Date(),
            commandPath: "test")!

        let testProcessManagerHasProcessInfo: (_ processManager: ProcessManager) -> Bool = { processManager in
            let returnedProcessInfo = processManager.processInfo(forIdentifier: processInfo.identifier)!
            XCTAssertNotNil(returnedProcessInfo)
            XCTAssertEqual(returnedProcessInfo, processInfo)
            
            let returnedProcessInfos = processManager.processInfos()
            XCTAssertEqual(returnedProcessInfos.count, 1)
            XCTAssertEqual(returnedProcessInfos[0], processInfo)

            XCTAssertNil(processManager.processInfo(forIdentifier: 999))
            return true
        }
        
        processManager.add(processInfo)
        let processManagerHasProcessInfoResult = testProcessManagerHasProcessInfo(processManager)
        XCTAssertTrue(processManagerHasProcessInfoResult)
        
        // Initialize a second `ProcessManager` with the existing `ProcessManagerStore`
        // this will test that the new `ProcessManager` is initialized with the
        // `ProcessInfo`s already stored in the `ProcessManagerStore`.
        let processManagerTwo = ProcessManager(processManagerStore: processManagerStore)
        let processManagerHasProcessInfoResultTwo = testProcessManagerHasProcessInfo(processManagerTwo)
        XCTAssertTrue(processManagerHasProcessInfoResultTwo)
        
        // Remove the processes and make sure nil is returned
        _ = processManager.removeProcess(forIdentifier: processInfo.identifier)

        let testProcessManagerHasNoProcessInfo: (_ processManager: ProcessManager) -> Bool = { processManager in
            XCTAssertNil(processManager.processInfo(forIdentifier: processInfo.identifier))
            
            let returnedProcessInfos = processManager.processInfos()
            XCTAssertEqual(returnedProcessInfos.count, 0)

            XCTAssertNil(processManager.processInfo(forIdentifier: 999))
            return true
        }
        
        let processManagerHasNoProcessInfoResult = testProcessManagerHasNoProcessInfo(processManager)
        XCTAssertTrue(processManagerHasNoProcessInfoResult)
        let processManagerThree = ProcessManager(processManagerStore: processManagerStore)
        let processManagerHasNoProcessInfoResultTwo = testProcessManagerHasNoProcessInfo(processManagerThree)
        XCTAssertTrue(processManagerHasNoProcessInfoResultTwo)    
    }

}
