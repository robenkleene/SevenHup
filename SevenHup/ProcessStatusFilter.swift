//
//  ProcessStatusFilter.swift
//  SevenHup
//
//  Created by Roben Kleene on 4/3/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import Foundation
import SodaStream

import SystemConfiguration


class ProcessStatusFilter {
    class func runningProcesses(withIdentifiers identifiers: [Int32],
                                completionHandler: @escaping ((_ identifierToProcessData: [Int32: ProcessData]?,
        _ error: NSError?) -> Void)) {
        if identifiers.isEmpty {
            completionHandler([Int32: ProcessData](), nil)
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
                                                        let exitStatusKey = NSError.TaskTerminatedUserInfoKey.exitStatus.rawValue as String
                                                        if
                                                            let exitStatus = error.userInfo[exitStatusKey] as? NSNumber,
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
        
        guard let identifier = Int32(rawIdentifier), let startTime = dateFormatter.date(from: rawStartDate) else {
            return nil
        }

        // TODO: This needs to come from the `ps` output!
        var userIdentifier: uid_t = 0
        var groupIdentifier: gid_t = 0
        guard let username = SCDynamicStoreCopyConsoleUser(nil, &userIdentifier, &groupIdentifier) as String? else {
            assert(false)
            return nil
        }

        return ProcessData(identifier: identifier,
                           name: command,
                           userIdentifier: userIdentifier,
                           username: username,
                           startTime: startTime)!
    }
}
