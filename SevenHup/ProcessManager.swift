//
//  ProcessManager.swift
//  Web Console
//
//  Created by Roben Kleene on 12/6/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import Foundation

extension UserDefaults: ProcessManagerStore {}

public protocol ProcessManagerStore {
    func set(_ value: Any?, forKey defaultName: String)
    func dictionary(forKey defaultName: String) -> [String: Any]?
}

enum ProcessManagerError: Error {
    case failedToKillError(processDatas: [ProcessData])
}

public class ProcessManager {
    enum ProcessDataKey: String {
        case identifier
        case commandPath
        case startTime
        func key() -> NSString {
            return rawValue as NSString
        }
    }

    private let processManagerStore: ProcessManagerStore
    private var identifierKeyToProcessDataValue = [NSString: AnyObject]()

    public init(processManagerStore: ProcessManagerStore) {
        if let processDataDictionary = processManagerStore.dictionary(forKey: runningProcessesKey) {
            identifierKeyToProcessDataValue = processDataDictionary as [NSString: AnyObject]
        }
        self.processManagerStore = processManagerStore
    }

    public func add(_ processData: ProcessData) {
        let keyValue = type(of: self).keyAndValue(from: processData)
        objc_sync_enter(self)
        identifierKeyToProcessDataValue[keyValue.key] = keyValue.value
        objc_sync_exit(self)
        save()
    }

    public func removeProcess(forIdentifier identifier: Int32) -> ProcessData? {
        let processData = self.processData(forIdentifier: identifier, remove: true)
        return processData
    }

    public func processData(forIdentifier identifier: Int32) -> ProcessData? {
        return processData(forIdentifier: identifier, remove: false)
    }

    public func processDatas() -> [ProcessData] {
        objc_sync_enter(self)
        let values = identifierKeyToProcessDataValue.values
        objc_sync_exit(self)

        var processDatas = [ProcessData]()

        for value in values {
            if let
                value = value as? NSDictionary,
                let processData = type(of: self).processData(for: value) {
                processDatas.append(processData)
            }
        }

        return processDatas
    }

    public func runningProcessDatas(completionHandler: @escaping ((_ identifierToProcessData: [Int32: ProcessData]?,
                                                                   _ error: NSError?) -> Void)) {
        runningProcessDatas(kill: false, completionHandler: completionHandler)
    }

    public func killAndRemoveRunningProcessDatas(completionHandler: @escaping ((_ identifierToProcessData: [Int32: ProcessData]?,
                                                                       _ error: NSError?) -> Void)) {
        runningProcessDatas(kill: true, completionHandler: completionHandler)
    }

    // MARK: Private

    private func runningProcessDatas(kill: Bool, completionHandler: @escaping ((_ identifierToProcessData: [Int32: ProcessData]?,
                                                                                _ error: NSError?) -> Void)) {
        ProcessFilter.runningProcessMap(matching: processDatas()) { optionalIdentifierToProcessData, error in
            guard
                kill,
                error == nil,
                let identifierToProcessData = optionalIdentifierToProcessData
            else {
                completionHandler(optionalIdentifierToProcessData, error)
                return
            }
            let processDatas = Array(identifierToProcessData.values)
            ProcessKiller.kill(processDatas) { success in
                guard success else {
                    let error = ProcessManagerError.failedToKillError(processDatas: processDatas)
                    completionHandler(optionalIdentifierToProcessData, error as NSError)
                    return
                }
                self.remove(processDatas: processDatas)
                completionHandler(optionalIdentifierToProcessData, error)
            }
        }
    }

    private func remove(processDatas: [ProcessData]) {
        for processData in processDatas {
            _ = removeProcess(forIdentifier: processData.identifier)
        }
    }
    
    private func save() {
        processManagerStore.set(identifierKeyToProcessDataValue as AnyObject?, forKey: runningProcessesKey)
    }

    private func processData(forIdentifier identifier: Int32, remove: Bool) -> ProcessData? {
        guard let processDataValue = processDataValue(forIdentifier: identifier, remove: remove) else {
            return nil
        }

        return type(of: self).processData(for: processDataValue)
    }

    // MARK: Helper

    private func processDataValue(forIdentifier identifier: Int32, remove: Bool) -> NSDictionary? {
        let key = type(of: self).key(from: identifier)
        if remove {
            objc_sync_enter(self)
            let processDataValue = identifierKeyToProcessDataValue.removeValue(forKey: key) as? NSDictionary
            objc_sync_exit(self)
            save()
            return processDataValue
        } else {
            objc_sync_enter(self)
            let value = identifierKeyToProcessDataValue[key] as? NSDictionary
            objc_sync_exit(self)
            return value
        }
    }

    private class func keyAndValue(from processData: ProcessData) -> (key: NSString, value: NSDictionary) {
        let key = self.key(from: processData.identifier)
        let value = self.value(for: processData)
        return (key: key, value: value)
    }

    private class func processData(for dictionary: NSDictionary) -> ProcessData? {
        guard
            let key = dictionary[ProcessDataKey.identifier.key()] as? NSString,
            let commandPath = dictionary[ProcessDataKey.commandPath.key()] as? String,
            let startTime = dictionary[ProcessDataKey.startTime.key()] as? Date
        else {
            return nil
        }

        let identifier = self.identifier(from: key)

        return ProcessData(identifier: identifier,
                           startTime: startTime,
                           commandPath: commandPath)
    }

    private class func value(for processData: ProcessData) -> NSDictionary {
        let dictionary = NSMutableDictionary()
        let key = self.key(from: processData.identifier)
        dictionary[ProcessDataKey.identifier.key()] = key
        dictionary[ProcessDataKey.commandPath.key()] = processData.commandPath
        dictionary[ProcessDataKey.startTime.key()] = processData.startTime
        return dictionary
    }

    private class func identifier(from key: NSString) -> Int32 {
        return Int32(key.intValue)
    }

    private class func key(from value: Int32) -> NSString {
        let valueNumber = String(value)
        return valueNumber as NSString
    }
}
