//
//  ProcessFilter.swift
//  Web Console
//
//  Created by Roben Kleene on 12/17/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
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

            for processData in processDatas {
                if let runningProcessData = identifierToProcessData[processData.identifier] {
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
        assert(runningProcessData.identifier == processData.identifier)

        // Make sure the running process started on or before the other `ProcessData`'s `startTime`
        if runningProcessData.startTime.compare(processData.startTime as Date) == ComparisonResult.orderedDescending {
            return false
        }

        return true
    }
}

class ProcessFilter {
    class func runningProcesses(withIdentifiers identifiers: [Int32],
                                completionHandler: @escaping ((_ identifierToProcessData: [Int32: ProcessData]?, _ error: NSError?) -> Void)) {
        if identifiers.isEmpty {
            let userInfo = [NSLocalizedDescriptionKey: "No identifiers specified"]
            let error = NSError(domain: errorDomain, code: 100, userInfo: userInfo)
            completionHandler(nil, error)
            return
        }

        let commandPath = "/bin/ps"
        let identifiersParameter = identifiers.map({ String($0) }).joined(separator: ",")
        let arguments = ["-o pid=,lstart=,args=", "-p \(identifiersParameter)"]

        // o: Change format
        // pid: Process ID
        // lstart: Start time
        // args: Command & Arguments
        // = Means don't display header for this column

        _ = SDATaskRunner.runTaskUntilFinished(withCommandPath: commandPath,
                                               withArguments: arguments as [NSString],
                                               inDirectoryPath: nil) { (standardOutput, _, error) -> Void in

            if let error = error {
                if error.code == NSError.TaskTerminatedErrorCode.nonzeroExitStatus.rawValue {
                    if
                        let exitStatus = error.userInfo[NSError.TaskTerminatedUserInfoKey.exitStatus.rawValue as String] as? NSNumber,
                        exitStatus.int32Value == 1 {
                        // If the process identifier is not found, `ps` exits with an exit status of 1
                        // So reinterpret that case as no processes found
                        completionHandler([Int32: ProcessData](), nil)
                        return
                    }
                }

                completionHandler(nil, error)
                return
            }

            guard let standardOutput = standardOutput else {
                completionHandler([Int32: ProcessData](), nil)
                return
            }

            let processDatas = makeProcessDatas(output: standardOutput)
            completionHandler(processDatas, nil)
        }
    }

    // MARK: Private

    class func makeProcessDatas(output: String) -> [Int32: ProcessData] {
        var identifierToProcessData = [Int32: ProcessData]()
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if let processData = makeProcessData(line: line) {
                identifierToProcessData[processData.identifier] = processData
            }
        }

        return identifierToProcessData
    }

    private class func makeProcessData(line: String) -> ProcessData? {
        if line.count < 35 {
            return nil
        }

        let rawIdentifier = line.prefix(5).trimmingCharacters(in: CharacterSet.whitespaces)

        let dateStartIndex = line.index(line.startIndex, offsetBy: 6)
        let dateEndIndex = line.index(line.startIndex, offsetBy: 30)
        let rawStartDate = String(line[dateStartIndex ..< dateEndIndex])

        let commandIndex = line.index(line.startIndex, offsetBy: 35)
        let command = String(line[commandIndex...])

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"

        guard let identifier = Int32(rawIdentifier), let date = dateFormatter.date(from: rawStartDate) else {
            return nil
        }

        return ProcessData(identifier: identifier, startTime: date, commandPath: command)
    }
}
