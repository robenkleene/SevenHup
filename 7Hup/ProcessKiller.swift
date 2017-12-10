//
//  ProcessKiller.swift
//  Web Console
//
//  Created by Roben Kleene on 1/5/16.
//  Copyright © 2016 Roben Kleene. All rights reserved.
//

import Foundation

class ProcessKiller {

    class func kill(_ processInfos: [ProcessInfo],
        completion: ((Bool) -> Void)?)
    {
        var result = true
        for processInfo in processInfos {
            let didKill = killProcessInfo(processInfo)
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
    
    private class func killProcessInfo(_ processInfo: ProcessInfo) -> Bool {
        return WCLProcessKiller.killProcess(withIdentifier: processInfo.identifier)
    }
}
