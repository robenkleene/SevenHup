//
//  ProcessManagerRouter.swift
//  SevenHupTests
//
//  Created by Roben Kleene on 4/1/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import Foundation
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
        if
            let commandPath = task.launchPath,
            let processData = ProcessData(identifier: task.processIdentifier,
                                          startTime: Date(),
                                          commandPath: commandPath) {
            processManager.add(processData)
        }
    }
}
