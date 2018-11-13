//
//  AppInfo.swift
//  BlueLight
//
//  Created by Rail on 7/1/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class AppInfo: NSObject {

    class var shareInfo:AppInfo {
        struct Static {
            static let instance: AppInfo = AppInfo()
        }
        return Static.instance
    }
    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    //登陆的mesh name
    var userName:String! {
        didSet {
            userDefaults.setObject(userName, forKey: "userName")
            userDefaults.synchronize()
        }
    }
    
    //登陆的mesh密码
    var userPwd:String! {
        didSet {
            userDefaults.setObject(userPwd, forKey: "userPwd")
            userDefaults.synchronize()
        }
    }
    
    override init() {
        self.userName = userDefaults.objectForKey("userName") as? String ?? BTDevInfo_UserNameDef
        self.userPwd = userDefaults.objectForKey("userPwd") as? String ?? BTDevInfo_UserPasswordDef
    }
    
    /// 判断是否初始化数据的标志
    var isInit:Bool! {
        get {
            return userDefaults.boolForKey("isInit")
        }
        set {
            userDefaults.setBool(newValue, forKey: "isInit")
            userDefaults.synchronize()
        }
    }
    
    func checkInit() {
        if !isInit {
            initData()
            isInit = true
        }
    }
    
    /**
     初始化默认信息
     
     - returns: nil
     */
    func initData() {
        saveScene(.RGBW, color: 0x807F00, name: "黄色")
        saveScene(.RGBW, color: 0xFF0000, name: "红色")
        saveScene(.RGBW, color: 0x00FF00, name: "绿色")
        saveScene(.RGBW, color: 0x0000FF, name: "蓝色")
        
        saveScene(.RGB, color: 0x807F00, name: "黄色")
        saveScene(.RGB, color: 0xFF0000, name: "红色")
        saveScene(.RGB, color: 0x00FF00, name: "绿色")
        saveScene(.RGB, color: 0x0000FF, name: "蓝色")
        
        saveScene(.YW, color: 0x00FF00, name: "黄色")
        saveScene(.YW, color: 0x0000FF, name: "白色")
    }
    
    private func saveScene(type:BlueLightType, color:UInt32, name:String) {
        SceneManager.sharedCoreDataManader.saveScene(["type":NSNumber(integer:type.rawValue),
                                                    "color":NSNumber(unsignedInt:UInt32(color)),
                                                    "name":name])
    }
    
    //硬件版本信息
    static let CurrentVersion = "S0103"
    
    static let DeviceVersion:[String :String] = ["H030101" : "CTFM02P30D02C00H030101-S0103",
                                                 "H040101" : "CTFM02P30D02C00H040101-S0103",
                                                 "H060101" : "CTFM02P30D02C00H060101-S0103"]
    
}
