//
//  ProcessFilter.swift
//  SevenHup
//
//  Created by Roben Kleene on 4/1/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import Foundation

extension ProcessFilter {
    class func runningProcessMap(matching processDatas: [ProcessData],
                                 completionHandler: @escaping ((_ identifierToProcessData: [Int32: ProcessData]?,
                                                                _ error: NSError?) -> Void)) {
        let identifiers = processDatas.map { $0.identifier }
        runningProcesses(withIdentifiers: identifiers) { (identifierToProcessData, error) -> Void in
            if let error = error {
                completionHandler(nil, error)
                return
            }

            guard var identifierToProcessData = identifierToProcessData else {
                completionHandler([Int32: ProcessData](), nil)
                return
            }

            guard !identifierToProcessData.isEmpty else {
                completionHandler(identifierToProcessData, nil)
                return
            }

            for processData in processDatas {
                if let runningProcessData = identifierToProcessData[processData.identifier] {
                    assert(runningProcessData.identifier == processData.identifier)
                    if !doesRunningProcessData(runningProcessData, matchProcessData: processData) {
                        identifierToProcessData.removeValue(forKey: processData.identifier)
                    }
                }
            }

            completionHandler(identifierToProcessData, nil)
        }
    }

    class func doesRunningProcessData(_ runningProcessData: ProcessData,
                                      matchProcessData processData: ProcessData) -> Bool {
        // Make sure the running process started on or before the other
        // `ProcessData`'s `startTime`
        if runningProcessData.startTime.compare(processData.startTime as Date) == ComparisonResult.orderedDescending {
            return false
        }
        return true
    }
}

class ProcessFilter {
    class func runningProcesses(withIdentifiers identifiers: [Int32],
                                completionHandler: @escaping ((_ identifierToProcessData: [Int32: ProcessData]?,
                                                               _ error: NSError?) -> Void)) {
        Processes.runningProcesses(withIdentifiers: identifiers, completionHandler: completionHandler)
    }
}
