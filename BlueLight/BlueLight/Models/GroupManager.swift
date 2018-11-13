//
//  GroupManager.swift
//  BlueLight
//
//  Created by Rail on 6/6/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import Foundation
import CoreData

class GroupManager: CoreDataManager {
    override init() {
        super.init()
        entityKey = "identify"
        entityName = "Group"
        sortKey = "createDate"
    }
    
    override class var sharedCoreDataManader: GroupManager {
        struct Static {
            static let instance: GroupManager = GroupManager()
        }
        return Static.instance
        
    }
    
    var groups:[Group] {
        get {
            if let results = query(predicate: nil) {
                return results as! [Group]
            }else {
                return []
            }
        }
    }
    
    func saveGroup(dic:[String : AnyObject]) -> Group{
        
        let group = NSEntityDescription.insertNewObject(forEntityName: entityName, into: CoreDataManager.managedObjectContext) as! Group
        
        group.setValuesForKeys(dic)
        group.createDate = NSDate()
        saveContext()
        return group
    }
    
    func removeGroup(group:Group){
        CoreDataManager.managedObjectContext.delete(group)
        saveContext()
    }
    
    func fetchGroupByIdentify(identify: NSNumber) -> Group? {
        let predicate = NSPredicate(format:"identify = %@", identify)
        if let results = query(predicate: predicate) {
            return results.firstObject as? Group
        }
        return nil
    }
    
    
}
