//
//  ProcessKiller.swift
//  Web Console
//
//  Created by Roben Kleene on 1/5/16.
//  Copyright © 2016 Roben Kleene. All rights reserved.
//

import Foundation

class ProcessKiller {
    class func kill(_ processDatas: [ProcessData],
                    completion: ((Bool) -> Void)?) {
        var result = true
        for processData in processDatas {
            let didKill = killProcessData(processData)
            if !didKill {
                result = false
                break
            }
        }

        // TODO: This should really use a more sophisticated mechanism for
        // tracking the termination state of the target process. E.g.:
        // https://developer.apple.com/library/mac/technotes/tn2050/_index.html
        // This wrapper function assures callers to the function are designed
        // around the correct implementation.
        completion?(result)
    }

    // MARK: Private

    private class func killProcessData(_ processData: ProcessData) -> Bool {
        return SUPProcessKiller.killProcess(withIdentifier: processData.identifier)
    }
}
