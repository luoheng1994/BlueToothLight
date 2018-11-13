//
//  SceneController.swift
//  BlueLight
//
//  Created by Rail on 7/7/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

enum SceneSelectMode: Int {
    case color
    case streamer
}

let NotificationScenePicked = "NotificationScenePicked"
let NotificationStreamerPicked = "NotificationStreamerPicked"

class SceneController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var collectionView:UICollectionView!
    
    var items:[AnyObject] = []
    var selectMode:SceneEditMode = .none {
        didSet {
            var image = UIImage(named: "icon_trash")
            if selectMode == .delete {
                image = UIImage(named: "icon_trash_open")
                collectionView.allowsSelection = false
            }else {
                collectionView.allowsSelection = true
            }
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .Plain, target: self, action: #selector(SceneController.startDelete))
            collectionView.reloadData()
        }
    }
    
    var sceneMode:SceneSelectMode = .color
    var lightType:BlueLightType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "场景"
        
        let segment = UISegmentedControl(items: ["纯色", "流光"])
        segment.addTarget(self, action: #selector(SceneController.segmentChange(_:)), forControlEvents: .ValueChanged)
        segment.frame = CGRect(x: 0, y: 0, width: 150 , height: 40)
        segment.selectedSegmentIndex = 0
        segment.tintColor = UIColor.colorWithHex(0xbcc8d2)
        segment.center = CGPoint(x: view.frame.midX, y: 110)
        
        view.addSubview(segment)
        
        view.backgroundColor = UIColor.whiteColor()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Vertical
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: 100, height: 100)
        collectionView = UICollectionView(frame:CGRect(x: 0, y: 150, width: view.frame.width, height: view.frame.height - 150), collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.registerClass(SceneCell.self, forCellWithReuseIdentifier: "SceneCell")
        view.addSubview(collectionView)
        selectMode = .none
        
    }
    override func viewDidAppear(animated: Bool) {
        items = SceneManager.sharedCoreDataManader.getScenesByType(lightType.rawValue)
        collectionView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        items = []
        collectionView.reloadData()
    }
    
    func startDelete() {
        if selectMode == .none {
            selectMode = .delete
        }else {
            selectMode = .none
        }
    }

    func segmentChange(segment:UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            items = SceneManager.sharedCoreDataManader.getScenesByType(lightType.rawValue)
            sceneMode = .color
        }else {
            items = StreamerManager.sharedCoreDataManader.streamers
            sceneMode = .streamer
        }
        collectionView.reloadData()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SceneCell", forIndexPath: indexPath) as! SceneCell
        let item = items[indexPath.row]
        cell.setSelectMode(selectMode, animate: true)
        if let scene = item as? Scene {
            cell.displayImage = scene.displayImage
            cell.nameLabel.text = scene.name
        }else if let streamer = item as? Streamer {
            cell.displayImage = streamer.displayImage
            cell.nameLabel.text = streamer.name
        }
        
        cell.deleteBlock = {view in
            let index = (collectionView.indexPathForCell(view)?.row)!
            let item = self.items[index]
            self.items.removeAtIndex(index)
            if let scene = item as? Scene {
                SceneManager.sharedCoreDataManader.removeScene(scene)
            }else if let streamer = item as? Streamer {
                StreamerManager.sharedCoreDataManader.removeStreamer(streamer)
            }
            collectionView.deleteItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
            
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if selectMode == .none {
            
            
            if sceneMode == .color {
                let scene = items[indexPath.row] as! Scene
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationScenePicked, object: self, userInfo: ["scene": scene])
                navigationController?.popViewControllerAnimated(true)
            }else if sceneMode == .streamer {
                let streamer = items[indexPath.row] as! Streamer
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationStreamerPicked, object: self, userInfo: ["streamer": streamer])
                navigationController?.popViewControllerAnimated(true)
            }
        }
        
    }
    

}
