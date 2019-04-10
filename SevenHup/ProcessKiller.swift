//
//  ProcessKiller.swift
//  Web Console
//
//  Created by Roben Kleene on 1/5/16.
//  Copyright © 2016 Roben Kleene. All rights reserved.
//

let timeoutTimeInterval = TimeInterval(15)

import Foundation

class ProcessKiller {
    class func kill(_ processDatas: [ProcessData],
                    timeoutInterval: TimeInterval,
                    completion: ((Bool) -> Void)?) {
        // `SUPProcessMonitor` doesn't work if not called on the main thread
        assert(Thread.isMainThread)
        var result = true
        var processMonitorsSet = Set<SUPProcessMonitor>()
        var didTimeout = false
        var completionCopy = completion
        guard !processDatas.isEmpty else {
            completionCopy?(result)
            completionCopy = nil
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
                    if !didTimeout {
                        completionCopy?(result)
                        completionCopy = nil
                        return
                    }
                }
            }
            let didKill = killProcessData(processData)
            if !didKill {
                result = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutTimeInterval) {
            guard
                processMonitorsSet.count > 0,
                completionCopy != nil else {
                    return
            }
            didTimeout = true
            result = false
            processMonitorsSet.removeAll()
            completionCopy?(result)
            completionCopy = nil
        }
    }
    
    class func kill(_ processDatas: [ProcessData],
                    completion: ((Bool) -> Void)?) {
        kill(processDatas, timeoutInterval: timeoutTimeInterval, completion: completion)
    }

    // MARK: Private

    private class func killProcessData(_ processData: ProcessData) -> Bool {
        return SUPProcessKiller.killProcess(withIdentifier: processData.identifier)
    }
}
