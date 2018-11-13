//
//  DeviceManager.swift
//  BlueLight
//
//  Created by Rail on 5/19/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import Foundation
import CoreData

class DeviceManager: CoreDataManager {
    
    override init() {
        super.init()
        entityKey = "mac"
        entityName = "Device"
        sortKey = "createDate"
    }
    
    override class var sharedCoreDataManader: DeviceManager {
        struct Static {
            static let instance: DeviceManager = DeviceManager()
        }
        
        return Static.instance
    }
    
    var devices:[Device] {
        get {
            if let results = query(predicate: nil) {
                return results as! [Device]
            }else {
                return []
            }
        }
    }
    
    var savedDevices:[Device] {
        get {
            if let results = query(predicate: nil) {
                return results as! [Device]
            }else {
                return []
            }
        }
    }
    
    func saveDevice(dic:[String : AnyObject]) -> Device{
        
        let device = NSEntityDescription.insertNewObject(forEntityName: entityName, into: CoreDataManager.managedObjectContext) as! Device
        
        device.setValuesForKeys(dic)
        device.createDate = NSDate()
        saveContext()
        return device
    }
    
    func removeDevice(device:Device){
        CoreDataManager.managedObjectContext.delete(device)
        saveContext()
    }
    
    func fetchDeviceByMacAddress(mac: String) -> Device? {
        let predicate = NSPredicate(format:"mac CONTAINS %@", mac)
        if let results = query(predicate: predicate) {
            return results.firstObject as? Device
        }
        return nil
    }
    
    func fetchDeviceByMeshAddress(meshAddr: NSNumber) -> Device? {
        let predicate = NSPredicate(format:"meshAddr = %@", meshAddr)
        if let results = query(predicate: predicate) {
            return results.firstObject as? Device
        }
        return nil
    }
    
    func fetchDeviceByUUIDString(uuid: String) -> Device? {
        let predicate = NSPredicate(format:"uuid = %@", uuid)
        if let results = query(predicate: predicate) {
            return results.firstObject as? Device
        }
        return nil
    }
    
    func fetchDeviceByMeshName(meshName: String) -> [Device] {
        let predicate = NSPredicate(format:"meshName = %@", meshName)
        if let results = query(predicate: predicate) {
            return results as! [Device]
        }
        return []
    }
}
