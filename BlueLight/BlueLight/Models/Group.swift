//
//  Group.swift
//  BlueLight
//
//  Created by Rail on 6/6/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import Foundation
import CoreData

@objc(Group)
class Group: NSManagedObject {


    var onlineCount = 0

    var displayName:String! {
        get {
            if name == nil {
                return String(format: "组%04x", (identify?.uint16Value)!)
            }else {
                return name
            }
        }
    }
    
}

extension Group {
    
    @NSManaged var identify:NSNumber?
    @NSManaged var name: String?
    @NSManaged var createDate: NSDate?
    @NSManaged var devices: NSSet?
    
}
