//
//  ProcessData.swift
//  Web Console
//
//  Created by Roben Kleene on 12/6/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import Foundation

public struct ProcessData: Equatable {
    let identifier: Int32
    let startTime: Date
    let commandPath: String

    public init?(identifier: Int32,
                 startTime: Date,
                 commandPath: String) {
        // An all whitespace `commandPath` is not allowed
        let trimmedCommandPathCharacterCount = commandPath
            .trimmingCharacters(in: CharacterSet.whitespaces)
            .count
        guard trimmedCommandPathCharacterCount > 0 else {
            return nil
        }

        self.identifier = identifier
        self.startTime = startTime
        self.commandPath = commandPath
    }
}

public func == (lhs: ProcessData, rhs: ProcessData) -> Bool {
    return lhs.identifier == rhs.identifier &&
        lhs.commandPath == rhs.commandPath &&
        lhs.startTime == rhs.startTime
}
