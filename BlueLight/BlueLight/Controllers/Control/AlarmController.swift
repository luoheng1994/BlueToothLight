//
//  AlarmController.swift
//  BlueLight
//
//  Created by Rail on 7/11/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class AlarmController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var colorSender:ColorSendAdapter!
    
    let tableView = UITableView(frame: CGRectZero, style: .Grouped)
    
    let bottomView = UIView()
    let addBtn = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "定时"
        view.backgroundColor = UIColor.whiteColor()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "返回", style: .Plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_edit"), style: .Plain, target: self, action: #selector(AlarmController.startEdit))
        
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 100)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.whiteColor()
        tableView.separatorStyle = .None
        view.addSubview(tableView)
        
        bottomView.frame = CGRect(x: 0, y: view.frame.height - 100, width: view.frame.width, height: 100)
        bottomView.backgroundColor = UIColor.backgroundColor()
        bottomView.layer.shadowColor = UIColor.blackColor().CGColor
        bottomView.layer.shadowOffset = CGSize(width: 0, height: -5)
        bottomView.layer.shadowRadius = 8
        bottomView.layer.shadowOpacity = 0.1
        view.addSubview(bottomView)
        
        addBtn.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        addBtn.center = CGPoint(x: view.frame.width / 2, y: 50)
        addBtn.setTitle("添加定时", forState: .Normal)
        addBtn.setTitleColor(UIColor.colorWithHex(0xA8A8A8), forState: .Normal)
        addBtn.layer.cornerRadius = 16
        addBtn.layer.borderColor = UIColor.themeColor().CGColor
        addBtn.layer.borderWidth = 1
        addBtn.addTarget(self, action: #selector(AlarmController.addAlarm), forControlEvents: .TouchUpInside)
        bottomView.addSubview(addBtn)
    }
    
    var alarmData:[UInt16: [Alarm]] = [:]
    
    override func viewWillAppear(animated: Bool) {
        Utils.instance.showLoading("加载中", inView: view)
        colorSender.getAlarm { (data, finished) in
            self.alarmData = data
            self.tableView.reloadData()
            if finished {
                Utils.instance.hideLoading()
            }
        }
        tableView.editing = false
        
    }

    func startEdit() {
        tableView.setEditing(!tableView.editing, animated: true)
    }
    
    func addAlarm() {
        
        for (_, alarms) in alarmData {
            if alarms.count == 16 {
                Utils.instance.showTip("一盏灯最多只能添加16个定时")
                return
            }
        }
        
        let ctl = AlarmAddController()
        ctl.sender = colorSender
        navigationController?.pushViewController(ctl, animated: true)
        
    }
    
    //MARK: - TableView
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return colorSender.devices.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let device = colorSender.devices[section]
        let dest = (device.meshAddr?.unsignedShortValue)!
        return alarmData[dest]?.count ?? 0
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        let backView = UIImageView()
        let index = section % 5 + 1
        let imageName = "list_background_\(index)"
        backView.image = UIImage(named: imageName)
        header.backgroundView = backView

        let device = colorSender.devices[section]
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_online")?.imageWithRenderingMode(.AlwaysTemplate)
        imageView.tintColor = device.innetwork ? UIColor.themeColor() : UIColor.colorWithHex(0x95a9b7)
        imageView.frame = CGRect(x: 15, y: 20, width: 20, height: 20)
        header.contentView.addSubview(imageView)
        
        let label = UILabel()
        label.text = device.displayName
        label.textAlignment = .Left
        label.font = UIFont.systemFontOfSize(20)
        label.frame = CGRect(x: 58, y: 19, width: 250, height: 22)
        label.textColor = UIColor.colorWithHex(0x343434)
        header.contentView.addSubview(label)


        if device.innetwork {
            let downView = UIImageView()
            downView.image = UIImage(named: "icon_down")!.imageWithRenderingMode(.AlwaysTemplate)
            downView.tintColor = UIColor.whiteColor()
            downView.contentMode = .ScaleAspectFit
            downView.frame = CGRect(x: view.frame.width - 40, y: 19, width: 20, height: 22)
            header.contentView.addSubview(downView)
        }
        
        
        return header
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "value1 cell")
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.font = UIFont.systemFontOfSize(15)
        cell.detailTextLabel?.textAlignment = .Left
        
        let textLabel = UILabel()
        textLabel.frame = CGRect(x: 53, y: 8, width: 230, height: 22)
        textLabel.font = UIFont.systemFontOfSize(18)
        textLabel.textColor = UIColor.colorWithHex(0x333333)
        cell.contentView.addSubview(textLabel)
        
        let detailLabel = UILabel()
        detailLabel.frame = CGRect(x: 53, y: 32, width: 230, height: 18)
        detailLabel.font = UIFont.systemFontOfSize(13)
        detailLabel.textColor = UIColor.colorWithHex(0x999999)
        cell.contentView.addSubview(detailLabel)
        
        let device = colorSender.devices[indexPath.section]
        let addr = device.meshAddr?.unsignedShortValue
        let alarms = alarmData[addr!]
        if let alarm = alarms?[indexPath.row] {
            if alarm.par1.type == 1 {
                detailLabel.text = getDisplayWeek(alarm.par2.week)
            }else {
                detailLabel.text = "永不"
            }
            
            textLabel.text = String(format: "%02d:%02d", alarm.hour, alarm.minute)
            
            if alarm.par1.cmd == 0 {
                cell.detailTextLabel?.text = "关灯   "
            }else {
                cell.detailTextLabel?.text = "开灯   "
            }
            
            //SeprateView
            if indexPath.row < alarms!.count - 1 {
                let sepView = UIView()
                sepView.frame = CGRect(x: 15, y: 49, width: view.frame.width + 15, height: 1)
                sepView.backgroundColor = UIColor.colorWithHex(0xDFE8EE)
                cell.contentView.addSubview(sepView)
            }
            let switchView = UISwitch()
            cell.accessoryView = switchView
            switchView.on = alarm.par1.enable == 1
            switchView.addTarget(self, action: #selector(AlarmController.switchChange(_:)), forControlEvents: .ValueChanged)
        }
        cell.selectionStyle = .None
        return cell
    }
    
    func switchChange(sender:UISwitch) {
        let cell = sender.superview as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)!
        let device = colorSender.devices[indexPath.section]
        let addr = device.meshAddr?.unsignedShortValue
        let alarms = alarmData[addr!]
        if let alarm = alarms?[indexPath.row] {
          colorSender.setAlarmEnabe(sender.on, index: alarm.index, dest: (device.meshAddr?.unsignedShortValue)!)
        }
        
    }
    
    func getDisplayWeek(week:UInt8) -> String{
        var selectWeeks = [Int]()
        for i in 0...6 {
            if week >> UInt8(i) & 0x01 == 1 {
                selectWeeks.append(i)
            }
        }
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
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let device = colorSender.devices[indexPath.section]
            let addr = device.meshAddr?.unsignedShortValue
            if let alarm = alarmData[addr!]?[indexPath.row] {
                alarmData[addr!]?.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                colorSender.deleteAlarm(alarm.index, dest: (device.meshAddr?.unsignedShortValue)!)
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let device = colorSender.devices[indexPath.section]
        let addr = device.meshAddr?.unsignedShortValue
        if let alarm = alarmData[addr!]?[indexPath.row] {
            let ctl = AlarmEditController()
            ctl.alarm = alarm
            ctl.dest = addr!
            ctl.sender = colorSender
            navigationController?.pushViewController(ctl, animated: true)
        }
        
    }
}
