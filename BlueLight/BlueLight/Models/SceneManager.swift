//
//  SceneManager.swift
//  BlueLight
//
//  Created by Rail on 7/7/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import Foundation
import CoreData

class SceneManager: CoreDataManager {
    override init() {
        super.init()
        entityKey = "createDate"
        entityName = "Scene"
        sortKey = "createDate"
    }
    
    override class var sharedCoreDataManader: SceneManager {
        struct Static {
            static let instance: SceneManager = SceneManager()
        }
        
        return Static.instance
    }
    
    var scenes:[Scene] {
        get {
            if let results = query(predicate: nil) {
                return results as! [Scene]
            }else {
                return []
            }
        }
    }
    
    func getScenesByType(lightType:Int) -> [Scene]{
        let predicate = NSPredicate(format:"type = %@", NSNumber(value: lightType))
        if let results = query(predicate: predicate) {
            return results as! [Scene]
        }
        return []
    }
    
    func saveScene(dic:[String : AnyObject]) -> Scene{
        let scene = NSEntityDescription.insertNewObject(forEntityName: entityName, into: CoreDataManager.managedObjectContext) as! Scene
        
        scene.setValuesForKeys(dic)
        scene.createDate = NSDate()
        saveContext()
        return scene
    }
    
    func removeScene(scene:Scene){
        CoreDataManager.managedObjectContext.delete(scene)
        saveContext()
    }
}
