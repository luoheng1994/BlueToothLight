//
//  SettingController.swift
//  BlueLight
//
//  Created by Rail on 6/30/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class SettingController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "返回", style: .Plain, target: nil, action: nil)
        title = "设置"
        tableView.backgroundColor = UIColor.backgroundColor()
        tableView.separatorColor = UIColor.colorWithHex(0xdfe8ee)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        
    }

    override func viewWillAppear(animated: Bool) {
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        let infoLabel = UILabel()
        infoLabel.font = UIFont.systemFontOfSize(15)
        infoLabel.textColor = UIColor.colorWithHex(0x95a9b7)
        infoLabel.frame = CGRect(x: 38, y: 20, width: 100, height: 22)
        header.contentView.addSubview(infoLabel)
        if section == 0 {
            infoLabel.text = "信息"
        }else if section == 1 {
            infoLabel.text = "设备"
        }
        return header
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "value1 cell")
        cell.imageView?.image = UIImage(named: "icon_online")
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "网络名"
                cell.detailTextLabel?.text = AppInfo.shareInfo.userName
                cell.accessoryType = .DisclosureIndicator
            }
        }else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "硬件更新"
                cell.detailTextLabel?.text = AppInfo.CurrentVersion
                cell.accessoryType = .DisclosureIndicator
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let netwoktCtl = NetworkInfoController(style: .Grouped)
                navigationController?.pushViewController(netwoktCtl, animated: true)
            }
        }else if indexPath.section == 1{
            if indexPath.row == 0 {
                let otaListCtl = OTAListController()
                navigationController?.pushViewController(otaListCtl, animated: true)
            }
        }

    }
    
    

}
