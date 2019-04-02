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
    let userIdentifier: String
    let username: String

    public init?(identifier: Int32,
                 name: String,
                 userIdentifier: String,
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
        self.userIdentifier = userIdentifier
        self.username = username
    }

    func dictionary() -> NSDictionary {
        let key = ProcessData.key(from: identifier)
        return [
            processIdentifierKey: key,
            processNameKey: name,
            processUserIdentifierKey: userIdentifier,
            processUsernameKey: username
        ]
    }
    
    static func makeProcessData(dictionary: NSDictionary) -> ProcessData? {
        guard
            let key = dictionary[processIdentifierKey] as? String,
            let name = dictionary[processNameKey] as? String,
            let userIdentifier = dictionary[processUserIdentifierKey] as? String,
            let username = dictionary[processUsernameKey]  as? String
            else {
            return nil
        }

        let identifier = ProcessData.identifier(from: key)
        return ProcessData(
            identifier: identifier,
            name: name,
            userIdentifier: userIdentifier,
            username: username
        )
    }

    static func identifier(from key: String) -> Int32 {
        return Int32((key as NSString).intValue)
    }

    static func key(from value: Int32) -> String {
        let valueNumber = String(value)
        return valueNumber
    }
}

public func == (lhs: ProcessData, rhs: ProcessData) -> Bool {
    return lhs.identifier == rhs.identifier &&
        lhs.name == rhs.name &&
        lhs.userIdentifier == rhs.userIdentifier &&
        lhs.username == rhs.username
}
