//
//  OTAService.swift
//  BlueLight
//
//  Created by Rail on 7/19/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class OTAService: NSObject {

    var service:BlueService = BlueService.instance
    
    
    
    func refreshVersion() {
        service.refreshVersion()
    }
    
    func needOta(client:BlueClient?) -> Bool{
        if client != nil {
            if let version = AppInfo.DeviceVersion[(client?.hardwareVersion)!] {
                let sversion = version.substringFromIndex(version.endIndex.advancedBy(-4))
                return compareVersion((client?.softwareVersion)!, curVersion: sversion)
            }
        }
        return false
    }
    
    private func compareVersion(deviceVersion:String, curVersion:String) -> Bool{
        if Int(curVersion) > Int(deviceVersion) {
            return true
        }else {
            return false
        }
    }
    
    
    
    
    var progressBlock:((progress:CGFloat) -> Void)?
    var failureBlock:(() -> Void)?
    var otaLocation:Int = 0
    var otaClient:BlueClient?
    var otaData:NSData?
    var maxLocation:Int = 0
    
    func otaClient(client:BlueClient, progressBlock:((progress:CGFloat) -> Void), failureBlock:(() -> Void)?) {
        self.progressBlock = progressBlock
        self.failureBlock = failureBlock
        otaLocation = 0
        otaClient = client
        service.loginForOta(client) { (success) in
            if success {
                self.loadOTAData()
            }else {
                self.otaFail()
            }
        }
    }
    
    func cancelOTA() {
        
    }
    
    func otaFail() {
        
        failureBlock?()
        failureBlock = nil
        progressBlock = nil
        otaData = nil
        maxLocation = 0
        otaLocation = 0
        otaClient = nil
        service.reLogin()
    }
    
    func otaSuccess() {
        progressBlock?(progress:1)
        failureBlock = nil
        progressBlock = nil
        otaData = nil
        maxLocation = 0
        otaLocation = 0
        self.otaClient = nil
//        service.reLogin()
    }
    
    private func loadOTAData() {
        if let otaFileName = AppInfo.DeviceVersion[(otaClient?.hardwareVersion)!] {
            let url = NSBundle.mainBundle().URLForResource(otaFileName, withExtension: ".bin")
            otaData = NSData(contentsOfURL: url!)
            
            maxLocation = (otaData?.length)! / 16
            if (otaData?.length)! % 16 > 0 {
                maxLocation = maxLocation + 1
            }
            service.readFirmware(otaClient!, block: { (firmware) in
                if firmware == nil {
                    self.otaFail()
                }else {
                    let firmwareStr = String(data: firmware!, encoding: NSUTF8StringEncoding) ?? ""
                    NSLog("升级之前firmWare：%@", firmwareStr)
                    
                    self.sendPacket()
                }
            })
        }else {
            otaFail()
        }
    } 
    
    func sendPacket() {
        if  maxLocation == 0 || otaLocation > maxLocation{
            return
        }
        if otaClient == nil || !otaClient!.isLogin{
            otaFail()
        }
        var packLenght = 0
        if otaLocation == maxLocation {
            packLenght = 0
        }else if otaLocation == maxLocation - 1{
            packLenght = (otaData?.length)! - otaLocation * 16
        }else if otaLocation < maxLocation{
            packLenght = 16
        }
        
        let data = otaData?.subdataWithRange(NSRange(location: otaLocation * 16, length: packLenght)) ?? NSData()
        
        service.sendPack(otaClient!, pack: data, index: UInt(otaLocation)) { success in
//            if success {
//                if self.otaLocation % 50 == 0 && self.otaLocation != 0{
//                    self.service.readFirmware(self.otaClient!, block: { (firmware) in
//                        if firmware == nil {
//                            self.otaFail()
//                        }else {
//                            let firmwareStr = String(data: firmware!, encoding: NSUTF8StringEncoding) ?? ""
//                            NSLog("升级中firmWare：%@", firmwareStr)
//                            self.otaLocation = self.otaLocation + 1
//                            self.sendPacket()
//                        }
//                    })
//                    return
//                }
//                self.otaLocation = self.otaLocation + 1
//                self.sendPacket()
//                return
//            }
//            self.sendPacket()
            
        }
        
        if otaLocation < maxLocation {
            let progress = CGFloat(otaLocation) / CGFloat(maxLocation)
            
            progressBlock?(progress:progress)
            
            if self.otaLocation % 51 == 0 && self.otaLocation != 0{
                self.service.readFirmware(self.otaClient!, block: { (firmware) in
                    if firmware == nil {
                        self.otaFail()
                    }else {
                        let firmwareStr = String(data: firmware!, encoding: NSUTF8StringEncoding) ?? ""
                        NSLog("升级中firmWare：%@", firmwareStr)
                        self.otaLocation = self.otaLocation + 1
                        self.sendPacket()
                    }
                })
                return
            }
            
            NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(OTAService.sendNext), userInfo: nil, repeats: false)
        }else {
            otaSuccess()
        }
        
    }
    
    func sendNext() {
        
        
        self.otaLocation = self.otaLocation + 1
        self.sendPacket()
    }
}
