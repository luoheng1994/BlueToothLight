//
//  NearbyViewController.swift
//  BlueLight
//
//  Created by Rail on 5/24/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class NearbyViewController: SelectableTableViewController {
    
    var devices:[Device] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonNames = ["重命名", "加入网络", "多灯控", "加入分组"]
        buttonImages = ["icon_rename", "icon_list", "icon_multi_control", "icon_addto"]
        actions = [ #selector(NearbyViewController.rename),
                    #selector(NearbyViewController.addToNetwork),
                    #selector(NearbyViewController.multiControl),
                    #selector(NearbyViewController.addToGroup)]
        
        
        tableView.register(UINib(nibName: "DeviceCell", bundle: Bundle.main), forCellReuseIdentifier: "nearby cell")
        BlueService.instance.startScan()
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.backgroundColor()
        let refreshHeader = RefreshHeader(refreshingTarget: self, refreshingAction: #selector(NearbyViewController.startRefresh))
        refreshHeader?.stateLabel.isHidden = true
        refreshHeader?.lastUpdatedTimeLabel.isHidden = true
        tableView.mj_header = refreshHeader
        
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated: animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NearbyViewController.refreshClients(_:)), name: NearbyClientsRefreshNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NearbyViewController.reloadData), name: NotificationReloadData, object: nil)
       
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    

    func refreshClients(notification: NSNotification) {
        tableView.mj_header.endRefreshing()
        if selectMode == .None {
            devices = notification.userInfo?["devices"] as! [Device]
            tableView.reloadData()
        }
        
    }
    
    func reloadData() {
        if selectMode == .None {
            tableView.reloadData()
        }
    }
    
    func startRefresh() {
        BlueService.instance.startScan()
    }
    
    
    //MARK: - tableview datasouce
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UITableViewHeaderFooterView(reuseIdentifier: "footer")
        footer.contentView.backgroundColor = UIColor.backgroundColor()
        return footer
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("nearby cell", forIndexPath: indexPath) as! DeviceCell
        let device = devices[indexPath.row]
        
        cell.indexPath = indexPath
        cell.nameField.text = device.displayName
        cell.infoLabel.text = device.displayType
        cell.detailInfoLabel.text = device.meshName
        cell.online = true
        cell.multiSelectEnable = device.meshName == AppInfo.shareInfo.userName
        return cell
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        if selectMode == .None {
            let device = devices[indexPath.row]
            if device.meshName != AppInfo.shareInfo.userName {
                Utils.instance.showTip("\"\(device.displayName!)\"不属于当前网络")
                return
            }
            doControl([device])
        }
    }
    
    //MARK: - Action
    
    func doControl(devices:[Device]) {
        if devices.count == 0 {
            return
        }
        let ctl = LightControlRootController()
        
        ctl.colorSender = ColorSendAdapter(controlDevices: devices)
        navigationController?.pushViewController(ctl, animated: true)
    }
    
    func addToNetwork() {
        if selectIndexs.count > 0 {
            let device = devices[selectIndexs[0]]
            if device.meshName == AppInfo.shareInfo.userName && BlueService.instance.listDevices.contains(device) {
                Utils.instance.showTip("该灯已经被加入当前网络中")
                return
            }
            
            let alert = UIAlertController(title:"请输入密码", message:"请输入\"\(device.meshName!)\"的登陆密码", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "确定", style: .Destructive, handler: { (action) in
                let pwdField = alert.textFields?.first
                let pwd = pwdField?.text
                if pwd?.characters.count > 0 {
                    Utils.instance.showLoading("设置中", showBg: true)
                    BlueService.instance.setNetwork(pwd!, clients: [device.client!], block: { (success) in
                        Utils.instance.hideLoading()
                        
                        if success {
                            Utils.instance.showTip("加入网络成功")
                        }else {
                            Utils.instance.showTip("加入网络失败")
                        }
                        self.tableView.reloadData()
                    })
                }
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            alert.addTextFieldWithConfigurationHandler{ (field) in
                field.placeholder = "登陆密码"
            }
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func addToGroup() {
        if selectIndexs.count > 0 {
            let ctl = AddGroupController(style: .Plain)
            var addDevices:[Device] = []
            for index in selectIndexs {
                addDevices.append(devices[index])
            }
            ctl.devices = addDevices
            
            navigationController?.pushViewController(ctl, animated: true)
        }
    }
    
    func multiControl() {
        if selectIndexs.count > 0 {
            if selectIndexs.count > 5 {
                Utils.instance.showTip("多控最多支持5盏灯")
                return
            }
            var controlDevices:[Device] = []
            for index in selectIndexs {
                controlDevices.append(devices[index])
            }
            doControl(controlDevices)
        }
    }
    
    
    //MARK:- Rename
    
    override func changeName(name: String?, index: Int?) {
        let device = devices[index!]
        device.name = name
        DeviceManager.sharedCoreDataManader.saveContext()
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationReloadData, object: nil)
    }
    
    

}
