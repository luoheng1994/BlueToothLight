//
//  GroupsViewController.swift
//  BlueLight
//
//  Created by Rail on 5/24/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class GroupsViewController: SelectableTableViewController, UIAlertViewDelegate {

    var groups:[Group] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buttonNames = ["重命名", "灯列表", "多组控", "删除分组"]
        buttonImages = ["icon_rename", "icon_list", "icon_multi_group", "icon_merge"]
        actions = [ #selector(GroupsViewController.rename),
                    #selector(GroupsViewController.lightList),
                    #selector(GroupsViewController.multiControl),
                    #selector(GroupsViewController.deleteGroup)]
        tableView.registerNib(UINib(nibName: "GroupCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "group cell")
        
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.backgroundColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GroupsViewController.doRefreshClients), name: NearbyClientsRefreshNotification, object: nil)
        refreshGroups()
        tableView.userInteractionEnabled = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func refreshGroups () {
        groups = GroupManager.sharedCoreDataManader.groups
        sortGroups()
        tableView.reloadData()
    }
    
    func doRefreshClients() {
        if selectMode == .None {
            refreshGroups()
        }
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
        groups.sortInPlace{ (group1, group2) -> Bool in
            return group1.onlineCount > group2.onlineCount
        }
        
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
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
        return groups.count
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
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        if selectMode == .None {
            let group = groups[indexPath.row]
            doControl([group])
        }
    }
    
    
    //MARK: - action
    
    func doControl(groups:[Group]) {
        let colorSender = ColorSendAdapter(groups: groups)
        if colorSender.devices.count == 0 {
            return
        }
        let ctl = LightControlRootController()
        ctl.colorSender = colorSender
        navigationController?.pushViewController(ctl, animated: true)
    }
    
    func lightList() {
        if selectIndexs.count > 0 {
            let group = groups[selectIndexs.first!]
            let ctl = GroupEditController()
            ctl.group = group
            navigationController?.pushViewController(ctl, animated: true)
        }
    }
    
    func multiControl() {
//        if selectIndexs.count > 0 {
//            var controlGroups:[Group] = []
//            for index in selectIndexs {
//               controlGroups.append(groups[index])
//            }
//            doControl(groups: controlGroups)
//        }
    }
    
    func deleteGroup () {
        if selectIndexs.count > 0 {
            let alert = UIAlertView(title: "提示", message: "确定删除选中分组吗？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
            alert.show()
        } 
    }
    
    //MARK: - Delete Group
    var removeGroups:[Group] = []
    func removeNext() {
        if removeGroups.count == 0 {
            Utils.instance.hideLoading()
            Utils.instance.showTip("删除成功")
            refreshGroups()
            
        }else {
            let group = removeGroups.first
            var clients = [BlueClient]()
            if let devices = group?.devices?.allObjects as? [Device] {
                var removeDirectly = true
                for device in devices {
                    if device.client != nil {
                      clients.append(device.client!)
                        removeDirectly = false
                    }
                }
                if removeDirectly {
                    removeGroups.removeFirst()
                    GroupManager.sharedCoreDataManader.removeGroup(group!)
                    removeNext()
                    return
                }
            }
            
            Utils.instance.showLoading("删除中", showBg: true)
            BlueService.instance.remove(clients, fromGroup: (group?.identify?.unsignedCharValue)!, callBack: {
                
                self.removeGroups.removeFirst()
                GroupManager.sharedCoreDataManader.removeGroup(group!)
                self.performSelector(#selector(GroupsViewController.removeNext), withObject: nil, afterDelay: 0.1)
            })
            
        }
    }
    
    
    func doDeleteSelectGroup() {
        if selectIndexs.count == 0 {
            return
        }
        removeGroups = []
        for index in selectIndexs {
            if index < groups.count {
                removeGroups.append(groups[index])
            }
        }
        removeNext()
        
    }
    
    //MARK:- Rename
    override func changeName(name: String?, index: Int?) {
        let group = groups[index!]
        group.name = name
        DeviceManager.sharedCoreDataManader.saveContext()
    }
    
    //MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            doDeleteSelectGroup()
        }
    }
}
