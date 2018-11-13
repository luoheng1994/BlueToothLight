//
//  StreamerManager.swift
//  BlueLight
//
//  Created by Rail on 7/7/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import Foundation
import CoreData

class StreamerManager: CoreDataManager {
    override init() {
        super.init()
        entityKey = "createDate"
        entityName = "Streamer"
        sortKey = "createDate"
    }
    
    var streamers:[Streamer] {
        get {
            if let results = query(predicate: nil) {
                return results as! [Streamer]
            }else {
                return []
            }
        }
    }
    
    override class var sharedCoreDataManader: StreamerManager {
        struct Static {
            static let instance: StreamerManager = StreamerManager()
        }
        
        return Static.instance
    }
    
    func saveStreamer(dic:[String : AnyObject]) -> Streamer{
        
        let streamer = NSEntityDescription.insertNewObject(forEntityName: entityName, into: CoreDataManager.managedObjectContext) as! Streamer
        
        streamer.setValuesForKeys(dic)
        streamer.createDate = NSDate()
        saveContext()
        return streamer
    }
    
    func removeStreamer(streamer:Streamer){
        CoreDataManager.managedObjectContext.delete(streamer)
        saveContext()
    }
}
