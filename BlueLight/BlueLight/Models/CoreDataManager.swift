//
//  CoreDataManager.swift
//  BlueLight
//
//  Created by Rail on 5/19/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {
    
    static let managedObjectModelFileName = "Model"
    
    static var managedObjectContext: NSManagedObjectContext = {
        
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.performAndWait({
            let undoManager = UndoManager()
            undoManager.groupsByEvent = false
            context.undoManager = undoManager
            context.persistentStoreCoordinator = sharedCoreDataManader.persistentStoreCoordinator
        })
        return context
    }()
    
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        let modelURL = Bundle.main.url(forResource: managedObjectModelFileName, withExtension: "momd")
        return NSManagedObjectModel(contentsOf: modelURL!)!
    }()
    
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: sharedCoreDataManader.managedObjectModel)
        
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let storeURL = docURL?.URLByAppendingPathComponent("\(managedObjectModelFileName).sqlite")
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        }catch {
            NSLog("Unresolved error \(error)");
        }
        return coordinator
    }()
    
    
    class var sharedCoreDataManader: CoreDataManager {
        struct Static {
            static let instance: CoreDataManager = CoreDataManager()
        }
        return Static.instance
    }
    
    
    func saveContext() {
        
        if CoreDataManager.managedObjectContext.hasChanges {
            do {
                try CoreDataManager.managedObjectContext.save()
            }catch{
                NSLog("Unresolved error \(error)")
            }
        }
    }
    
    var entityName = ""
    
    var entityKey = ""
    
    var sortKey = ""
    
    func query(predicate: NSPredicate?) -> NSArray?{
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: entityName, in: CoreDataManager.managedObjectContext)
        
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: true)]
        
        do {
            return try CoreDataManager.managedObjectContext.executeFetchRequest(request)
        }catch {
            NSLog("Unresolved error \(error)");
            return nil
        }
        
    }
    
    
    //MARK: - Undo/Redo Operations
    
    func undo() {
        CoreDataManager.managedObjectContext.undo()
    }
    
    func redo() {
        CoreDataManager.managedObjectContext.redo()
    }
    
    func rollback() {
        CoreDataManager.managedObjectContext.rollback()
    }
    
    func reset() {
        CoreDataManager.managedObjectContext.reset()
    }
    
}
