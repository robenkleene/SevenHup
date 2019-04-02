//
//  ProcessManagerRouter.swift
//  SevenHupTests
//
//  Created by Roben Kleene on 4/1/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import Foundation
import SystemConfiguration

@testable import SevenHup
import SodaStream

class ProcessManagerRouter: NSObject, SDATaskRunnerDelegate {
    let processManager: ProcessManager

    init(processManager: ProcessManager) {
        self.processManager = processManager
    }

    // MARK: WCLTaskRunnerDelegate

    func taskDidFinish(_ task: Process) {
        _ = processManager.removeProcess(forIdentifier: task.processIdentifier)
    }

    func task(_ task: Process,
              didRunCommandPath commandPath: String,
              arguments _: [String]?,
              directoryPath _: String?) {
        // Can alsu use `UserName()` to just get the username
        let userInfo = type(of: self).getUserInfo()
        let userIdentifier = userInfo.userIdentifier
        let identifier = task.processIdentifier
        guard
            let username = userInfo.username,
            let name = task.launchPath,
            let processData = ProcessData(identifier: identifier,
                                          name: name,
                                          userIdentifier: userIdentifier,
                                          username: username,
                                          startTime: Date()) else {
            assert(false)
            return
        }
        processManager.add(processData)
    }

    private class func getUserInfo() -> (username: String?, userIdentifier: uid_t, groupIdentifier: gid_t) {
        var uid: uid_t = 0
        var gid: gid_t = 0
        let username = SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) as String?
        return (username: username, userIdentifier: uid, groupIdentifier: gid)
    }
}
