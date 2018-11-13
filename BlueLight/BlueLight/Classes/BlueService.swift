//
//  BlueService.swift
//  BlueLight
//
//  Created by Rail on 7/1/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

let NearbyClientsRefreshNotification = "NearbyClientsRefreshNotification"
let ListClientsAddNotification = "ListClientsAddNotification"
let NodeClientStatusChangeNotification = "NodeClientStatusChangeNotification"

enum ClientStatus:Int {
    case None = 0
    case Connecting
    case Connected
}

class BlueService: NSObject, BlueManagerDelegate, BlueClientDelegate {
    
    static var instance:BlueService {
        struct Static {
            static let instance = BlueService()
        }
        return Static.instance
    }
    
    
    let manager = BlueManager()
    
    //一键开关灯命令，需要重发3次。。。。
    var sendCount = 0
    
    //节点设备的连接状态
    var nodeClientStatus:ClientStatus = .None {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NodeClientStatusChangeNotification), object: nil)
        }
    }
    
    override init() {
        super.init()
        manager.delegate = self
        
    }
    //扫描结果代理
    func blueManager(manager: BlueManager!, didDiscoverClient client: BlueClient!) {
        discoveredClients.append(client)
        if initialScan {
            notify()
        }
        checkLogin()
        checkMeshAddr(client: client)
    }
    
    func blueManager(manager: BlueManager!, didUpdateState state: CBCentralManagerState) {
        if state == .poweredOn {
            startScan()
        }else {
            meshClient?.clean()
            meshClient = nil
            discoveredClients = []
            notify()
            for device in DeviceManager.sharedCoreDataManader.devices {
                device.innetwork = false
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationReloadData), object: nil)
            nodeClientStatus = .None
        }
    }
    
    //mesh连接点， 通过这个设备收发数据
    var meshClient:BlueClient?
    
    //第一次扫面时，每扫描到一个设备都会通知
    var initialScan = true
    //附近发现的设备
    var discoveredClients:[BlueClient] = []
    //附近发现的设备，从数据库中读取
    var discoveredDevices:[Device] = []
    
    //mesh网络中的设备，通过USER_ALL命令获取
    var meshClients:[BlueClient] = []
    //mesh 网络中的设备
    var listDevices:[Device] = []
    //扫描定时器，10秒钟为一轮
    var discoverTimer:Timer?
   
    // 开始扫描
    func startScan() {
        
        NSLog("--------------------------")
        initialScan = true
        discoveredClients = []
        manager.stopScan()
        manager.startScan()
        if discoverTimer != nil && discoverTimer!.isValid {
            discoverTimer?.invalidate()
        }
        discoverTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(BlueService.startFetch), userInfo: nil, repeats: true)
    }
    //停止扫描
    func stopScan() {
        initialScan = true
        discoveredClients = []
        manager.stopScan()
        
        if discoverTimer != nil && discoverTimer!.isValid {
            discoverTimer?.invalidate()
        }
    }
    //重新扫描
    func startFetch() {
        NSLog("--------------------------")
        if !initialScan {
            notify()
        }
        initialScan = false
        discoveredClients = []
        manager.stopScan()
        manager.startScan()
    }
    //扫描结果通知
    private func notify() {
        
        discoveredDevices = []
        meshClients = []
        if let client = meshClient {
            if !discoveredClients.contains(client) && client.isConnected {
                discoveredClients.append(client)
            }
        }
        for client in discoveredClients {
            var device = DeviceManager.sharedCoreDataManader.fetchDeviceByMacAddress(mac: client.macAddress)
            let dict = [
                "uuid": client.uuidString,
                "mac": client.macAddress ?? "",
                "type": client.type.rawValue,
                "meshAddr": NSNumber(unsignedShort: client.meshAddr),
                "meshName": client.meshName,
                "meshPwd": client.meshPwd
            ]
            if device == nil {
                device = DeviceManager.sharedCoreDataManader.saveDevice(dic: dict)
            }else {
                device?.setValuesForKeysWithDictionary(dict)
            }
            if device?.client == nil {
                device?.client = client
            }else {
                device?.client!.meshName = client.meshName
                device?.client!.meshPwd = client.meshPwd
                device?.client!.name = client.name
                device?.client!.uuidString = client.uuidString
                device?.client!.peripheral = client.peripheral
                device?.client!.rssi = client.rssi
                
                device?.client!.type = client.type
                device?.client!.meshAddr = client.meshAddr
                device?.client!.macAddress = client.macAddress
                device?.client!.u_Mac = client.u_Mac
            }
            discoveredDevices.append(device!)
            
            if client.meshName == AppInfo.shareInfo.userName {
                meshClients.append(client)
            }
        }
        DeviceManager.sharedCoreDataManader.saveContext()
        discoveredDevices.sortInPlace { (device1, device2) -> Bool in
            return device1.createDate!.compare(device2.createDate! as NSDate) == .OrderedAscending
        }
        NSNotificationCenter.defaultCenter().postNotificationName(NearbyClientsRefreshNotification, object: self, userInfo: ["devices": discoveredDevices])
        
        
        
        if meshClients.count  == 0 {
            for device in listDevices {
                device.innetwork = false
            }
        }
        
    }
    
    
    //MARK: - 更新mesh addr
    
    //检查mesh addr是否重复
    func checkMeshAddr(client:BlueClient) {
        if client.meshName != AppInfo.shareInfo.userName {
            return
        }
        
        let devices = DeviceManager.sharedCoreDataManader.devices
        for device in devices {
            if device.meshName == AppInfo.shareInfo.userName && device.mac != client.macAddress{
                if client.meshAddr == device.meshAddr?.unsignedShortValue {
                    changeMeshAddr(client)
                }
            }
        }
    }
    //正在更新标志，如果为true表示正在更新一个设备的mesh addr，将不能继续更新其他设备
    var isChanging = false
    //待更新的client
    var updateMeshClient:BlueClient?
    //待设置的mesh addr
    var updateMeshAddr:UInt16 = 1
    //超时timer
    var updateMeshAddrTimer:NSTimer?
    //开始更新
    func changeMeshAddr(client:BlueClient) {
        if isChanging {
            return
        }
        isChanging = true
        let devices = DeviceManager.sharedCoreDataManader.devices
        var meshAddrs:[UInt16] = []
        for device in devices {
            if device.meshName == AppInfo.shareInfo.userName && device.mac != client.macAddress{
                meshAddrs.append((device.meshAddr?.unsignedShortValue)!)
            }
        }
        for i in 1...UInt16(0xFF) {
            if !meshAddrs.contains(i) {
                updateMeshAddr = i
                break
            }
        }
        updateMeshClient = client
        //连接并且登陆设备，登陆成功回调的时候继续执行设置mesh addr
        manager.loginWithPwd(AppInfo.shareInfo.userPwd, client: client)
        updateMeshAddrTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(BlueService.cleanUpdateMeshAddr), userInfo: nil, repeats: false)
    }
    
    //清除更新mesh addr 信息
    func cleanUpdateMeshAddr() {
        
        isChanging = false
        updateMeshClient = nil
        if updateMeshAddrTimer != nil && updateMeshAddrTimer!.valid {
            updateMeshAddrTimer?.invalidate()
        }
    }
    
    
    //MARK: Login
    //检查登陆
    func checkLogin() -> Bool{
        if meshClient == nil{
            if meshClients.count > 0 {
                loginWith(meshClients[0])
                nodeClientStatus = .Connecting
            }
            return false
        }else if meshClient!.peripheral.state == .Disconnected {
            loginWith(meshClient!)
            nodeClientStatus = .Connecting
            return false
        }
        return true
    }
    
    
    /**
     登陆设备
     
     - parameter client: 即将登陆的client
     */
    func loginWith(client:BlueClient) {
        meshClient = client
        manager.loginWithPwd(AppInfo.shareInfo.userPwd, client: self.meshClient)
    }
    
    //重新登陆
    func reLogin() {
        manager.cancelLogin(meshClient)
        meshClient = nil
        notify()
    } 
    
    
    //MARK: Update Network Info
    //待更新的设备列表
    var updateClients:[BlueClient] = []
    //设备通过这个密码去登陆
    var oldPassword = ""
    //当前正在连接-更改的设备
    var curUpdateClient:BlueClient?
    //全部执行完毕后回调
    var updataBlock:((_ success:Bool)->Void)?
    //更新设备账号密码
    func setCurrentNetword(oldPwd:String, block:((_ success:Bool)->Void)?) {
        var clients = [BlueClient]()
        for device in listDevices {
            if meshClients.contains(device.client!) {
                clients.append(device.client!)
            }
        }
        if clients.count == 0 {
            block?(success: true)
            
        }else {
            setNetwork(oldPwd, clients: clients, block: block)
        }
    }
    //开始更新设备
    func setNetwork(oldPwd:String, clients:[BlueClient], block:((_ success:Bool)->Void)?) {
        updateClients = clients
        oldPassword = oldPwd
        updataBlock = block
        updataNext()
    }
    
    //逐个连接附近的设备，进行数据更新
    private func updataNext() {
        if updateClients.count == 0 {
            return
        }
        if curUpdateClient == nil {
            curUpdateClient = updateClients[0]
        }else {
            let curIndex = updateClients.indexOf(curUpdateClient!)
            if curIndex < updateClients.count - 1 {
                curUpdateClient = updateClients[curIndex! + 1]
            }else {
                updataBlock?(success: true)
                manager.cancelLogin(curUpdateClient)
                curUpdateClient = nil
                updateClients = []
                return
            }
        }
        if curUpdateClient != nil && curUpdateClient!.isConnected && curUpdateClient!.isLogin {
            sendUpdateInfo()
        }else {
            manager.loginWithPwd(oldPassword, client: curUpdateClient)
        }
        
    }
    
    //发送更新数据
    private func sendUpdateInfo() {
        curUpdateClient?.updateName(AppInfo.shareInfo.userName, andPassword: AppInfo.shareInfo.userPwd, withCallBack: { (success) in
            if success {
                self.curUpdateClient?.meshName = AppInfo.shareInfo.userName
                let device = DeviceManager.sharedCoreDataManader.fetchDeviceByMacAddress((self.curUpdateClient?.macAddress)!)
                device?.meshName = AppInfo.shareInfo.userName
                DeviceManager.sharedCoreDataManader.saveContext()
            }
            self.manager.cancelLogin(self.curUpdateClient)
            self.updataNext()
        })
    }
    
    //MARK: - 更新网络中的设备列表
    //获取mesh网络中的设备
    func getNetworkClient() {
        if !checkLogin() {
            return
        }
        listDevices = []
        meshClient?.notifyOpen()
        let bytes:[UInt8] = [0x10]
        let data = NSData(bytes: bytes, length: 1)
        meshClient?.sendCmd(UInt8(CMD_USER_ALL), dest: 0xffff, withData: data)
        performSelector(#selector(BlueService.getGroup), withObject: nil, afterDelay: 4)//防止数据没接收完成，延时发送获取分组
    }
    
    //获取分组信息
    func getGroup() {
        let bytes:[UInt8] = [0x10, 0x01]
        let data = NSData(bytes: bytes, length: 2)
        self.meshClient?.sendCmd(UInt8(CMD_GET_G_8), dest: 0xffff, withData: data)
    }
    
    //MARK: - BlueManagerDelegate
    //登陆成功
    func blueManager(manager: BlueManager!, didSuccessLoginClient client: BlueClient!) {
        
        if client == meshClient && client != otaClient{
            setTime()
            client.delegate = self;
            getNetworkClient()
            nodeClientStatus = .Connected
        }
        if self.updateClients.contains(client) {
            sendUpdateInfo()
        }
        
        //登陆成功，跟新meshAddr
        if updateMeshClient == client {
            updateMeshClient?.updateMeshAddr(updateMeshAddr, withCallBack: { success in
                if self.meshClient == self.updateMeshClient {
                    self.getNetworkClient()
                }else {
                    manager.cancelLogin(client)
                }
                self.cleanUpdateMeshAddr()
            })
        }
        
        if otaClient == client {
            otaLoginBlock?(success:true)
            client.delegate = self;
            
        }
    }
    
    //登陆失败
    func blueManager(manager: BlueManager!, didFailLoginClient client: BlueClient!) {
        if client == meshClient {
            meshClient = nil
            if (meshClients.count > 0) {
                if let index = meshClients.indexOf(client) {
                    if client != meshClients.last {
                        loginWith(meshClients[index + 1])
                        return
                    }
                }
                nodeClientStatus = .Connecting
                loginWith(meshClients[0])
            }
        }
        
        if self.updateClients.contains(client) {
            if updateClients.count == 1 {
                updataBlock?(success: false)
                curUpdateClient = nil
                updateClients = []
            }else {
                updataNext()
            }
        }
        
        if otaClient == client {
            otaLoginBlock?(success:false)
        }
    }
    //设备断开连接
    func blueManager(manager: BlueManager!, didDisConnectClient client: BlueClient!) {
        NSLog("%@ disconnect", client.macAddress)
        if client == meshClient {
            meshClient = nil
            if (meshClients.count > 0) {
                if let index = meshClients.indexOf(client) {
                    if client != meshClients.last {
                        loginWith(meshClients[index + 1])
                        return
                    }
                }
                loginWith(meshClients[0])
                nodeClientStatus = .Connecting
            }
        }
        
    }
    
    
    //MARK: BlueClientDelegate
    //接收到设备的通知，开光状态， 亮度变化，在线离线改变
    func didNotifyData(data: NSData!) {
        var bytes:[UInt8] = [UInt8](count: 20, repeatedValue: 0)
        data.getBytes(&bytes, length: 20)
        
        var addr = bytes[10]
        if addr > 0 {
            let state = bytes[11]
            let device = getDeviceByMeshAddr(UInt16(addr))
            device?.innetwork = state > 0
            device?.bright = bytes[12]
        }
        
        addr = bytes[14]
        if addr > 0 {
            let state = bytes[15]
            let device = getDeviceByMeshAddr(UInt16(addr))
            device?.innetwork = state > 0
            device?.bright = bytes[16]
        }
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationReloadData, object: nil)
        
    }
    //更具mesh addr 查找当前网络中的设备
    private func getDeviceByMeshAddr(meshAddr:UInt16) ->Device?{
        let devices = DeviceManager.sharedCoreDataManader.fetchDeviceByMeshName(AppInfo.shareInfo.userName)
        
        for device in devices {
            if device.meshAddr?.unsignedShortValue == meshAddr {
                return device
            }
        }
        return nil
    }
    
    //发现新设备，通过UserAll获取后的回调
    func blueClient(client: BlueClient!, didDiscoverNewClient newClient: BlueClient!) {
        var device = DeviceManager.sharedCoreDataManader.fetchDeviceByMacAddress(newClient.macAddress)
        let dict = [
            "mac": newClient.macAddress ?? "",
            "type": newClient.type.rawValue,
            "meshAddr": NSNumber(unsignedShort: newClient.meshAddr),
            "meshName": AppInfo.shareInfo.userName,
            "meshPwd": AppInfo.shareInfo.userName
        ]
        if device == nil {
            device = DeviceManager.sharedCoreDataManader.saveDevice(dict)
        }else {
            device?.setValuesForKeysWithDictionary(dict)
        }
        if device?.client == nil {
            
            device?.client = newClient
        }else {
            device?.client?.meshAddr = newClient.meshAddr
            device?.client?.currentStatus = newClient.currentStatus
            device?.client?.type = newClient.type
            device?.meshAddr = NSNumber(unsignedShort: newClient.meshAddr)
            device?.type = NSNumber(integer: newClient.type.rawValue)
        }
        DeviceManager.sharedCoreDataManader.saveContext()
        
        if !listDevices.contains(device!) {
            listDevices.append(device!)
            var savedDevices = DeviceManager.sharedCoreDataManader.fetchDeviceByMeshName(AppInfo.shareInfo.userName)
            
            for device in savedDevices {
                device.innetwork = listDevices.contains(device)
            }
            savedDevices.sortInPlace({ (device1, device2) -> Bool in
                return device1.createDate!.compare(device2.createDate! as NSDate) == .OrderedAscending || device1.innetwork && !device2.innetwork
            })
            NSNotificationCenter.defaultCenter().postNotificationName(ListClientsAddNotification, object: self, userInfo: ["devices": savedDevices])
        }
        
    }
    
    //获取分组信息的回调
    func blueClient(client: BlueClient!, didGetGroupInfo groups: [AnyObject]!) {
        let device = DeviceManager.sharedCoreDataManader.fetchDeviceByMeshAddress(NSNumber(unsignedShort: client.meshAddr))
        let _groups = groups as! [NSNumber]
        var groupList = [Group]()
        for groupId in _groups { 
            var group = GroupManager.sharedCoreDataManader.fetchGroupByIdentify(groupId)
            if group == nil {
                group = GroupManager.sharedCoreDataManader.saveGroup(["identify": groupId])
            }
            groupList.append(group!)
        }
        if groupList.count > 0 {
            device?.groups = NSSet(array: groupList)
        }else {
            device?.groups = nil
        }
        
        DeviceManager.sharedCoreDataManader.saveContext()
        
        checkSeqClient(client)
        
    }

    
    
    //MARK: - Add to Group
    //设置分组
    func add(clients:[BlueClient], toGroup group:UInt8, callBack:(()->Void)?){
        seqSendCmd(CMD_GROUP, clients: clients, data: NSData(bytes: [0x01, group, 0x80], length:3), callBack: callBack)
    }
    //移除分组
    func remove(clients:[BlueClient], fromGroup group:UInt8, callBack:(()->Void)?){
        seqSendCmd(CMD_GROUP, clients: clients, data: NSData(bytes: [0x00, group, 0x80], length:3), callBack: callBack)
    }
    
    
    //MARK: - Set Time
    //设定定时
    func setTime() {
        
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)
        let components = calendar?.components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: NSDate())
        let year = UInt16((components?.year)!)
        let year1 = UInt8(year & 0xff)
        let year2 = UInt8(year >> 8 & 0xff)
        let month = UInt8((components?.month)!)
        let day = UInt8((components?.day)!)
        let hour = UInt8((components?.hour)!)
        let min = UInt8((components?.minute)!)
        let sec = UInt8((components?.second)!)
        
        let bytes = [year1, year2, month, day, hour, min, sec]
        let data = NSData(bytes: bytes, length: 7)
        
        self.meshClient?.sendCmd(UInt8(CMD_SET_TIME), dest: 0xFFFF, withData: data)
    }
    
    //MARK: - sequence send
    //队列发送，发送一条命令，等待相应后，在发送下一条
    private var seqSendClients:[BlueClient] = []
    private var sendData:NSData?
    private var cmdToSend:UInt8?
    private var sendCallBack:(()->Void)?
    private var sendTimer:NSTimer?
    private var timeroutTimer:NSTimer?//单个命令超时的定时器
    
    private func checkSeqClient(client:BlueClient) {
        if client.meshAddr == seqSendClients.first?.meshAddr {
            seqSendClients.removeFirst()
            seqSendNext()
        }
    }
    
    func seqSendNext() {
        if timeroutTimer != nil && timeroutTimer!.valid {
            timeroutTimer?.invalidate()
        }
        if seqSendClients.count > 0 {
            meshClient?.sendCmd(cmdToSend!, dest: (seqSendClients.first?.meshAddr)!, withData: sendData)
            
            timeroutTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(BlueService.cmdTimeOut), userInfo: nil, repeats: false)
        }else {
            sendCallBack?()
            sendCallBack = nil
            seqSendClients = []
            sendCallBack = nil
            cmdToSend = nil
            sendData = nil
            sendTimer = nil
            
            if sendTimer != nil && sendTimer!.valid {
                sendTimer?.invalidate()
            }
        }
    }
    
    func cmdTimeOut() {
        seqSendClients.removeFirst()
        seqSendNext()
    }
    
    func sendTimeOut(timer:NSTimer) {
        if timer.valid {
            timer.invalidate()
        }
        sendCallBack?()
        seqSendClients = []
        sendCallBack = nil
        cmdToSend = nil
        sendData = nil
        sendTimer = nil
    }
    
    func seqSendCmd(cmd:Int32, clients:[BlueClient], data:NSData, callBack:(()->Void)?){

        seqSendClients = clients
        sendData = data
        cmdToSend = UInt8(cmd)
        sendCallBack = callBack
        seqSendNext()
        sendTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(BlueService.sendTimeOut(_:)), userInfo: nil, repeats: false)
    }
    
    //MARK: - Delay Send
    //需要同时发送多个命令的时候，需要每条命令间有延时，比如多灯控5盏灯，每盏灯发送的命令需要有100ms（可调整）的延时，才能保证命令正确送达
    var curData:NSData!
    var curDests:[UInt16]!
    var curCmd:Int32!
    var curIndex = 0
    
    func delaySend(cmd:Int32, dests:[UInt16], data:NSData) {
        curIndex = 0
        curCmd = cmd
        curDests = dests
        curData = data
        sendNext()
    }
    func sendNext() {
        if curIndex < (curDests?.count)! - 1 {
            sendCmd(curCmd, dest: (curDests[curIndex]), data: curData)
            curIndex = curIndex + 1
            performSelector(#selector(BlueService.sendNext), withObject: nil, afterDelay: 0.1)
        }
    }
    
    //MARK: - Get Alarm
    //刷新定时信息
    private var getAlarmCallBack:((data:[UInt16: [Alarm]], finished:Bool) -> Void)?
    private var getAlarmDests:[UInt16]!
    private var alarmMap:[UInt16: [Alarm]] = [:]
    private var getAlarmTimer:NSTimer?
    
    func getAlarm(dests:[UInt16], callback:((data:[UInt16: [Alarm]], finished:Bool) -> Void)?) {
        getAlarmDests = dests
        getAlarmCallBack = callback
        alarmMap = [:]
        getNextAlarm()
    }
    //队列获取
    func getNextAlarm() {
        if getAlarmDests.count == 0 {
            return
        }
        let dest = getAlarmDests.first
        
        let bytes:[UInt8] = [0x10, 0x00]
        let data = NSData(bytes: bytes, length: 2)
        sendCmd(CMD_GET_ALARM, dest: dest!, data: data)
        getAlarmTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(BlueService.checkGetAlarmTimeOut), userInfo: nil, repeats: false)
    }
    func checkGetAlarmTimeOut() {
        if getAlarmTimer != nil && getAlarmTimer!.valid {
            getAlarmTimer?.invalidate()
        }
        if getAlarmDests.count > 0 {
            getAlarmDests.removeFirst()
            getAlarmCallBack?(data: alarmMap, finished: getAlarmDests.count == 0)
            getNextAlarm()
        }
        
    }
    
    //接收到mesh网络发来的定时信息
    func blueClient(client: BlueClient!, didGetAlarm alarm: Alarm) {
        if alarmMap[client.meshAddr] == nil {
            alarmMap[client.meshAddr] = []
        }
        if alarm.event == 0xa5{
            alarmMap[client.meshAddr]?.append(alarm)
            alarmMap[client.meshAddr]?.sortInPlace({ (alarm1, alarm2) -> Bool in
                return alarm1.index > alarm2.index
            })
        }
        
        if alarmMap[client.meshAddr]?.count == Int(alarm.count) {
            if getAlarmTimer != nil && getAlarmTimer!.valid {
                getAlarmTimer?.invalidate()
            }
            getAlarmDests.removeFirst()
            getAlarmCallBack?(data: alarmMap, finished: getAlarmDests.count == 0)
            getNextAlarm()
        }else {
            getAlarmCallBack?(data: alarmMap, finished: false)
        }
    }
    
    
    //MARK: - 获取设备版本
    func refreshVersion() {
        let bytes:[UInt8] = [0x10, 0x11]
        let data = NSData(bytes: bytes, length: 2)
        meshClient?.sendCmd(UInt8(CMD_USER_ALL), dest: 0xffff, withData: data)
    }
    
    //BlueClientDelegate 获取版本信息
    func didRefreshVersion(client: BlueClient!) {
        for device in listDevices {
            if device.meshAddr?.unsignedShortValue == client.meshAddr {
                device.client?.hardwareVersion = client.hardwareVersion
                device.client?.softwareVersion = client.softwareVersion
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationReloadData, object: nil)
            }
            
        }
    }
    
    //MARK: - OTA 登陆
    
    var otaLoginBlock:((success:Bool)-> Void)?
    var otaClient:BlueClient?
    
    func loginForOta(client:BlueClient, block:((success:Bool)-> Void)) {
        if meshClient == client && (meshClient?.isLogin)! {
            block(success:true)
            return
        }
        otaClient = client
        otaLoginBlock = block
        manager.loginWithPwd(AppInfo.shareInfo.userPwd, client: otaClient)
    }
    
    // 发送一个数据包
    var sendBlock:((success:Bool) -> Void)?
    func sendPack(client:BlueClient, pack:NSData, index:UInt, block:((success:Bool) -> Void)) {
        sendBlock = block
        client.sendPack(pack, index: index)
    }
    
    //发送一个包的回调
    func blueClient(client: BlueClient!, didSendPack success: Bool) {
        sendBlock?(success: success)
    }
    
    
    
    //MARK: - Read firmware
    //读取固件信息
    private var readfFirmwareBlock:((firmware:NSData?) -> Void)?
    private var readfFirmwareClient:BlueClient?
    private var readfFirmwareTimer:NSTimer?
    
    func readFirmware(client:BlueClient, block:((firmware:NSData?) -> Void)) {
        readfFirmwareClient = client
        readfFirmwareBlock = block
        client.readFireWare()
        readfFirmwareTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(BlueService.readTimeOut), userInfo: nil, repeats: false)
    }
    
    func blueClient(client: BlueClient!, didReadFirmWare data: NSData!) {
        if client == readfFirmwareClient {
            readfFirmwareBlock?(firmware: data)
            cleanFirmware()
        }
    }
    
    func readTimeOut() {
        readfFirmwareBlock?(firmware: nil)
        cleanFirmware()
        
    }
    
    private func cleanFirmware() {
        readfFirmwareBlock = nil
        readfFirmwareClient = nil
        if readfFirmwareTimer != nil && readfFirmwareTimer!.valid {
            readfFirmwareTimer!.invalidate()
            readfFirmwareTimer = nil
        }
        
    }
}

// MARK: - 发送命令扩展
extension BlueService {
    
    func addGroup(groupId:UInt8, dest:UInt16) {
        
        sendCmd(CMD_GROUP, dest: dest, data: NSData(bytes: [0x01, groupId, 0x80], length:3))
    }
    
    func deleteGroup(groupId:UInt8, dest:UInt16) {
        sendCmd(CMD_GROUP, dest: dest, data: NSData(bytes: [0x00, groupId, 0x80], length:3))
    }
    
    
    
    func switchAllOn() {
        sendCount = sendCount + 1
        sendCmd(CMD_Light_ON_OFF, dest: 0xFFFF, data: NSData(bytes: [UInt8(0x01)], length:1))
        if sendCount <= 3 {
            performSelector(#selector(BlueService.switchAllOn), withObject: nil, afterDelay: 0.1)
        }
    }
    
    func switchAllOff() {
        sendCount = sendCount + 1
        sendCmd(CMD_Light_ON_OFF, dest: 0xFFFF, data: NSData(bytes: [UInt8(0x00)], length:1))
        if sendCount <= 3 {
            performSelector(#selector(BlueService.switchAllOff), withObject: nil, afterDelay: 0.1)
        }
    }
    
    func sendCmd(cmd:Int32, dests:[UInt16], data:NSData) {
        for dest in dests {
           self.meshClient?.sendCmd(UInt8(cmd), dest: dest, withData: data)
        }
    }
    
    func sendCmd(cmd:Int32, dest:UInt16, data:NSData) {
        self.meshClient?.sendCmd(UInt8(cmd), dest: dest, withData: data)
    }
}
