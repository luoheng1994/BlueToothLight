//
//  AddGroupController.swift
//  BlueLight
//
//  Created by Rail on 6/7/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class AddGroupController: UITableViewController, UIAlertViewDelegate {

    var devices:[Device]!
    
    var groups:[Group] = []
    
    var selectGroup:Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "加入分组"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(AddGroupController.addGroup))
        
        tableView.registerNib(UINib(nibName: "GroupCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "group cell")
        tableView.backgroundColor = UIColor.backgroundColor()
        tableView.separatorStyle = .None
        groups = GroupManager.sharedCoreDataManader.groups
        sortGroups()
    }

    func sortGroups() {
        for group in groups {
            group.onlineCount = 0
            for device in group.devices! {
                let dev = device as! Device
                if dev.innetwork {
                    group.onlineCount += 1
                }
            }
        }
        groups.sortInPlace { (group1, group2) -> Bool in
            return group1.onlineCount > group2.onlineCount
        }
        
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return groups.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("group cell", forIndexPath: indexPath) as! GroupCell
        
        let group = groups[indexPath.row]
        cell.nameField.text = group.displayName
        cell.infoLabel.text = "\(group.onlineCount)/\(group.devices?.count ?? 0)在线"
        cell.onlineColor = UIColor.colorWithHex(0xe84e6b)
        cell.online = group.onlineCount > 0
        
        return cell

    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectGroup = groups[indexPath.row]
        let alert = UIAlertView(title: "提示", message: "确认加入分组\"\(selectGroup!.displayName!)\"吗？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
        alert.show()
    }
    
    var confirmView = UIView()
    var alertview = UIView()
    let textField = UITextField()
    
    // MARK:- Action
    func addGroup() {
        let groups = GroupManager.sharedCoreDataManader.groups
        if groups.count >= 8 {
            Utils.instance.showTip("最多只能创建八个分组")
            return
        }
        
        
        let keyView = UIApplication.sharedApplication().keyWindow?.rootViewController?.view
        
        let width = 250
        let height = 180
        
        confirmView = UIView()
        confirmView.alpha = 0
        confirmView.frame = (keyView?.frame)!
        confirmView.backgroundColor = UIColor.blackColor()
        confirmView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AddGroupController.hideConfirm)))
        keyView?.addSubview(confirmView)
        
        alertview = UIView()
        alertview.frame = CGRect(x: 0, y: 0, width: width, height: height)
        alertview.backgroundColor = UIColor.whiteColor()
        alertview.layer.cornerRadius = 10
        alertview.layer.shadowColor = UIColor.blackColor().CGColor
        alertview.layer.shadowRadius = 5
        alertview.layer.shadowOpacity = 0.5
        alertview.layer.shadowOffset = CGSize.zero
        
        alertview.center = view.center
        alertview.frame.origin.y = alertview.frame.origin.y - 150
        alertview.transform = CGAffineTransformMakeScale(1.2, 1.2)
        alertview.alpha = 0
        alertview.clipsToBounds = false
        keyView?.addSubview(alertview)
        
        let titleLabel = UILabel()
        titleLabel.text = "创建组"
        titleLabel.textAlignment = .Center
        titleLabel.frame = CGRect(x: 0, y: 0, width: width, height: 48)
        alertview.addSubview(titleLabel)
        
        let seprateView = UIView()
        seprateView.backgroundColor = UIColor.colorWithHex(0xdfe8ee)
        seprateView.frame = CGRect(x: 0, y: 48, width: width, height: 2)
        alertview.addSubview(seprateView)
        
        textField.frame = CGRect(x: 25, y: 75, width: width - 50, height: 30)
        textField.borderStyle = .RoundedRect
        textField.placeholder = "请输入组名"
        alertview.addSubview(textField)
        
        let cancelBtn = UIButton(type: .System)
        cancelBtn.backgroundColor = UIColor.colorWithHex(0xbababa)
        cancelBtn.setTitle("取消", forState: [])
        cancelBtn.setTitleColor(UIColor.whiteColor(), forState: [])
        cancelBtn.frame = CGRect(x: width / 9, y: height - 50, width: width / 3, height: 30)
        cancelBtn.addTarget(self, action: #selector(AddGroupController.hideConfirm), forControlEvents: .TouchUpInside)
        cancelBtn.layer.cornerRadius = 8
        alertview.addSubview(cancelBtn)
        
        let okBtn = UIButton(type: .System)
        okBtn.backgroundColor = UIColor.themeColor()
        okBtn.setTitle("保存", forState: [])
        okBtn.setTitleColor(UIColor.whiteColor(), forState: [])
        okBtn.frame = CGRect(x: width / 9 * 5, y: height - 50, width: width / 3, height: 30)
        okBtn.addTarget(self, action: #selector(AddGroupController.doAdd), forControlEvents: .TouchUpInside)
        okBtn.layer.cornerRadius = 8
        alertview.addSubview(okBtn)
        
        UIView.animateWithDuration(0.3) { () -> Void in
            self.alertview.alpha = 1
            self.confirmView.alpha = 0.4
            self.alertview.transform = CGAffineTransformMakeScale(1.0, 1.0)
            
        }
    }
    
    func hideConfirm() {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.confirmView.alpha = 0
            self.alertview.alpha = 0
        }) { (finished) -> Void in
            if finished {
                self.confirmView.removeFromSuperview()
                self.alertview.removeFromSuperview()
            }
        }
    }
    
    func doAdd() {
        let name = textField.text
        if name?.characters.count > 0{
            
            var ids = [UInt8]()
            for group in GroupManager.sharedCoreDataManader.groups {
                ids .append((group.identify?.unsignedCharValue)!)
            }
            var id:UInt8 = 0
            for index in 0 ... 255 {
                if !ids.contains(UInt8(index)) {
                    id = UInt8(index)
                    break
                }
            }
            
            
            let _ = GroupManager.sharedCoreDataManader.saveGroup(["name": name!, "identify": NSNumber(unsignedShort:UInt16(0x8000 + UInt16(id)))])
//            group.devices = NSSet(array: devices)
//            GroupManager.sharedCoreDataManader.saveContext()
            
            var clients = [BlueClient]()
            for device in devices {
                clients.append(device.client!)
            }
            Utils.instance.showLoading("保存中", showBg: true)
            BlueService.instance.add(clients, toGroup: id, callBack: {
                Utils.instance.hideLoading()
                Utils.instance.showTip("保存成功")
                BlueService.instance.getGroup()
                self.navigationController?.popViewControllerAnimated(true)
            })
            
            
            hideConfirm()
            
        }
    }
    
    //MARK: -UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            var clients = [BlueClient]()
            for device in devices {
                clients.append(device.client!)
            }
            Utils.instance.showLoading("保存中", showBg: true)
            BlueService.instance.add(clients, toGroup: (selectGroup?.identify?.unsignedCharValue)!, callBack: {
                Utils.instance.hideLoading()
                Utils.instance.showTip("保存成功")
                self.navigationController?.popViewControllerAnimated(true)
            })
            
//            selectGroup?.devices = selectGroup?.devices?.setByAddingObjectsFromArray(devices)
//            GroupManager.sharedCoreDataManader.saveContext()
            Utils.instance.showTip("保存成功")
            BlueService.instance.getGroup()
            navigationController?.popViewControllerAnimated(true)
            
        }

    }
    
    override func navigationShouldPopOnBackButton() -> Bool {
        BlueService.instance.getGroup()
        return true
    }
}
