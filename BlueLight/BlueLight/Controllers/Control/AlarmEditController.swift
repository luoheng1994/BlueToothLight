//
//  AlarmEditController.swift
//  BlueLight
//
//  Created by Rail on 7/13/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class AlarmEditController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var sender:ColorSendAdapter!
    let datePicker = UIDatePicker()
    
    let tableView = UITableView(frame: CGRectZero, style: .Plain)
    
    var selectWeeks:[Int] = []
    var action:AlarmAction = .On
    
    var alarm:Alarm! {
        didSet {
            action = AlarmAction(rawValue: alarm.par1.cmd)!
            if alarm.par1.type == 1 {
                let week = alarm.par2.week
                selectWeeks = [Int]()
                for i in 0...6 {
                    if week >> UInt8(i) & 0x01 == 1 {
                        selectWeeks.append(i)
                    }
                }
            }
            
        }
    }
    var dest:UInt16!
    
    let bottomView = UIView()
    let deleteBtn = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "定时编辑"
        view.backgroundColor = UIColor.whiteColor()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "返回", style: .Plain, target: nil, action: nil)
        
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)
        let components = (calendar?.components([.Year, .Month, .Hour, .Minute, .Second], fromDate: NSDate()))!
        components.setValue(Int(alarm.hour), forComponent: .Hour)
        components.setValue(Int(alarm.minute), forComponent: .Minute)
        components.setValue(Int(alarm.second), forComponent: .Second)
        let date = calendar?.dateFromComponents(components)
        
        datePicker.datePickerMode = .Time
        datePicker.date = date!
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
        
        bottomView.frame = CGRect(x: 0, y: view.frame.height - 100, width: view.frame.width, height: 100)
        bottomView.backgroundColor = UIColor.backgroundColor()
        bottomView.layer.shadowColor = UIColor.blackColor().CGColor
        bottomView.layer.shadowOffset = CGSize(width: 0, height: -5)
        bottomView.layer.shadowRadius = 8
        bottomView.layer.shadowOpacity = 0.1
        view.addSubview(bottomView)
        
        deleteBtn.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        deleteBtn.center = CGPoint(x: view.frame.width / 2, y: 50)
        deleteBtn.setTitle("删除定时", forState: .Normal)
        deleteBtn.setTitleColor(UIColor.merryCranesbill(), forState: .Normal)
        deleteBtn.layer.cornerRadius = 16
        deleteBtn.layer.borderColor = UIColor.merryCranesbill().CGColor
        deleteBtn.layer.borderWidth = 1
        deleteBtn.addTarget(self, action: #selector(AlarmEditController.deleteAlarm), forControlEvents: .TouchUpInside)
        bottomView.addSubview(deleteBtn)
    }
    
    func weekPicked(notification:NSNotification) {
        selectWeeks = notification.userInfo?["weeks"] as! [Int]
        tableView.reloadData()
    }
    
    func doSave() {
        let date = datePicker.date
        if selectWeeks.count > 0 {
            sender.editAlarm(dest, weeks:selectWeeks, date: date, action: action, index: alarm.index)
        }else {
            sender.editAlarm(dest, date:date, action: action, index: alarm.index)
        }
        Utils.instance.showLoading("保存中", showBg: true)
        performSelector(#selector(AlarmAddController.hideLoading), withObject: nil, afterDelay: 1.5)
    }
    
    func deleteAlarm() {
        sender.deleteAlarm(alarm.index, dest: dest)
        navigationController?.popViewControllerAnimated(true)
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
