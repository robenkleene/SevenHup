//
//  TaskHelper.swift
//  Web Console
//
//  Created by Roben Kleene on 1/7/16.
//  Copyright © 2016 Roben Kleene. All rights reserved.
//

import XCTest

extension XCTestCase {
    func wait(forTerminationOf tasks: [Process]) {
        var expectation: XCTestExpectation?
        let observers = NSMutableArray()

        for task in tasks {
            if !task.isRunning {
                continue
            }

            if expectation == nil {
                expectation = self.expectation(description: "Tasks terminated")
            }

            let clearObserver: (NSObjectProtocol) -> Void = { observer in
                NotificationCenter.default.removeObserver(observer)
                observers.remove(observer)
                if let expectation = expectation, observers.count == 0 {
                    expectation.fulfill()
                }
            }

            var observer: NSObjectProtocol?
            observer = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification,
                                                              object: task,
                                                              queue: nil) { _ in
                if let observer = observer {
                    clearObserver(observer)
                }
            }

            if let observer = observer {
                observers.add(observer)
                if !task.isRunning {
                    clearObserver(observer)
                }
            }
        }

        waitForExpectations(timeout: testTimeout) { _ in
            let allObservers = Array(observers)
            for observer in allObservers {
                observers.remove(observer)
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
