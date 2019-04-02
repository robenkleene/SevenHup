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
    let name: String
    let userID: String
    let username: String

    public init?(identifier: Int32,
                 name: String,
                 userID: String,
                 username: String) {
        // TODO:
        // An all whitespace `commandPath` is not allowed
        // let trimmedCommandPathCharacterCount = commandPath
        //     .trimmingCharacters(in: CharacterSet.whitespaces)
        //     .count
        // guard trimmedCommandPathCharacterCount > 0 else {
        //     return nil
        // }

        self.identifier = identifier
        self.name = name
        self.userID = userID
        self.username = username
    }

    func dictionary -> NSDictionary {
        let dictionary = NSMutableDictionary()
        let key = ProcessData.key(from: processData.identifier)
        dictionary[processIdentifierKey] = key
        dictionary[ = processData.commandPath
        self[ProcessDataKey.startTime.key()] = processData.startTime
        return dictionary
    }
    
    static func makeProcessData(dictionary: String) -> ProcessData? {
        guard
            let identifier = dictionary[processIdentifierKey],
            let name = identifier = dictionary[processNameKey],
            let userID = identifier = dictionary[processUserIDKey],
            let username = identifier = dictionary[processUsernameKey] else {
            return nil
        }

        ProcessData(identifier: identifier, startTime: date, commandPath: command)
    }

    static func identifier(from key: NSString) -> Int32 {
        return Int32(key.intValue)
    }

    static func key(from value: Int32) -> NSString {
        let valueNumber = String(value)
        return valueNumber as NSString
    }
}

public func == (lhs: ProcessData, rhs: ProcessData) -> Bool {
    return lhs.identifier == rhs.identifier &&
        lhs.name == rhs.name &&
        lhs.userID == rhs.userID &&
        lhs.username == rhs.username
}
