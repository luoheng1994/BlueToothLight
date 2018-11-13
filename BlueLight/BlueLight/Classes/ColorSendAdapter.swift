//
//  ColorSendAdapter.swift
//  BlueLight
//
//  Created by Rail on 7/6/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

/// 用来发送数据给设备的中间类
class ColorSendAdapter: NSObject {
    
    /// 灯种类
    var lightType:BlueLightType = .RGBW
    
    /// LightControlController 显示的title
    var displayTitle:String? = "灯控"
    
    /// 数据发送的目标，只有多灯控的时候 大于1，其他count = 1
    var destination:[UInt16] = []
    
    /// 控制的设备
    var devices:[Device] = []

    /// 用来获取状态信息的设备，一般为设备列表的第一个
    var statusDevice:Device?
    /// 当前设备的状态
    var currentState:Status {
        get {
            return statusDevice?.client?.currentStatus ?? Status(bright: 0, r: 0, g: 0, b: 0, w: 0)
        }
        set {
            statusDevice?.client?.currentStatus = newValue
        }
    }
    
    var service:BlueService = BlueService.instance
    
    /**
     单灯控或者多灯控的初始化
     
     - parameter controlDevices: 待控制的设备
     
     - returns: nil
     */
    init(controlDevices:[Device]) {
        super.init()
        devices = controlDevices
        for device in devices {
            destination.append((device.meshAddr?.unsignedShortValue)!)
            if lightType.rawValue < device.type?.integerValue {
                lightType = BlueLightType(rawValue: (device.type?.integerValue)!)!
            }
        }
        if devices.count == 1 {
            displayTitle = devices.first?.displayName
        }
        statusDevice = devices.first
        sourtDevice()
        sendRefreshStatus()
    }
    
    /**
     单组控或多组控的初始化
     
     - parameter groups: 待控制的组
     
     - returns: nil
     */
    init(groups:[Group]) {
        super.init()
        devices = []
        for group in groups {
            destination.append((group.identify?.unsignedShortValue)!)
            for _device in group.devices! {
                let device = _device as! Device
                if !devices.contains(device) {
                    devices.append(device)
                    if lightType.rawValue < device.type?.integerValue {
                        lightType = BlueLightType(rawValue: (device.type?.integerValue)!)!
                    }
                }
            }
        }
        if groups.count == 1 {
            displayTitle = groups.first?.displayName
        }
        statusDevice = devices.first
        sourtDevice()
        sendRefreshStatus()
    }
    
    private func sourtDevice() {
        devices.sortInPlace{ (device1, device2) -> Bool in
            return device1.createDate!.compare(device2.createDate! as NSDate) == .OrderedAscending
        }
    }
    
    /**
     获取第一个设备的状态，用来初始化控制界面
     */
    func sendRefreshStatus() {
        service.sendCmd(CMD_USER_ALL, dest: destination.first!, data: NSData(bytes: [UInt8(0x10)], length: 1))
    }
    
    /**
     开灯命令
     */
    func sendLightOn() {
        sendCmd(CMD_Light_ON_OFF, data: NSData(bytes: [UInt8(0x01)], length: 1))
    }
    
    func sendLightOff() {
        sendCmd(CMD_Light_ON_OFF, data: NSData(bytes: [UInt8(0x00)], length: 1))
    }
    
    func sendLum(bright:CGFloat) {
        let _bright = UInt8(bright * 100)
        currentState = Status(bright: _bright, r: currentState.r, g: currentState.g, b: currentState.b, w: currentState.w)
        sendCmd(CMD_SET_LUM, data: NSData(bytes: [_bright], length: 1))
    }
    
    func send(red:CGFloat, green:CGFloat, blue:CGFloat) {
        let color = [0x04,
                     UInt8(red * 255),
                     UInt8(green * 255),
                     UInt8(blue * 255) ]
        currentState = Status(bright: currentState.bright, r: color[1], g: color[2], b: color[3], w: 0)
        sendCmd(CMD_SET_LIGHT, data: NSData(bytes: color, length: 4))
    }
    
    func send(red:CGFloat, green:CGFloat, blue:CGFloat, white:CGFloat) {
        let color = [0x04,
                     UInt8(red * 255),
                     UInt8(green * 255),
                     UInt8(blue * 255),
                     UInt8(white * 255)]
        currentState = Status(bright: currentState.bright, r: color[1], g: color[2], b: color[3], w: color[4])
        sendCmd(CMD_SET_LIGHT, data: NSData(bytes: color, length: 5))
    }
    
    func send(yellow:CGFloat, white:CGFloat) {
        let color = [0x06,
                     UInt8(yellow * 255),
                     UInt8(white * 255) ]
        currentState = Status(bright: currentState.bright, r: color[1], g: color[2], b: 0, w: 0)
        sendCmd( CMD_SET_LIGHT, data: NSData(bytes: color, length: 3))
    }
    
    func sendCmd(cmd:Int32, data:NSData) {
        if destination.count == 1 {
            service.sendCmd(cmd, dest: destination.first!, data: data)
        }else {
            service.delaySend(cmd, dests: destination, data: data)
        }
    }
    
    //MARK: - Get Alarm
    
   
    
    func getAlarm(block:((data:[UInt16: [Alarm]], finished:Bool) -> Void)?) {
        var dests = [UInt16]()
        for device in devices {
            if device.innetwork {
                dests.append((device.client?.meshAddr)!)
            }
        }
        service.getAlarm(dests, callback: block)
    }
    
    func deleteAlarm(index:UInt8, dest:UInt16) {
        let bytes = [0x01, index]
        let data = NSData(bytes: bytes, length: 2)
        service.sendCmd(CMD_ALARM, dest: dest, data: data)
    }
    
    func setAlarmEnabe(enable:Bool, index:UInt8, dest:UInt16) {
        let cmd:UInt8 = enable ? 0x03 : 0x04
        let bytes = [cmd, index]
        let data = NSData(bytes: bytes, length: 2)
        service.sendCmd(CMD_ALARM, dest: dest, data: data)
    }
    
    //MARK: - Set Alarm
    func setAlarm(weeks:[Int], date:NSDate, action:AlarmAction, index:UInt8) {
        let data = getAlarmData(weeks, date: date, action: action, index: index, cmd: 0x00)
        sendCmd(CMD_ALARM, data: data)
    }
    
    private func getAlarmData(weeks:[Int]?, date:NSDate, action:AlarmAction, index:UInt8, cmd:UInt8) ->NSData {
        if weeks != nil {
            var week = 0
            for _week in weeks! {
                week = 0x01 << _week | week
            }
            let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)
            let components = calendar?.components([.Hour, .Minute, .Second], fromDate: date)
            
            let hour = UInt8((components?.hour)!)
            let min = UInt8((components?.minute)!)
            let sec = UInt8((components?.second)!)
            
            var par = AlarmCmd(cmd: action.rawValue, type: 0x01, enable: 0x01)
            let parData = NSData(bytes: &par, length: 1)
            var parByte:UInt8 = 0
            parData.getBytes(&parByte, length: 1)
            
            let bytes = [cmd, index, parByte, 0x00, UInt8(week), hour, min, sec]
            return NSData(bytes: bytes, length: 8)
        }else {
            let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)
            var newDate = date
            if date.compare(NSDate()) == .OrderedAscending {
                let components = NSDateComponents()
                components.setValue(1, forComponent: .Day)
                newDate = (calendar?.dateByAddingComponents(components, toDate: date, options: .MatchFirst))!
            }
            
            
            let components = calendar?.components([.Month, .Day, .Hour, .Minute, .Second], fromDate: newDate)
            let month = UInt8((components?.month)!)
            let day = UInt8((components?.day)!)
            let hour = UInt8((components?.hour)!)
            let min = UInt8((components?.minute)!)
            let sec = UInt8((components?.second)!)
            
            var par = AlarmCmd(cmd: action.rawValue, type: 0x00, enable: 0x01)
            let parData = NSData(bytes: &par, length: 1)
            var parByte:UInt8 = 0
            parData.getBytes(&parByte, length: 1)
            
            let bytes = [cmd, index, parByte, month, day, hour, min, sec]
            return NSData(bytes: bytes, length: 8)
        }
    }
    
    func setAlarm(date:NSDate, action:AlarmAction, index:UInt8) {
        let data = getAlarmData(nil, date: date, action: action, index: index, cmd: 0x00)
        sendCmd(CMD_ALARM, data: data)
    }
    
    func editAlarm(dest:UInt16, weeks:[Int], date:NSDate, action:AlarmAction, index:UInt8) {
        let data = getAlarmData(weeks, date: date, action: action, index: index, cmd: 0x02)
        service.sendCmd(CMD_ALARM, dest: dest, data: data)
    }
    
    func editAlarm(dest:UInt16, date:NSDate, action:AlarmAction, index:UInt8) {
        let data = getAlarmData(nil, date: date, action: action, index: index, cmd: 0x02)
        service.sendCmd(CMD_ALARM, dest: dest, data: data)
    }
    
    //MARK: - Streamer
    func sendStreamer(colors:[UInt32], speed:UInt8) {
    
        dispatch_async(service.manager.centralQueue) {
            let delay = 0.1 * Double(self.destination.count)
            var bytes:[UInt8] = [0x00]
            self.sendCmd(CMD_CHANGE_COLOR, data: NSData(bytes: bytes, length: 1))
            NSThread.sleepForTimeInterval(delay)
            for (index, color) in colors.enumerate() {
                bytes = [0x01, UInt8(index)]
                switch self.lightType {
                case .RGBW:
                    let red = color >> 16 & 0xFF
                    let green = color >> 8 & 0xFF
                    let blue = color & 0xFF
                    let white = color >> 24 & 0xFF
                    bytes.append(UInt8(red))
                    bytes.append(UInt8(green))
                    bytes.append(UInt8(blue))
                    bytes.append(UInt8(white))
                case .RGB:
                    let red = color >> 16 & 0xFF
                    let green = color >> 8 & 0xFF
                    let blue = color & 0xFF
                    bytes.append(UInt8(red))
                    bytes.append(UInt8(green))
                    bytes.append(UInt8(blue))
                case .YW:
                    let yellow = color >> 8 & 0xFF
                    let white = color & 0xFF
                    bytes.append(UInt8(yellow))
                    bytes.append(UInt8(white))
                }
                self.sendCmd(CMD_CHANGE_COLOR, data: NSData(bytes: bytes, length: bytes.count))
                NSThread.sleepForTimeInterval(delay)
            }
            
            bytes = [speed]
            self.sendCmd(CMD_START_CHANGE, data: NSData(bytes: bytes, length: 1))
            
        }
    }
    
}
