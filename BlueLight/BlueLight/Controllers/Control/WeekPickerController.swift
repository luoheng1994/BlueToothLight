//
//  WeekPickerController.swift
//  BlueLight
//
//  Created by Rail on 7/12/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

let NotificationWeekPicked = "NotificationWeekPicked"

class WeekPickerController: UITableViewController {
    
    var selectIndexs:[Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "重复"
        
        tableView.allowsMultipleSelection = true
    }
    
    override func viewDidAppear(animated: Bool) {
        for index in selectIndexs {
            tableView.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: true, scrollPosition: .None)
        }
    }

    override func navigationShouldPopOnBackButton() -> Bool {
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationWeekPicked, object: self, userInfo: ["weeks":selectIndexs])
        return true
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DisplayWeeks.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: "Default cell")
        cell.textLabel?.text = DisplayWeeks[indexPath.row]
        if selectIndexs.contains(indexPath.row) {
            cell.accessoryType = .Checkmark
        }else {
            cell.accessoryType = .None
        }
        cell.selectionStyle = .None
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = .Checkmark
        if !selectIndexs.contains(indexPath.row) {
            selectIndexs.append(indexPath.row)
        }
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = .None
        selectIndexs.removeAtIndex(selectIndexs.indexOf(indexPath.row)!)
    }
    
}
