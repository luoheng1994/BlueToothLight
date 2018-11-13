//
//  Device.swift
//  BlueLight
//
//  Created by Rail on 5/19/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import Foundation
import CoreData

@objc(Device)
class Device: NSManagedObject {
    
    var online = false
    var innetwork = false
    var bright:UInt8 = 0
    
    var client:BlueClient? {
        didSet {
            mac = client?.macAddress
            uuid = client?.uuidString
        }
    }
    
    var displayType:String! {
        get {
            switch type!.intValue {
            case 6:
                return localize(key: "冷暖色")
            case 4, 3:
                return localize(key: "彩色")
            default:
                return localize(key: "未知设备")
            }
        }
    }
    
    var displayName:String! {
        get {
            if name != nil {
                return name
            }else {
                if (mac?.characters.count)! > 0 {
                    
                    let mac_end = mac?.substringFromIndex(mac!.endIndex.advancedBy(-4)).uppercaseString
                    switch type!.intValue {
                    case 6:
                        return "YW_\(mac_end!)"
                    case 4:
                        return "RGB_\(mac_end!)"
                    case 3:
                        return "RGBW_\(mac_end!)"
                    default:
                        return "Unknown_\(mac_end!)"
                    }
                }else {
                    return "Unknown"
                }
                
            }
        }
    }
    
}

extension Device {
    @NSManaged var mac: String?
    @NSManaged var name: String?
    @NSManaged var uuid: String?
    @NSManaged var type: NSNumber?
    @NSManaged var createDate: NSDate?
    @NSManaged var meshAddr: NSNumber?
    @NSManaged var meshName: String?
    @NSManaged var meshPwd: String?
    
    @NSManaged var groups: NSSet?
    
}
