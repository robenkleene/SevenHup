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
    let startTime: Date

    public init?(identifier: pid_t,
                 name: String,
                 userIdentifier: uid_t,
                 username: String,
                 startTime: Date) {
        // Don't allow all whitespace `name` or `username`
        let trimmedNameCharacterCount = name.trimmingCharacters(in: CharacterSet.whitespaces).count
        let trimmedUsernameCharacterCount = username.trimmingCharacters(in: CharacterSet.whitespaces).count
        guard
            trimmedNameCharacterCount > 0,
            trimmedUsernameCharacterCount > 0
        else {
            return nil
        }

        self.identifier = identifier
        self.name = name
        self.userIdentifier = userIdentifier
        self.username = username
        self.startTime = startTime
    }

    func dictionary() -> NSDictionary {
        let key = ProcessData.key(from: identifier)
        return [
            processIdentifierKey: key,
            processNameKey: name,
            processUserIdentifierKey: userIdentifier,
            processUsernameKey: username,
            processStartTimeKey: startTime
        ]
    }

    static func makeProcessData(dictionary: NSDictionary) -> ProcessData? {
        guard
            let key = dictionary[processIdentifierKey] as? NSString,
            let name = dictionary[processNameKey] as? String,
            let userKey = dictionary[processUserIdentifierKey] as? NSString,
            let username = dictionary[processUsernameKey] as? String,
            let startTime = dictionary[processStartTimeKey] as? Date
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
            username: username,
            startTime: startTime
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
        lhs.username == rhs.username &&
        lhs.startTime == rhs.startTime
}
