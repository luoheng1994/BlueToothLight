//
//  LightsViewController.swift
//  BlueLight
//
//  Created by Rail on 5/24/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

let NotificationReloadData = "reloadData"

class LightsViewController: SelectableTableViewController {

    var devices:[Device] = []
    
    var nearbyDevices:[Device] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonNames = ["重命名", "删除离线灯", "多灯控", "加入分组"]
        buttonImages = ["icon_rename", "icon_list", "icon_multi_control", "icon_addto"]
        
        actions = [ #selector(LightsViewController.rename),
                    #selector(LightsViewController.kickOut),
                    #selector(LightsViewController.multiControl),
                    #selector(LightsViewController.addToGroup)]
        
        tableView.registerNib(UINib(nibName: "DeviceCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "device cell")
        
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.backgroundColor()
        let refreshHeader = RefreshHeader(refreshingTarget: self, refreshingAction: #selector(LightsViewController.startRefresh))
        refreshHeader?.stateLabel.hidden = true
        refreshHeader?.lastUpdatedTimeLabel.hidden = true
        tableView.mj_header = refreshHeader
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LightsViewController.refreshClients(_:)), name: ListClientsAddNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LightsViewController.reloadData), name: NotificationReloadData, object: nil)
        devices = DeviceManager.sharedCoreDataManader.fetchDeviceByMeshName(AppInfo.shareInfo.userName)
        devices.sortInPlace({ (device1, device2) -> Bool in
            return device1.createDate!.compare(device2.createDate! as NSDate) == .OrderedAscending || device1.innetwork && !device2.innetwork
        })
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LightsViewController.nodeClientStatusChange), name: NodeClientStatusChangeNotification, object: nil)
        nodeClientStatusChange()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func nodeClientStatusChange() {
        if BlueService.instance.nodeClientStatus == .Connecting {
            Utils.instance.showLoading("连接中", inView: tableView)
            tableView.userInteractionEnabled = true
        }else {
            Utils.instance.hideLoading()
        }
    }
    
    var refreshTimer:NSTimer?
    func startRefresh() {
        BlueService.instance.getNetworkClient()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(LightsViewController.refreshTimeOut(_:)), userInfo: nil, repeats: false)
        
    }
    
    func refreshTimeOut(timer:NSTimer){
        tableView.mj_header.endRefreshing()
        if timer.valid {
            timer.invalidate()
        }
    }
    
    func refreshClients(notification: NSNotification) {
        tableView.mj_header.endRefreshing()
        if refreshTimer != nil && refreshTimer!.valid {
            refreshTimer?.invalidate()
        }
        if selectMode == .None {
            devices = notification.userInfo?["devices"] as! [Device]
            tableView.reloadData()
        }
    }
    
    func reloadData() {
        if selectMode == .None {
            devices.sortInPlace { (device1 , device2) -> Bool in
                return device1.innetwork && !device2.innetwork
            }
            tableView.reloadData()
        }
    }
    
    //MARK: - tableview datasouce
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier("device cell", forIndexPath: indexPath) as! DeviceCell
        let device = devices[indexPath.row]
        
        cell.indexPath = indexPath
        cell.nameField.text = device.displayName
        cell.infoLabel.text = device.displayType
        cell.detailInfoLabel.text = device.meshName
        cell.online = device.innetwork
        if device.innetwork {
            var onoff = "关"
            if device.bright > 0 {
                onoff = "开"
            }
            cell.infoLabel.text = device.displayType + "(" + onoff + ")"
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        if selectMode == .None {
            let device = devices[indexPath.row]
            if device.innetwork{
                doControl([device])
            }else {
                Utils.instance.showTip("设备不在网络中")
            }
        }
    }
    
    
    
    func doControl(devices:[Device]) {
        if devices.count == 0 {
            return
        }
        let ctl = LightControlRootController()
        
        ctl.colorSender = ColorSendAdapter(controlDevices: devices)
        navigationController?.pushViewController(ctl, animated: true)
    }
    
    //MARK: - Action
    
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
    
    func kickOut() {
        if selectIndexs.count > 0 {
            let index = selectIndexs[0]
            let device = devices[index]
            if device.innetwork || BlueService.instance.discoveredDevices.contains(device){
                Utils.instance.showTip("在线的或者附近的灯不能被删除")
            }else{
                devices.removeAtIndex(index)
                DeviceManager.sharedCoreDataManader.removeDevice(device)
                
                tableView.deselectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: false)
                tableView.reloadData()
                selectIndexs = []
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationReloadData, object: nil)
            }
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
