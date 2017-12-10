//
//  ProcessManager.swift
//  Web Console
//
//  Created by Roben Kleene on 12/6/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import Foundation

extension UserDefaults: ProcessManagerStore { }

protocol ProcessManagerStore {
    func set(_ value: Any?, forKey defaultName: String)
    func dictionary(forKey defaultName: String) -> [String : Any]?
}
class ProcessManager {
    
    enum ProcessInfoKey: String {
        case identifier = "identifier"
        case commandPath = "commandPath"
        case startTime = "startTime"
        func key() -> NSString {
            return self.rawValue as NSString
        }
    }
    
    private let processManagerStore: ProcessManagerStore
    private var identifierKeyToProcessInfoValue = [NSString: AnyObject]()
    
    convenience init() {
        self.init(processManagerStore: UserDefaultsManager.standardUserDefaults())
    }
    
    init(processManagerStore: ProcessManagerStore) {
        if let processInfoDictionary = processManagerStore.dictionary(forKey: runningProcessesKey) {
            identifierKeyToProcessInfoValue = processInfoDictionary as [NSString : AnyObject]
        }
        self.processManagerStore = processManagerStore
    }
    
    func add(_ processInfo: ProcessInfo) {
        let keyValue = type(of: self).keyAndValue(from: processInfo)
        objc_sync_enter(self)
        identifierKeyToProcessInfoValue[keyValue.key] = keyValue.value
        objc_sync_exit(self)
        save()
    }
    
    func removeProcess(forIdentifier identifier: Int32) -> ProcessInfo? {
        let processInfo = self.processInfo(forIdentifier: identifier, remove: true)
        return processInfo
    }
    
    func processInfo(forIdentifier identifier: Int32) -> ProcessInfo? {
        return processInfo(forIdentifier: identifier, remove: false)
    }
    
    func processInfos() -> [ProcessInfo] {
        objc_sync_enter(self)
        let values = identifierKeyToProcessInfoValue.values
        objc_sync_exit(self)
        
        var processInfos = [ProcessInfo]()
        
        for value in values {
            if let
                value = value as? NSDictionary,
                let processInfo = type(of: self).processInfo(for: value)
            {
                processInfos.append(processInfo)
            }
        }
        
        return processInfos
    }
    
    // MARK: Private
    
    private func save() {
        processManagerStore.set(identifierKeyToProcessInfoValue as AnyObject?, forKey: runningProcessesKey)
    }
    
    private func processInfo(forIdentifier identifier: Int32, remove: Bool) -> ProcessInfo? {
        guard let processInfoValue = processInfoValue(forIdentifier: identifier, remove: remove) else {
            return nil
        }
        
        return type(of: self).processInfo(for: processInfoValue)
    }
    
    // MARK: Helper
    
    private func processInfoValue(forIdentifier identifier: Int32, remove: Bool) -> NSDictionary? {
        let key = type(of: self).key(from: identifier)
        if remove {
            objc_sync_enter(self)
            let processInfoValue = identifierKeyToProcessInfoValue.removeValue(forKey: key) as? NSDictionary
            objc_sync_exit(self)
            save()
            return processInfoValue
        } else {
            objc_sync_enter(self)
            let value = identifierKeyToProcessInfoValue[key] as? NSDictionary
            objc_sync_exit(self)
            return value
        }
    }
    
    private class func keyAndValue(from processInfo: ProcessInfo) -> (key: NSString, value: NSDictionary) {
        let key = self.key(from: processInfo.identifier)
        let value = self.value(for: processInfo)
        return (key: key, value: value)
    }
    
    private class func processInfo(for dictionary: NSDictionary) -> ProcessInfo? {
        guard
            let key = dictionary[ProcessInfoKey.identifier.key()] as? NSString,
            let commandPath = dictionary[ProcessInfoKey.commandPath.key()] as? String,
            let startTime = dictionary[ProcessInfoKey.startTime.key()] as? Date
        else {
            return nil
        }
        
        let identifier = self.identifier(from: key)
        
        return ProcessInfo(identifier: identifier,
            startTime: startTime,
            commandPath: commandPath)
    }
    
    private class func value(for processInfo: ProcessInfo) -> NSDictionary {
        let dictionary = NSMutableDictionary()
        let key = self.key(from: processInfo.identifier)
        dictionary[ProcessInfoKey.identifier.key()] = key
        dictionary[ProcessInfoKey.commandPath.key()] = processInfo.commandPath
        dictionary[ProcessInfoKey.startTime.key()] = processInfo.startTime
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
