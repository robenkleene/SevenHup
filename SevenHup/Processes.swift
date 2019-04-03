//
//  Processes.swift
//  SevenHup
//
//  Created by Roben Kleene on 4/3/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import Foundation

class Processes {
    class func runningProcesses(withIdentifiers identifiers: [Int32],
                                completionHandler: @escaping ((_ identifierToProcessData: [Int32: ProcessData]?,
        _ error: NSError?) -> Void)) {
        if identifiers.isEmpty {
            completionHandler([Int32: ProcessData](), nil)
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
        let identifiersSet = Set(identifiers)
        let identifierToProcesses = SUPProcesses.identifierToProcesses(forIdentifiers: identifiersSet as Set<NSNumber>)
        return Array(identifierToProcesses.values)
    }
    
    private class func makeProcessDatas(dictionaries: [Any]) -> [Int32: ProcessData] {
        guard let processDictionaries = dictionaries as? [NSDictionary] else {
            assert(false)
            return [Int32: ProcessData]()
        }
        
        var identifierToProcessData = [Int32: ProcessData]()
        for dictionary in processDictionaries {
            if let processData = ProcessData.makeProcessData(dictionary: dictionary) {
                identifierToProcessData[processData.identifier] = processData
            }
        }
        return identifierToProcessData
    }
}
