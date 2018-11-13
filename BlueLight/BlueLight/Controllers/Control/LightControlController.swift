//
//  LightControlController.swift
//  BlueLight
//
//  Created by Rail on 6/8/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit
import SpriteKit
import RESideMenu

class LightControlController: UIViewController, ColorRingDelegate, ColorPanelDelegate, WarmRingDelegate, BrightProgressDelegate {
    
    
    var colorSender:ColorSendAdapter!
    
    var isInit = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initNight()
        
        initLight()
        
        showNight()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LightControlController.scenePicked(_:)), name: NotificationScenePicked, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LightControlController.streamerPicked(_:)), name: NotificationStreamerPicked, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LightControlController.nodeClientStatusChange), name: NodeClientStatusChangeNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if !isInit {
            return
        }
        isInit = false
        if let state:Status = colorSender.currentState {
            switch colorSender.lightType {
            case .RGBW:
                let red = CGFloat(state.r)
                let green = CGFloat(state.g)
                let blue = CGFloat(state.b)
                let white = CGFloat(state.w)
                let bright = CGFloat(state.bright)
                let view = colorView as! ColorPanelView
                view.color = (red/255, green/255, blue/255, white/255)
                self.bright = bright / 100
                
            case .RGB:
                let red = CGFloat(state.r)
                let green = CGFloat(state.g)
                let blue = CGFloat(state.b)
                let bright = CGFloat(state.bright)
                let view = colorView as! ColorRingView
                view.color = (red/255, green/255, blue/255)
                self.bright = bright / 100
            case .YW:
                let yellow = CGFloat(state.r)
                let white = CGFloat(state.g)
                let bright = CGFloat(state.bright)
                let view = colorView as! WarmRingView
                view.color = (yellow/255, 1 - white/255)
                self.bright = bright / 100
            }
            if let bright = colorSender.statusDevice?.bright {
                isOn = bright > 0
            }
        }
        
        nodeClientStatusChange()
    }
    
    func nodeClientStatusChange() {
        if BlueService.instance.nodeClientStatus != .Connected {
            Utils.instance.showLoading("连接中",showBg: isOn, inView: view)
        }else {
            Utils.instance.hideLoading()
        }
    }
    
    var colorTimer:NSTimer?
    var brightTimer:NSTimer?
    override func viewWillAppear(animated: Bool) {
        if isOn {
            navigationController?.navigationBar.setBackgroundImage(UIImage(named: "navi_background"), forBarMetrics: .Default)
        }else {
            navigationController?.navigationBar.setBackgroundImage(UIImage(named: "navi_background_translucent"), forBarMetrics: .Default)
        }
        navigationController?.interactivePopGestureRecognizer?.enabled = false
        colorTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: #selector(LightControlController.timerSendColor), userInfo: nil, repeats: true)
        brightTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: #selector(LightControlController.timerSendBright), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "navi_background"), forBarMetrics: .Default)
        navigationController?.interactivePopGestureRecognizer?.enabled = true
        colorTimer?.invalidate()
        brightTimer?.invalidate()
        
    }
    
    func scenePicked(notification:NSNotification) {
        let scene = notification.userInfo!["scene"] as! Scene
        let color = (scene.color?.unsignedIntValue)!
        switch colorSender.lightType {
        case .RGBW:
            let red = CGFloat(color >> 16 & 0xFF)
            let green = CGFloat(color >> 8 & 0xFF)
            let blue = CGFloat(color & 0xFF)
            let white = CGFloat(color >> 24 & 0xFF)
            let view = colorView as! ColorPanelView
            view.color = (red/255, green/255, blue/255, white/255)
            
        case .RGB:
            let red = CGFloat(color >> 16 & 0xFF)
            let green = CGFloat(color >> 8 & 0xFF)
            let blue = CGFloat(color & 0xFF)
            let view = colorView as! ColorRingView
            view.color = (red/255, green/255, blue/255)
        case .YW:
            let yellow = CGFloat(color >> 8 & 0xFF)
            let white = CGFloat(color & 0xFF)
            let view = colorView as! WarmRingView
            view.color = (yellow/255, 1 - white/255)
        }
        sendCurrnetStatus()
    }
    
    func streamerPicked(notification:NSNotification){
        let streamer = notification.userInfo!["streamer"] as! Streamer
        
        var colors:[UInt32] = []
        let sceneList = streamer.scenes?.array as! [Scene]
        for scene in sceneList {
            colors.append(UInt32((scene.color?.unsignedIntValue)!))
        }
        let speed = streamer.speed?.unsignedShortValue
        colorSender.sendStreamer(colors, speed: UInt8(speed!))

    }
    
    //MARK: - View for night
    
    let nightView = UIView()
    let nightSceneView = SKView()
    let btnOff = UIButton(type: .Custom)
    
    
    
    
    let dControlRadius:CGFloat = 300
    let dBrightHeight:CGFloat = 100
    let dLightOnRadius:CGFloat = 100
    
    func initNight() {
        nightView.frame = view.bounds
        view.addSubview(nightView)
        
        nightSceneView.frame = view.bounds
        nightSceneView.asynchronous = true
        if let nightScene = NightScene(fileNamed: "NightScene") {
            nightScene.size = UIScreen.mainScreen().bounds.size
            nightSceneView.ignoresSiblingOrder = true
            nightScene.scaleMode = .AspectFill
            
            nightSceneView.presentScene(nightScene)
        }
        nightView.addSubview(nightSceneView)
        
        let size = view.bounds.size
        let total = dControlRadius + dBrightHeight + dLightOnRadius
        
        let height = size.height - 164
        var width:CGFloat = height * dLightOnRadius / total
        if width > dLightOnRadius {
            width = dLightOnRadius
        }
        
        btnOff.setImage(UIImage(named: "icon_light_off"), forState : [])
        btnOff.frame = CGRect(x: (size.width - width) / 2, y: size.height - 150, width: width, height: width)
        btnOff.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleBottomMargin]
        nightView.addSubview(btnOff)
        
        btnOff.layer.shadowColor = UIColor.colorWithHex(0xea5ee2).CGColor
        btnOff.layer.shadowRadius = 13
        btnOff.layer.shadowOpacity = 0.8
        btnOff.layer.shadowOffset = CGSize.zero
        btnOff.addTarget(self, action: #selector(LightControlController.turnOn), forControlEvents: .TouchUpInside)
        btnOff.hidden = true
    }
    
    
    //MARK: - View for light on
    let lightView = UIView()
    let bottomView = UIView()
    let brightProgress = BrightProgressView()
    let btnOn = UIButton(type: .Custom)
    var colorView:UIView!
    func initLight() {
        
        
        
        //Custom Tabbar
        let size = view.bounds.size
        bottomView.frame = CGRect(x: 0, y: size.height - 100, width: size.width, height: 100)
        lightView.frame = view.bounds
        lightView.backgroundColor = UIColor.colorWithHex(0xebebeb)
        view.addSubview(lightView)
        let bottomTitles = ["保存场景", "场景", "流光" , "定时"]
        let bottomImages = ["icon_scene_save", "icon_scene", "icon_glitter", "icon_timer"]
        let bottomActions = [ #selector(LightControlController.saveScene),
                             #selector(LightControlController.showScene),
                             #selector(LightControlController.startStreamer),
                             #selector(LightControlController.setTimer)]
        
        let btnWidth = size.width / 4
        for index in 0 ..< bottomTitles.count {
            let title = bottomTitles[index]
            let imageName = bottomImages[index]
            let action = bottomActions[index]
            
            let btn = SubTitleButton(type: .Custom)
            btn.setTitle(title, forState: [])
            btn.setTitleColor(UIColor.buttonColor(), forState: [])
            btn.setImage(UIImage(named: imageName), forState: [])
            btn.frame = CGRect(x: btnWidth * CGFloat(index), y: 0, width: btnWidth, height: 100)
            btn.addTarget(self, action: action, forControlEvents: .TouchUpInside)
            bottomView.addSubview(btn)
        }
        
        
        
        let total = dControlRadius + dBrightHeight + dLightOnRadius
        
        let height = size.height - 164
        var controlRadius:CGFloat = height * dControlRadius / total
        if controlRadius > dControlRadius {
            controlRadius = dControlRadius
        }
        var brightHeight:CGFloat = height * dBrightHeight / total
        if brightHeight > dBrightHeight {
            brightHeight = dBrightHeight
        }
        var lightOnRadius:CGFloat = height * dLightOnRadius / total
        if lightOnRadius > dLightOnRadius {
            lightOnRadius = dLightOnRadius
        }
        
        let top:CGFloat = 64
        
        let margin = (size.height - 164 - controlRadius - brightHeight - lightOnRadius) / 3
        
        switch colorSender.lightType {
        case .RGBW:
            let panelView = ColorPanelView()
            panelView.delegate = self
            colorView = panelView
        case .RGB:
            let panelView = ColorRingView()
            panelView.delegate = self
            colorView = panelView
        default:
            let panelView = WarmRingView()
            panelView.delegate = self
            colorView = panelView
        }
        
        colorView.frame = CGRect(x: (size.width - controlRadius) / 2, y: margin + top, width: controlRadius, height: controlRadius)
        
        brightProgress.frame = CGRect(x: (size.width - controlRadius) / 2, y: controlRadius + margin + top, width: controlRadius, height: brightHeight)
        brightProgress.delegate = self
        
        btnOn.setImage(UIImage(named: "icon_light_on"), forState: [])
        btnOn.frame = CGRect(x: (size.width - lightOnRadius) / 2, y: controlRadius + margin * 2 + brightHeight + top, width: lightOnRadius, height: lightOnRadius)
        btnOn.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleBottomMargin]
        
        btnOn.layer.shadowColor = UIColor.colorWithHex(0x207bca).CGColor
        btnOn.layer.shadowRadius = 8
        btnOn.layer.shadowOpacity = 0.8
        btnOn.layer.shadowOffset = CGSize(width: 5, height: 5)
        btnOn.addTarget(self, action: #selector(LightControlController.turnOff), forControlEvents: .TouchUpInside)
        btnOff.frame = btnOn.frame
        
        lightView.addSubview(brightProgress)
        lightView.addSubview(btnOn)
        lightView.addSubview(bottomView)
        lightView.addSubview(colorView)
        
        lightView.hidden = true
    }
    
    //MARK: - Button Action
    
    func saveScene() {
        let lightType = colorSender.lightType
        var color:UInt32 = 0x000000
        switch lightType {
        case .RGBW:
            let view = colorView as! ColorPanelView
            let _color = view.realColor
            let red = UInt32(_color.red * 255) << 16 & 0xFF0000
            let green = UInt32(_color.green * 255) << 8 & 0xFF00
            let blue = UInt32(_color.blue * 255) & 0xFF
            let white = UInt32(_color.white * 255) << 24 & 0xFF000000
            color = red + green + blue + white
        case .RGB:
            let view = colorView as! ColorRingView
            let _color = view.color
            let red = UInt32(_color.red * 255) << 16 & 0xFF0000
            let green = UInt32(_color.green * 255) << 8 & 0xFF00
            let blue = UInt32(_color.blue * 255) & 0xFF
            color = red + green + blue
        default:
            let view = colorView as! WarmRingView
            let _color = view.color
            
            let yellow = UInt32(_color.yellow * 255) << 8 & 0xFF00
            let white = UInt32(_color.white * 255) & 0xFF
            color = yellow + white
        }
        SceneManager.sharedCoreDataManader.saveScene(["type":NSNumber(integer:lightType.rawValue),
                                                           "color":NSNumber(unsignedInt:UInt32(color))])
        Utils.instance.showTip("保存成功")
    }
    
    
    func showScene() {
        let ctl = SceneController()
        ctl.lightType = colorSender.lightType
        navigationController?.pushViewController(ctl, animated: true)
    }
    
    func startStreamer() {
        let ctl = StreamerController()
        ctl.sender = colorSender
        navigationController?.pushViewController(ctl, animated: true)
    }
    
    func setTimer() {
        let ctl = AlarmController()
        ctl.colorSender = colorSender
        navigationController?.pushViewController(ctl, animated: true)
    }
    
    //MARK: - Animation
    
    func showLight() {
        if lightView.hidden == false {
            return
        }
        
        view.userInteractionEnabled = false
        nightSceneView.paused = true
        
        lightView.hidden = false
        lightView.alpha = 0
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "navi_background"), forBarMetrics: .Default)
        
        let screenHeight = UIScreen.mainScreen().bounds.height
        
        UIView.animateWithDuration(0.2, animations: {
            self.nightView.alpha = 0
            self.lightView.alpha = 1
            
            }) { (finished) in
                self.nightView.hidden = true
        }
        
        let originBottomViewY = bottomView.frame.origin.y
        bottomView.frame.origin.y = screenHeight + bottomView.frame.height
        bottomView.alpha = 0
        let originColorViewY = colorView.frame.origin.y
        colorView.frame.origin.y = 0
        colorView.alpha = 0
        
        UIView.animateWithDuration(0.25, delay: 0.2, options: .CurveEaseOut, animations: {
            self.bottomView.frame.origin.y = originBottomViewY
            self.bottomView.alpha = 1
            
            self.colorView.frame.origin.y = originColorViewY
            self.colorView.alpha = 1
            }, completion: nil)
        
//        let originBtnOnY = btnOn.frame.origin.y
//        btnOn.frame.origin.y = screenHeight + btnOn.frame.height
//        UIView.animateWithDuration(0.25, delay: 0.3, options: .CurveEaseInOut, animations: {
//            self.btnOn.frame.origin.y = originBtnOnY
//            }, completion: nil)
        
        let originBrightProgressY = brightProgress.frame.origin.y
        brightProgress.frame.origin.y = 100
        brightProgress.alpha = 0
        UIView.animateWithDuration(0.25, delay: 0.3, options: .CurveEaseOut, animations: {
            self.brightProgress.frame.origin.y = originBrightProgressY
            self.brightProgress.alpha = 1
        }) {finished in
            if finished {
                self.view.userInteractionEnabled = true
            }
        }
    }
    
    func showNight() {
        btnOff.hidden = false
        if nightView.hidden == false {
            return
        }
        
        view.userInteractionEnabled = false
        
        nightView.hidden = false
        nightView.alpha = 0
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "navi_background_translucent"), forBarMetrics: .Default)
        let screenHeight = UIScreen.mainScreen().bounds.height
        
        let originBottomViewY = bottomView.frame.origin.y
        bottomView.alpha = 1
        let originColorViewY = colorView.frame.origin.y
        colorView.alpha = 1
        
        UIView.animateWithDuration(0.25, delay: 0, options: .CurveEaseOut, animations: {
            self.bottomView.frame.origin.y = screenHeight + self.bottomView.frame.height
            self.bottomView.alpha = 0
            
            self.colorView.frame.origin.y = 0
            self.colorView.alpha = 0
        }) {finished in
            self.bottomView.frame.origin.y = originBottomViewY
            self.colorView.frame.origin.y = originColorViewY
        }
        
        let originBrightProgressY = brightProgress.frame.origin.y
        brightProgress.alpha = 1
        UIView.animateWithDuration(0.25, delay: 0.1, options: .CurveEaseOut, animations: {
            self.brightProgress.frame.origin.y = 100
            self.brightProgress.alpha = 0
        }) {finished in
            if finished {
                self.brightProgress.frame.origin.y = originBrightProgressY
            }
        }
        UIView.animateWithDuration(0.25, delay: 0.2, options: .CurveEaseOut, animations: {
            
            self.lightView.alpha = 0
            self.nightView.alpha = 1
        }) { (finished) in
            self.nightSceneView.paused = false
            self.lightView.hidden = true
            self.view.userInteractionEnabled = true
        }
        
    }
    
    //MARK: Status
    var isOn = false {
        didSet {
            if isOn {
                showLight()
            }else {
                showNight()
            }
        }
    }
    
    var bright:CGFloat {
        get {
            if isOn {
                return brightProgress.value * 0.8 + 0.2
            }else {
                return 0
            }
        }
        set {
            if newValue < 0.2 {
                brightProgress.value = 0
            }else {
                brightProgress.value = (newValue - 0.2) / 0.8
            }
        }
    }
    
    //MARK: Action
    
    
    func turnOn() {
        isOn = true
        colorSender.sendLightOn()
    }
    
    func turnOff() {
        isOn = false
        colorSender.sendLightOff()
    }
    
    var sendingColor = false
    var sendingBright = false
    
    func timerSendBright() {
        if sendingBright {
            colorSender.sendLum(bright)
        }
    }
    
    func timerSendColor() {
        if sendingColor {
            sendCurrnetStatus()
        }
    }
    
    func sendCurrnetStatus() {
        switch colorSender.lightType {
        case .RGBW:
            let view = colorView as! ColorPanelView
            let color = view.color
            colorSender.send(color.red, green: color.green, blue: color.blue, white: color.white)
        case .RGB:
            let view = colorView as! ColorRingView
            let color = view.color
            colorSender.send(color.red, green: color.green, blue: color.blue)
        default:
            let view = colorView as! WarmRingView
            let color = view.color
            colorSender.send(color.yellow, white: color.white)
        }
    }
    
    //MARK: ColorRingDelegate
    
    func colorRingView(view: ColorRingView, startChangeRed red: CGFloat, green: CGFloat, blue: CGFloat) {
        sendingColor = true
        sendCurrnetStatus()
    }
    
    func colorRingView(view: ColorRingView, didChangeRed red: CGFloat, green: CGFloat, blue: CGFloat) {
        
        
    }
    
    func colorRingView(view: ColorRingView, endChangeRed red: CGFloat, green: CGFloat, blue: CGFloat) {
        sendingColor = false
        sendCurrnetStatus()
    }
    
    //MARK: ColorPanelDelegate
    
    func colorPanelView(view: ColorPanelView, startChangeRed red: CGFloat, green: CGFloat, blue: CGFloat, white: CGFloat) {
        sendingColor = true
        sendCurrnetStatus()
        
    }
    
    func colorPanelView(view: ColorPanelView, didChangeRed red: CGFloat, green: CGFloat, blue: CGFloat, white: CGFloat) {
        
    }
    
    func colorPanelView(view: ColorPanelView, endChangeRed red: CGFloat, green: CGFloat, blue: CGFloat, white: CGFloat) {
        sendingColor = false
        sendCurrnetStatus()
        
    }
    
    //MARK: WarmRingDelegate
    
    func warmRingView(view: WarmRingView, startChangeYellow yellow: CGFloat, white: CGFloat) {
        sendingColor = true
        sendCurrnetStatus()
        
    }
    
    func warmRingView(view: WarmRingView, didChangeYellow yellow: CGFloat, white: CGFloat) {
        
        
    }
    
    func warmRingView(view: WarmRingView, endChangeYellow yellow: CGFloat, white: CGFloat) {
        sendingColor = false
        sendCurrnetStatus()
    }
    
    //MARK: BrightProgressDelegate
    func brightProgress(progress: BrightProgressView, startChangeValue value: CGFloat) {
        sendingBright = true
        colorSender.sendLum(bright)
        
    }
    
    func brightProgress(progress: BrightProgressView, didChangeValue value: CGFloat) {
        
    }
    
    func brightProgress(progress: BrightProgressView, endChangeValue value: CGFloat) {
        sendingBright = false
        colorSender.sendLum(bright)
        
    }
    
}
