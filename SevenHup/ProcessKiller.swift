//
//  ProcessKiller.swift
//  Web Console
//
//  Created by Roben Kleene on 1/5/16.
//  Copyright © 2016 Roben Kleene. All rights reserved.
//

let timeoutTimeInterval = TimeInterval(5)

import Foundation

class ProcessKiller {
    class func kill(_ processDatas: [ProcessData],
                    completion: ((Bool) -> Void)?) {
        var result = true
        var processMonitorsSet = Set<SUPProcessMonitor>()
        var didTimeout = false
        guard !processDatas.isEmpty else {
            completion?(result)
            return
        }
        for processData in processDatas {
            let processMonitor = SUPProcessMonitor(identifier: processData.identifier)
            processMonitorsSet.insert(processMonitor)
            processMonitor.watch { success in
                guard !didTimeout else {
                    return
                }
                if !success {
                    result = false
                }
                processMonitorsSet.remove(processMonitor)
                if processMonitorsSet.count == 0 {
                    completion?(result)
                }
            }
            let didKill = killProcessData(processData)
            if !didKill {
                result = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutTimeInterval) {
            didTimeout = true
            result = false
            processMonitorsSet.removeAll()
            completion?(result)
        }
    }

    // MARK: Private

    private class func killProcessData(_ processData: ProcessData) -> Bool {
        return SUPProcessKiller.killProcess(withIdentifier: processData.identifier)
    }
}
