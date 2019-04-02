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
            let key = dictionary[processIdentifierKey] as? NSString,
            let name = dictionary[processNameKey] as? String,
            let userKey = dictionary[processUserIdentifierKey] as? NSString,
            let username = dictionary[processUsernameKey] as? String
        else {
            assert(false)
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

    static func userIdentifier(from key: NSString) -> uid_t {
        return uid_t(key.intValue)
    }

    static func identifier(from key: NSString) -> pid_t {
        return pid_t(key.intValue)
    }

    // This is identifiers are stored as `NSString` instead of `NSNumber`
    // because at the bottom of everything we're depending on the
    // `dictionary(forKey defaultName: String) -> [String: Any]?` function on
    // `NSUserDefaults` that uses a string as the key. So using a string here,
    // though less than ideal, allows us to convert between one less type.
    static func key(from identifier: pid_t) -> NSString {
        return String(identifier) as NSString
    }
}

public func == (lhs: ProcessData, rhs: ProcessData) -> Bool {
    return lhs.identifier == rhs.identifier &&
        lhs.name == rhs.name &&
        lhs.userIdentifier == rhs.userIdentifier &&
        lhs.username == rhs.username
}
