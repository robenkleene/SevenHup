//
//  ProcessFilter.swift
//  SevenHup
//
//  Created by Roben Kleene on 4/1/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import Foundation

import SodaStream

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
        if identifiers.isEmpty {
            let userInfo = [NSLocalizedDescriptionKey: "No identifiers specified"]
            let error = NSError(domain: errorDomain, code: noIdentifiersErrorCode, userInfo: userInfo)
            completionHandler(nil, error)
            return
        }
        DispatchQueue.global(qos: .background).async {
            // TODO: This is slow, instead figure out if we can either filter the processes as we are accessing them, or at least only collect the identifiers we're looking for to begin with
            let identifierToProcesses = SUPProcesses.identifierToProcesses()
            var processDictionaries = [NSDictionary]()
            for identifier in identifiers {
                let key = ProcessData.key(from: identifier)
                guard let processDictionary = identifierToProcesses[key] as? NSDictionary else {
                    continue
                }
                processDictionaries.append(processDictionary)
            }
            let processDatas = makeProcessDatas(dictionaries: processDictionaries)
            completionHandler(processDatas, nil)
        }
    }

    // MARK: Private

    private class func makeProcessDatas(dictionaries: [NSDictionary]) -> [Int32: ProcessData] {
        var identifierToProcessData = [Int32: ProcessData]()
        for dictionary in dictionaries {
            if let processData = ProcessData.makeProcessData(dictionary: dictionary) {
                identifierToProcessData[processData.identifier] = processData
            }
        }
        return identifierToProcessData
    }
}
