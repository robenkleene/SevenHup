//
//  ProcessStatusFilter.swift
//  SevenHup
//
//  Created by Roben Kleene on 4/3/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import Foundation
import SodaStream

class ProcessStatusFilter {
    class func runningProcesses(withIdentifiers identifiers: [pid_t],
                                completionHandler: @escaping ((_ identifierToProcessData: [pid_t: ProcessData]?,
                                                               _ error: NSError?) -> Void)) {
        if identifiers.isEmpty {
            completionHandler([pid_t: ProcessData](), nil)
            return
        }

        let commandPath = "/bin/ps"
        let identifiersParameter = identifiers.map { String($0) }.joined(separator: ",")
        let arguments = ["-o pid=,lstart=,args=,uid=,user=", "-p \(identifiersParameter)"]

        // o: Change format
        // pid: Process ID
        // lstart: Start time
        // args: Command & Arguments
        // = Means don't display header for this column
        _ = SDATaskRunner.runTaskUntilFinished(withCommandPath: commandPath,
                                               withArguments: arguments,
                                               inDirectoryPath: nil,
                                               withEnvironment: nil) { (standardOutput, _, error) -> Void in

            if let error = error {
                if error.code == NSError.TaskTerminatedErrorCode.nonzeroExitStatus.rawValue {
                    let exitStatusKey = NSError.TaskTerminatedUserInfoKey.exitStatus.rawValue as String
                    if
                        let exitStatus = error.userInfo[exitStatusKey] as? NSNumber,
                        exitStatus.int32Value == 1
                    {
                        // If the process identifier is not found, `ps` exits with an exit status of 1
                        // So reinterpret that case as no processes found
                        completionHandler([pid_t: ProcessData](), nil)
                        return
                    }
                }

                completionHandler(nil, error)
                return
            }

            guard let standardOutput = standardOutput else {
                completionHandler([pid_t: ProcessData](), nil)
                return
            }

            let processDatas = makeProcessDatas(output: standardOutput)
            completionHandler(processDatas, nil)
        }
    }

    // MARK: Private

    class func makeProcessDatas(output: String) -> [pid_t: ProcessData] {
        var identifierToProcessData = [pid_t: ProcessData]()
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if let processData = makeProcessData(line: line) {
                identifierToProcessData[processData.identifier] = processData
            }
        }

        return identifierToProcessData
    }

    private class func makeProcessData(line: String) -> ProcessData? {
        if line.count < 106 {
            return nil
        }

        let rawIdentifier = line.prefix(5).trimmingCharacters(in: CharacterSet.whitespaces)

        let dateStartIndex = line.index(line.startIndex, offsetBy: 6)
        let dateEndIndex = line.index(line.startIndex, offsetBy: 30)
        let rawStartDate = String(line[dateStartIndex ..< dateEndIndex])

        let commandStartIndex = line.index(line.startIndex, offsetBy: 35)
        let commandEndIndex = line.index(line.startIndex, offsetBy: 100)
        let rawCommand = String(line[commandStartIndex ..< commandEndIndex])
        let trimmedCommand = rawCommand.trimmingCharacters(in: CharacterSet.whitespaces)

        let userIdentifierStartIndex = line.index(line.startIndex, offsetBy: 100)
        let userIdentifierEndIndex = line.index(line.startIndex, offsetBy: 106)
        let rawUserIdentifier = String(line[userIdentifierStartIndex ..< userIdentifierEndIndex])
        let trimmedUserIdentifier = rawUserIdentifier.trimmingCharacters(in: CharacterSet.whitespaces)

        guard let userIdentifier = uid_t(trimmedUserIdentifier) else {
            return nil
        }

        let usernameIdentifierStartIndex = line.index(line.startIndex, offsetBy: 106)
        let rawUsername = String(line[usernameIdentifierStartIndex...])
        let username = rawUsername.trimmingCharacters(in: .whitespacesAndNewlines)

        if username.isEmpty {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"

        guard let identifier = pid_t(rawIdentifier), let startTime = dateFormatter.date(from: rawStartDate) else {
            return nil
        }

        return ProcessData(identifier: identifier,
                           name: trimmedCommand,
                           userIdentifier: userIdentifier,
                           username: username,
                           startTime: startTime)!
    }
}
