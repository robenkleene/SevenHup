//
//  Processes.swift
//  SevenHup
//
//  Created by Roben Kleene on 4/3/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

import Foundation

class Processes {
    class func processInfos(for identifiers: [pid_t]) -> [Any] {
        let identifiersSet = Set(identifiers)
        let identifierToProcesses = SUPProcesses.identifierToProcesses(forIdentifiers: identifiersSet as Set<NSNumber>)
        return Array(identifierToProcesses.values)
    }
}
