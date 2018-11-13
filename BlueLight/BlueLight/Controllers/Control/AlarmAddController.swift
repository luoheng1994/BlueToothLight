//
//  AlarmAddController.swift
//  BlueLight
//
//  Created by Rail on 7/12/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

let DisplayWeeks = ["周日","周一","周二","周三","周四","周五","周六"]
class AlarmAddController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var sender:ColorSendAdapter!
    let datePicker = UIDatePicker()
    
    let tableView = UITableView(frame: CGRectZero, style: .Plain)
    
    
    var selectWeeks:[Int] = []
    var action:AlarmAction = .On
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "定时添加"
        view.backgroundColor = UIColor.whiteColor()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "返回", style: .Plain, target: nil, action: nil)
        
        datePicker.datePickerMode = .Time
        datePicker.date = NSDate()
        datePicker.tintColor = UIColor.colorWithHex(0xDFE8EE)
        datePicker.frame = CGRect(x: 0, y: 74, width: view.frame.width, height: 216)
        datePicker.locale = NSLocale(localeIdentifier: "en_US")
        view.addSubview(datePicker)
        
        tableView.frame = CGRect(x: 0, y: 300, width: view.frame.width, height: 82)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorColor = UIColor.colorWithHex(0xDFE8EE)
        tableView.bounces = false
        view.addSubview(tableView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .Plain, target: self, action: #selector(AlarmAddController.doSave))
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AlarmAddController.weekPicked(_:)), name: NotificationWeekPicked, object: nil)
    }
    
    func weekPicked(notification:NSNotification) {
        selectWeeks = notification.userInfo?["weeks"] as! [Int]
        tableView.reloadData()
    }
    
    func doSave() {
        let date = datePicker.date
        if selectWeeks.count > 0 {
            sender.setAlarm(selectWeeks, date: date, action: action, index: 0x00)
        }else {
            sender.setAlarm(date, action: action, index: 0x00)
        }
        Utils.instance.showLoading("保存中", showBg: true)
        performSelector(#selector(AlarmAddController.hideLoading), withObject: nil, afterDelay: 1.5)
    }
    
    func hideLoading() {
        Utils.instance.hideLoading()
        Utils.instance.showTip("保存成功")
        navigationController?.popViewControllerAnimated(true)
    }
    
    //MARK: - UITableView
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 35
    }
 
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "Value1 cell")
        if indexPath.row == 0 {
            cell.textLabel?.text = "重复"
            cell.detailTextLabel?.text = displayWeek()
        }else if indexPath.row == 1 {
            cell.textLabel?.text = "动作"
            cell.detailTextLabel?.text = action == .On ? "开灯" : "关灯"
        }
        cell.accessoryType = .DisclosureIndicator
        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row == 0 {
            let ctl = WeekPickerController(style: .Grouped)
            ctl.selectIndexs = selectWeeks
            navigationController?.pushViewController(ctl, animated: true)
        }else {
            
            let alert = UIAlertController(title: "请选择动作", message: "选择一个定时应该执行动作", preferredStyle: .ActionSheet)
            alert.addAction(UIAlertAction(title: "开灯", style: .Default, handler: { (action) in
                self.action = .On
                self.tableView.reloadData()
                
            }))
            alert.addAction(UIAlertAction(title: "关灯", style: .Default, handler: { (action) in
                self.action = .Off
                self.tableView.reloadData()
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    
    func displayWeek() -> String{
        if selectWeeks.count == 0 {
            return "永不"
        }else if selectWeeks.count == 1 {
            return DisplayWeeks[selectWeeks.first!]
        }else if selectWeeks.count == 2 && selectWeeks.contains(0) && selectWeeks.contains(6){
            return "周末"
        }else if selectWeeks.count == 5 && !selectWeeks.contains(0) && !selectWeeks.contains(6){
            return "工作日"
        }else if selectWeeks.count == 7 {
            return "每天"
        }
        
        var weekStr = ""
        for index in selectWeeks.sort() {
            let week = DisplayWeeks[index]
            weekStr = weekStr + week + " "
        }
        return weekStr
    }
}
