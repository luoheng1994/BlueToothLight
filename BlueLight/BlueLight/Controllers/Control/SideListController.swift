//
//  SideListController.swift
//  BlueLight
//
//  Created by Rail on 6/15/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

let keyNotifStateShange = "client state change"

class SideListController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var devices:[Device] = []
    let tableView = UITableView(frame: CGRect.zero, style: .Grouped)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let width = view.bounds.width
        let bgImageView = UIImageView()
        bgImageView.frame = view.bounds
        bgImageView.image = UIImage(named: "bg_side_menu")
        view.addSubview(bgImageView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorColor = UIColor.whiteColor()
        tableView.frame = CGRect(x: width * 0.4, y: 0, width: width * 0.6, height: view.bounds.height)
        view.addSubview(tableView)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SideListController.clientStateChange), name: keyNotifStateShange, object: nil)
    }
    
    func clientStateChange() {
        tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        
        let width = UIScreen.mainScreen().bounds.width
        
        header.backgroundView = UIView()
        header.backgroundView?.backgroundColor = UIColor.clearColor()
        let label = UILabel()
        label.frame = CGRect(x: 0, y: 20, width: width * 0.6, height: 99)
        label.textAlignment = .Center
        label.font = UIFont.boldSystemFontOfSize(17)
        label.textColor = UIColor.whiteColor()
        label.text = "灯列表"
        header.contentView.addSubview(label)
        
        let separator = UIView()
        separator.backgroundColor = UIColor.whiteColor()
        separator.frame = CGRect(x: 0, y: 99, width: width * 0.6, height: 1)
        header.contentView.addSubview(separator)
        return header
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UITableViewHeaderFooterView()
        
        footer.backgroundView = UIView()
        footer.backgroundView?.backgroundColor = UIColor.whiteColor()
        return footer
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "value1 cell")
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.displayName
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.font = UIFont.systemFontOfSize(17)
        cell.detailTextLabel?.text = device.displayType
        cell.detailTextLabel?.textColor = UIColor.whiteColor()
        cell.detailTextLabel?.font = UIFont.systemFontOfSize(14)
        
        let imageView = UIImageView(image: UIImage(named: "icon_arrow_right"))
        cell.accessoryView = imageView
        cell.tintColor = UIColor.whiteColor()
        cell.imageView?.image = UIImage(named: "icon_online")
        cell.backgroundColor = UIColor.clearColor()
        cell.separatorInset = UIEdgeInsetsZero
        cell.selectionStyle = .None
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        indicator.hidesWhenStopped = true
        indicator.frame = CGRect(x: 10, y: 15, width: 30, height: 30)
        cell.addSubview(indicator)
        
        if device.innetwork {
            cell.imageView?.hidden = false
            indicator.stopAnimating()
        }else {
            cell.imageView?.hidden = true
            indicator.startAnimating()
        }
        
        return cell
    }
    


}
