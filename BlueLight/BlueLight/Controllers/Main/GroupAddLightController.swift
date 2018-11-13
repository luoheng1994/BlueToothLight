//
//  GroupAddLightController.swift
//  BlueLight
//
//  Created by Rail on 6/17/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class GroupAddLightController: UITableViewController {

    
    var group:Group!
    
    var devices:[Device] = []
    var selectMap:[Device:Bool] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "选择灯"
        tableView.allowsMultipleSelection = true
        
        let savedDevices = DeviceManager.sharedCoreDataManader.savedDevices
        for device in savedDevices {
            if !group.devices!.containsObject(device) {
                devices.append(device)
                selectMap[device] = false
            }
        }
    }
    
    override func navigationShouldPopOnBackButton() -> Bool {
        
        var clients:[BlueClient] = []
        for (device,select) in selectMap {
            if select {
                if let client = device.client {
                    clients.append(client)
                }
            }
        }
        
        Utils.instance.showLoading("添加中", showBg: true)
        BlueService.instance.add(clients, toGroup: (group.identify?.unsignedCharValue)!) {
            Utils.instance.hideLoading()
            Utils.instance.showTip("添加成功")
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        
        
        return false
    }

    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UITableViewHeaderFooterView()
        let backView = UIView()
        backView.backgroundColor = UIColor.colorWithHex(0xadc1cb)
        backView.frame = CGRect(x: 20, y: 0, width: tableView.frame.width, height: 0.5)
        footer.contentView.addSubview(backView)
        return footer
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value2, reuseIdentifier: "Value2 cell")
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.displayName
        cell.textLabel?.textAlignment = .Left
        cell.textLabel?.textColor = UIColor.blackColor()
        cell.detailTextLabel?.text = device.displayType
        cell.detailTextLabel?.font = UIFont.systemFontOfSize(14)
        cell.detailTextLabel?.textColor = UIColor.grayColor()
        cell.backgroundColor = UIColor.clearColor()
        cell.selectionStyle = .None
        cell.accessoryType = selectMap[device]! ? .Checkmark : .None
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = .Checkmark
        
        let device = devices[indexPath.row]
        selectMap[device] = true
    }
    
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = .None
        
        let device = devices[indexPath.row]
        selectMap[device] = false
    }
    
}
