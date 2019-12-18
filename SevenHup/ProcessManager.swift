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

    @discardableResult
    public func removeProcess(forIdentifier identifier: pid_t) -> ProcessData? {
        let processData = self.processData(forIdentifier: identifier, remove: true)
        return processData
    }

    public func processData(forIdentifier identifier: pid_t) -> ProcessData? {
        return processData(forIdentifier: identifier, remove: false)
    }

    public func getProcessDatas() -> [ProcessData] {
        var processDatas = [ProcessData]()

        objc_sync_enter(self)
        let values = identifierKeyToProcessDataValue.values
        objc_sync_exit(self)

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
        let processDatas = getProcessDatas()
        runningProcessDatas(processDatas, kill: false, completionHandler: completionHandler)
    }

    public func killAndRemoveRunningProcessDatas(completionHandler: @escaping ((
        _ identifierToProcessData: [pid_t: ProcessData]?,
        _ error: NSError?
    ) -> Void)) {
        let processDatas = getProcessDatas()

        runningProcessDatas(processDatas, kill: true) { [weak self] identifierToProcessData, error in
            guard let strongSelf = self else {
                return
            }
            let identifiers = processDatas.map { $0.identifier }
            if let identifierToProcessData = identifierToProcessData {
                let identifiersSet = Set(identifiers)
                let runningIdentifiers = identifierToProcessData.keys
                let runningIdentifiersSet = Set(runningIdentifiers)
                let notRunningIdentifiers = identifiersSet.subtracting(runningIdentifiersSet)
                strongSelf.remove(processIdentifiers: Array(notRunningIdentifiers))
            } else {
                for identifier in identifiers {
                    strongSelf.removeProcess(forIdentifier: identifier)
                }
            }
            completionHandler(identifierToProcessData, error)
        }
    }

    // MARK: Private

    private func runningProcessDatas(_ processDatas: [ProcessData],
                                     kill: Bool,
                                     completionHandler: @escaping ((_ identifierToProcessData: [pid_t: ProcessData]?,
                                                                    _ error: NSError?) -> Void)) {
        ProcessFilter.runningProcessMap(matching: processDatas) { optionalIdentifierToProcessData, error in
            guard
                kill,
                error == nil,
                let identifierToProcessData = optionalIdentifierToProcessData,
                !identifierToProcessData.isEmpty
            else {
                completionHandler(optionalIdentifierToProcessData, error)
                return
            }
            let runningProcessDatas = Array(identifierToProcessData.values)

            DispatchQueue.main.async {
                ProcessKiller.kill(runningProcessDatas) { success in
                    guard success else {
                        let error = ProcessManagerError.failedToKillError(processDatas: runningProcessDatas)
                        completionHandler(optionalIdentifierToProcessData, error as NSError)
                        return
                    }
                    self.remove(processDatas: runningProcessDatas)
                    completionHandler(optionalIdentifierToProcessData, error)
                }
            }
        }
    }

    private func remove(processDatas: [ProcessData]) {
        for processData in processDatas {
            removeProcess(forIdentifier: processData.identifier)
        }
    }

    private func remove(processIdentifiers: [pid_t]) {
        for processIdentifier in processIdentifiers {
            removeProcess(forIdentifier: processIdentifier)
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
