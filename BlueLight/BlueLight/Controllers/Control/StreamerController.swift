//
//  StreamerController.swift
//  BlueLight
//
//  Created by Rail on 7/13/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class StreamerController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    
    let bottomView = UIView()
    let startBtn = UIButton(type: .System)
    
    var collectionView:UICollectionView!
    var sender:ColorSendAdapter!
    
    var scenes:[Scene] = []
    
    var editMode:SceneEditMode = .picker
    let speedSlider = UISlider()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "流光设置"
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Vertical
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: 100, height: 100)

        collectionView = UICollectionView(frame:CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 150), collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.registerClass(SceneCell.self, forCellWithReuseIdentifier: "SceneCell")
        collectionView.allowsMultipleSelection = true
        view.addSubview(collectionView)
        
        
        bottomView.frame = CGRect(x: 0, y: view.frame.height - 150, width: view.frame.width, height: 150)
        bottomView.backgroundColor = UIColor.colorWithHex(0xc3caf0)
        bottomView.layer.shadowColor = UIColor.blackColor().CGColor
        bottomView.layer.shadowOffset = CGSize(width: 0, height: -5)
        bottomView.layer.shadowRadius = 8
        bottomView.layer.shadowOpacity = 0.1
        view.addSubview(bottomView)
        
        startBtn.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        startBtn.center = CGPoint(x: view.frame.width / 2, y: 100)
        startBtn.setTitle("流光溢彩", forState: .Normal)
        startBtn.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        startBtn.layer.cornerRadius = 16
        startBtn.layer.borderColor = UIColor.whiteColor().CGColor
        startBtn.layer.borderWidth = 1
        startBtn.addTarget(self, action: #selector(StreamerController.startStreamer), forControlEvents: .TouchUpInside)
        bottomView.addSubview(startBtn)
        
        
        speedSlider.frame = CGRect(x: 5, y: 30, width: view.frame.width - 10, height: 20)
        speedSlider.minimumValueImage = UIImage(named: "icon_snail")
        speedSlider.maximumValueImage = UIImage(named: "icon_rabbit")
        speedSlider.setMinimumTrackImage(UIImage(named: "progress_mini"), forState: .Normal)
        speedSlider.setMaximumTrackImage(UIImage(named: "progress_maxi"), forState: .Normal)
        speedSlider.value = 0.5
        bottomView.addSubview(speedSlider)
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "清空", style: .Plain, target: self, action: #selector(StreamerController.clearSelect))
    }
    
    override func viewDidAppear(animated: Bool) {
        
        scenes = SceneManager.sharedCoreDataManader.getScenesByType(sender.lightType.rawValue)
        collectionView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        scenes = []
        collectionView.reloadData()
    }
    
    func startStreamer() {
        if selectIndexs.count == 0 {
            Utils.instance.showTip("请选择至少两个场景")
            return
        }
        var scenesList:[Scene] = []
        for indexPath in selectIndexs {
            let scene = scenes[indexPath.row]
            scenesList.append(scene)
        }
        let speed = UInt16(speedSlider.value * 100)
        let sceneSet = NSOrderedSet(array: scenesList)
        let streamer = StreamerManager.sharedCoreDataManader.saveStreamer(["type":NSNumber(integer:sender.lightType.rawValue),
            "scenes": sceneSet, "speed": NSNumber(unsignedShort: speed)])
        NSNotificationCenter.defaultCenter().postNotificationName("NotificationStreamerPicked", object: self, userInfo: ["streamer": streamer])
        navigationController?.popViewControllerAnimated(true)
    }
    
    func clearSelect() {
        selectIndexs = []
        collectionView.reloadData()
    }
    var selectIndexs:[NSIndexPath] = []

    //MARK: -Collection View Delegate
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return scenes.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SceneCell", forIndexPath: indexPath) as! SceneCell
        let scene = scenes[indexPath.row]
        cell.displayImage = scene.displayImage
        cell.nameLabel.text = scene.name
        cell.hideIndex()
        cell.selectMode = .picker
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if selectIndexs.count >= 5 {
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
            return
        }
        if !selectIndexs.contains(indexPath) {
            selectIndexs.append(indexPath)
        }
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SceneCell
        cell.showIndex(selectIndexs.count)
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if selectIndexs.contains(indexPath) {
            let index = selectIndexs.indexOf(indexPath)
            selectIndexs.removeAtIndex(index!)
        }
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SceneCell
        cell.hideIndex()
        
        for (index, path) in selectIndexs.enumerate() {
            let cell = collectionView.cellForItemAtIndexPath(path) as! SceneCell
            cell.showIndex(index + 1)
        }
    }

}
