//
//  Scene+CoreDataProperties.swift
//  BlueLight
//
//  Created by Rail on 7/14/16.
//  Copyright © 2016 Rail. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Scene {

    @NSManaged var color: NSNumber?
    @NSManaged var createDate: NSDate?
    @NSManaged var type: NSNumber?
    @NSManaged var name: String?
    @NSManaged var streamers: NSSet?

}
