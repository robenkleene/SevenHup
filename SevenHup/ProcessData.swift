//
//  ProcessData.swift
//  Web Console
//
//  Created by Roben Kleene on 12/6/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import Foundation

public struct ProcessData: Equatable {
    let identifier: pid_t
    let name: String
    let userIdentifier: uid_t
    let username: String

    public init?(identifier: pid_t,
                 name: String,
                 userIdentifier: uid_t,
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
            let userKey = dictionary[processUserIdentifierKey] as? String,
            let username = dictionary[processUsernameKey]  as? String
            else {
            return nil
        }

        let identifier = ProcessData.identifier(from: key)
        let userIdentifier = ProcessData.userIdentifier(from: userKey)

        return ProcessData(
            identifier: identifier,
            name: name,
            userIdentifier: userIdentifier,
            username: username
        )
    }

    static func userIdentifier(from key: String) -> uid_t {
        return uid_t((key as NSString).intValue)
    }
    
    static func identifier(from key: String) -> pid_t {
        return pid_t((key as NSString).intValue)
    }

    static func key(from value: Int32) -> NSString {
        let valueNumber = String(value) as NSString
        return valueNumber
    }
}

public func == (lhs: ProcessData, rhs: ProcessData) -> Bool {
    return lhs.identifier == rhs.identifier &&
        lhs.name == rhs.name &&
        lhs.userIdentifier == rhs.userIdentifier &&
        lhs.username == rhs.username
}
