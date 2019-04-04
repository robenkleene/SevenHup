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
    private typealias ProcessDictionary = [NSString: AnyObject]
    private let processManagerStore: ProcessManagerStore
    private var identifierKeyToProcessDataValue = ProcessDictionary()
    public var count: Int {
        return identifierKeyToProcessDataValue.count
    }

    public init(processManagerStore: ProcessManagerStore) {
        if let processDataDictionary = processManagerStore.dictionary(forKey: runningProcessesKey) {
            identifierKeyToProcessDataValue = processDataDictionary as ProcessDictionary
        }
        self.processManagerStore = processManagerStore
    }

    public func add(_ processData: ProcessData) {
        let keyDictionary = type(of: self).keyAndDictionary(from: processData)
        objc_sync_enter(self)
        identifierKeyToProcessDataValue[keyDictionary.key] = keyDictionary.dictionary
        objc_sync_exit(self)
        save()
    }

    public func removeAll() {
        objc_sync_enter(self)
        identifierKeyToProcessDataValue.removeAll()
        objc_sync_exit(self)
        save()
    }

    public func removeProcess(forIdentifier identifier: pid_t) -> ProcessData? {
        let processData = self.processData(forIdentifier: identifier, remove: true)
        return processData
    }

    public func processData(forIdentifier identifier: pid_t) -> ProcessData? {
        return processData(forIdentifier: identifier, remove: false)
    }

    public func processDatas() -> [ProcessData] {
        objc_sync_enter(self)
        let values = identifierKeyToProcessDataValue.values
        objc_sync_exit(self)

        var processDatas = [ProcessData]()

        for value in values {
            if let
                dictionary = value as? NSDictionary,
                let processData = ProcessData.makeProcessData(dictionary: dictionary) {
                processDatas.append(processData)
            }
        }

        return processDatas
    }

    public func runningProcessDatas(completionHandler: @escaping ((_ identifierToProcessData: [pid_t: ProcessData]?,
                                                                   _ error: NSError?) -> Void)) {
        runningProcessDatas(kill: false, completionHandler: completionHandler)
    }

    public func killAndRemoveRunningProcessDatas(completionHandler: @escaping ((
        _ identifierToProcessData: [pid_t: ProcessData]?,
        _ error: NSError?
    ) -> Void)) {
        runningProcessDatas(kill: true, completionHandler: completionHandler)
    }

    // MARK: Private

    private func runningProcessDatas(kill: Bool,
                                     completionHandler: @escaping ((_ identifierToProcessData: [pid_t: ProcessData]?,
                                                                    _ error: NSError?) -> Void)) {
        ProcessFilter.runningProcessMap(matching: processDatas()) { optionalIdentifierToProcessData, error in
            guard
                kill,
                error == nil,
                let identifierToProcessData = optionalIdentifierToProcessData,
                !identifierToProcessData.isEmpty
            else {
                completionHandler(optionalIdentifierToProcessData, error)
                return
            }
            let processDatas = Array(identifierToProcessData.values)

            DispatchQueue.main.async {
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
    }

    private func remove(processDatas: [ProcessData]) {
        for processData in processDatas {
            _ = removeProcess(forIdentifier: processData.identifier)
        }
    }

    private func save() {
        processManagerStore.set(identifierKeyToProcessDataValue as AnyObject?, forKey: runningProcessesKey)
    }

    private func processData(forIdentifier identifier: pid_t, remove: Bool) -> ProcessData? {
        guard let processDataDictionary = processDataDictionary(forIdentifier: identifier, remove: remove) else {
            return nil
        }

        return ProcessData.makeProcessData(dictionary: processDataDictionary)
    }

    // MARK: Helper

    private func processDataDictionary(forIdentifier identifier: pid_t, remove: Bool) -> NSDictionary? {
        let key = ProcessData.key(from: identifier)
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

    private class func keyAndDictionary(from processData: ProcessData) -> (key: NSString, dictionary: NSDictionary) {
        let key = ProcessData.key(from: processData.identifier)
        let dictionary = processData.dictionary()
        return (key: key, dictionary: dictionary)
    }
}
