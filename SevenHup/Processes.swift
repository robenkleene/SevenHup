//
//  Processes.swift
//  SevenHup
//
//  Created by Roben Kleene on 4/3/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import Foundation

class Processes {
    class func runningProcesses(withIdentifiers identifiers: [pid_t],
                                completionHandler: @escaping ((_ identifierToProcessData: [pid_t: ProcessData]?,
                                                               _ error: NSError?) -> Void)) {
        if identifiers.isEmpty {
            completionHandler([pid_t: ProcessData](), nil)
            return
        }
        DispatchQueue.global(qos: .background).async {
            let dictionaries = Processes.processInfos(for: identifiers)
            let processDatas = makeProcessDatas(dictionaries: dictionaries)
            completionHandler(processDatas, nil)
        }
    }

    // MARK: Private

    private class func processInfos(for identifiers: [pid_t]) -> [Any] {
        // let identifiersSet = Set(identifiers)
        // let identifierToProcesses = SUPProcesses.identifierToProcesses(forIdentifiers:
        //                                                                identifiersSet as Set<NSNumber>)
        let identifierToProcesses = SUPProcesses.identifierToProcesses(forIdentifiers: identifiers as [NSNumber])

        return Array(identifierToProcesses.values)
    }

    private class func makeProcessDatas(dictionaries: [Any]) -> [pid_t: ProcessData] {
        guard let processDictionaries = dictionaries as? [NSDictionary] else {
            assert(false)
            return [pid_t: ProcessData]()
        }

        var identifierToProcessData = [pid_t: ProcessData]()
        for dictionary in processDictionaries {
            if let processData = ProcessData.makeProcessData(dictionary: dictionary) {
                identifierToProcessData[processData.identifier] = processData
            }
        }
        return identifierToProcessData
    }
}
