//
//  OTAListController.swift
//  BlueLight
//
//  Created by Rail on 7/19/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class OTAListController: UITableViewController {

    var devices:[Device] = []
    
    let otaService = OTAService()
    var otaing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        devices = DeviceManager.sharedCoreDataManader.fetchDeviceByMeshName(AppInfo.shareInfo.userName)
        devices.sortInPlace({ (device1, device2) -> Bool in
            return device1.createDate!.compare(device2.createDate! as NSDate) == .OrderedAscending || device1.online && !device2.online
        })
        title = "固件升级"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OTAListController.reloadData), name: NotificationReloadData, object: nil)
        
        
        devices = DeviceManager.sharedCoreDataManader.fetchDeviceByMeshName(AppInfo.shareInfo.userName)
        devices.sortInPlace({ (device1, device2) -> Bool in
            return device1.createDate!.compare(device2.createDate! as NSDate) == .OrderedAscending || device1.innetwork && !device2.innetwork
        })
        tableView.reloadData()
        otaService.refreshVersion()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        BlueService.instance.stopScan()
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        BlueService.instance.startScan()
    }
    
    func reloadData() {
        if !otaing {
            tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return devices.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "value1 cell")
        let device = devices[indexPath.row]
        cell.detailTextLabel?.font = UIFont.systemFontOfSize(15)
        cell.textLabel?.text = device.displayName
        cell.accessoryType = .None
        cell.selectionStyle = .None
        
        let detailLabel = UILabel()
        detailLabel.frame = CGRect(x: 20, y: 50, width: 300, height: 20)
        detailLabel.textColor = UIColor.colorWithHex(0x666666)
        detailLabel.text = device.client?.softwareVersion != nil ? "设备版本：\((device.client?.softwareVersion)!)" : ""
        detailLabel.font = UIFont.systemFontOfSize(14)
        detailLabel.tag = 1
        cell.contentView.addSubview(detailLabel)
        
        
        if BlueService.instance.discoveredDevices.contains(device)  {
            
            if device.client?.hardwareVersion == nil {
                cell.detailTextLabel?.text = "未知版本"
            }else {
                if otaService.needOta(device.client) {
                    cell.detailTextLabel?.text = "可升级"
                    cell.accessoryType = .DisclosureIndicator
                    cell.detailTextLabel?.textColor = UIColor.bewitchedTree()
                }else {
                    cell.detailTextLabel?.text = "已经最新"
                }
            }
        }else {
            cell.detailTextLabel?.text = "设备不在附近"
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let device = devices[indexPath.row]
        if BlueService.instance.discoveredDevices.contains(device)  {
            if device.client?.hardwareVersion != nil {
                if otaService.needOta(device.client) {
                    confirmStartOTA(device)
                }
            }
        }
    }
    
    
    func confirmStartOTA(device:Device) {
        let alert = UIAlertController(title: "开始更新", message: "确定更新设备\"\(device.displayName)\"?\n开始更新后请不要断开蓝牙连接.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "确定", style: .Default, handler: { (action) in
            self.startOta(device)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func navigationShouldPopOnBackButton() -> Bool {
        if otaing {
            let alert = UIAlertController(title: "设备升级中", message: "正在更新设备\"\(otaDevice?.displayName!)\"!\n退出更新将导致升级失败，确定退出？", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "确定", style: .Default, handler: { (action) in
                self.navigationController?.popViewControllerAnimated(true)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    //MARK: - 开始OTA
    var otaDevice:Device? = nil
    var otaCell:UITableViewCell? = nil
    let otaProgress = UIProgressView()
    
    func startOta(device:Device) {
        otaDevice = device
        otaing = true
        
        let index = devices.indexOf(device)
        let indexPath = NSIndexPath(forRow: index!, inSection: 0)
        otaCell = tableView.cellForRowAtIndexPath(indexPath)
        let otaLabel = otaCell?.viewWithTag(1) as? UILabel
        otaLabel?.text = "设备连接中"
        otaProgress.frame = CGRect(x: 20, y: 78, width: view.frame.width - 40, height: 2)
        otaCell?.addSubview(otaProgress)
        otaProgress.progress = 0
        tableView.userInteractionEnabled = false
        otaService.otaClient(device.client!, progressBlock: { (progress) in
            self.tableView.userInteractionEnabled = true
            self.otaProgress.progress = Float(progress)
            if progress == 1 {
                self.otaCell?.detailTextLabel?.text = "升级完成"
                self.otaCell?.detailTextLabel?.textColor = UIColor.bewitchedTree()
                self.otaing = false
            }else {
                otaLabel?.text = String(format: "%.f%%", progress * 100)
                self.otaCell?.detailTextLabel?.text = "升级中"
            }
            
            }) {
                self.tableView.userInteractionEnabled = true
                self.otaCell?.detailTextLabel?.text = "升级失败"
                self.otaCell?.detailTextLabel?.textColor = UIColor.merryCranesbill()
                self.otaing = false
                
        }
//        otaService.otaClient(device.client!)
    }
    

}
