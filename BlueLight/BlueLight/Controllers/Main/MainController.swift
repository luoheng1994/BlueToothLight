//
//  MainController.swift
//  BlueLight
//
//  Created by Rail on 5/24/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class MainController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    
    var slideCtl:SlideTopBarController!
    
    @IBOutlet weak var tabView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        navigationController?.navigationBar.delegate = navigationController
        
        tabView.backgroundColor = UIColor.backgroundColor()
        tabView.layer.shadowColor = UIColor.blackColor().CGColor
        tabView.layer.shadowOffset = CGSize(width: 0, height: -5)
        tabView.layer.shadowRadius = 8
        tabView.layer.shadowOpacity = 0.1
        
        title = localize("蓝牙灯")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "返回", style: .Plain, target: nil, action: nil)
        let titles = localize(["附近", "灯列表", "分组"])
        
        let controllers = [NearbyViewController(style: .Grouped), LightsViewController(style: .Grouped), GroupsViewController(style: .Grouped)]
        
        slideCtl = SlideTopBarController(titles: titles, controllers: controllers)
        slideCtl.topBar.layer.shadowColor = UIColor.blackColor().CGColor
        slideCtl.topBar.layer.shadowOffset = CGSize(width: 0, height: 5)
        slideCtl.topBar.layer.shadowRadius = 8
        slideCtl.topBar.layer.shadowOpacity = 0.1
        automaticallyAdjustsScrollViewInsets = false
        
        slideCtl.view.frame = contentView.bounds
        contentView.addSubview(slideCtl.view)
        addChildViewController(slideCtl)
        
        slideCtl.startScroll = {
            self.hideBtns()
        }
        
        singleSeleceBtn.setTitleColor(UIColor.buttonColor(), forState: [])
        singleSeleceBtn.setTitle("单操作", forState: [])
        singleSeleceBtn.setImage(UIImage(named: "button_single"), forState: [])
        singleSeleceBtn.addTarget(self, action: #selector(MainController.singleSelect), forControlEvents: .TouchUpInside)
        
        
        multiSelectBtn.setTitleColor(UIColor.buttonColor(), forState: [])
        multiSelectBtn.setTitle("组操作", forState: [])
        multiSelectBtn.setImage(UIImage(named: "button_group"), forState: [])
        multiSelectBtn.addTarget(self, action: #selector(MainController.multiSelect), forControlEvents: .TouchUpInside)
        
        switchAllBtn.setTitleColor(UIColor.buttonColor(), forState: [])
        switchAllBtn.setTitle("一键开关", forState: [])
        switchAllBtn.setImage(UIImage(named: "icon_switch_all"), forState: [])
        switchAllBtn.addTarget(self, action: #selector(MainController.switchAll), forControlEvents: .TouchUpInside)
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_settings"), style: .Plain, target: self, action: #selector(MainController.showSettings))
        
    }
    
    override func viewWillAppear(animated: Bool) {
        hideBtns()
    }
    
    @IBOutlet weak var singleSeleceBtn: SubTitleButton!
    
    @IBOutlet weak var multiSelectBtn: SubTitleButton!
    
    @IBOutlet weak var switchAllBtn: SubTitleButton!
    
    var buttons:[UIButton] = []
    
    //MARK: - Action
    
    //一键开关
    func switchAll() {
        let alert = UIAlertController(title: "选择开关", message: "一键开关所有灯", preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "开灯", style: .Destructive, handler: { (action) in
            BlueService.instance.sendCount = 0
            BlueService.instance.switchAllOn()
            
        }))
        alert.addAction(UIAlertAction(title: "关灯", style: .Default, handler: { (action) in
            BlueService.instance.sendCount = 0
            BlueService.instance.switchAllOff()
            
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func singleSelect() {
        let width = UIScreen.mainScreen().bounds.width / 3
        let height = tabView.bounds.height
        
        let ctl = slideCtl.selectController as! SelectableTableViewController
        ctl.selectMode = .Single
        
        let backBtn = SubTitleButton(type: .Custom)
        backBtn.setTitle("返回", forState: [])
        backBtn.setImage(UIImage(named: "icon_back"), forState: [])
        backBtn.setTitleColor(UIColor.colorWithHex(0x69d4eb), forState: [])
        backBtn.addTarget(self, action: #selector(MainController.hideBtns), forControlEvents: .TouchUpInside)
        
        let btn1 = SubTitleButton(type: .Custom)
        btn1.setTitle(ctl.buttonNames[0], forState: [])
        btn1.setImage(UIImage(named: ctl.buttonImages[0]), forState: [])
        btn1.setTitleColor(UIColor.colorWithHex(0x95a9b7), forState: [])
        btn1.addTarget(ctl, action: ctl.actions[0], forControlEvents: .TouchUpInside)
        
        let btn2 = SubTitleButton(type: .Custom)
        btn2.setTitle(ctl.buttonNames[1], forState: [])
        btn2.setImage(UIImage(named: ctl.buttonImages[1]), forState: [])
        btn2.setTitleColor(UIColor.colorWithHex(0x69d4eb), forState: [])
        btn2.addTarget(ctl, action: ctl.actions[1], forControlEvents: .TouchUpInside)
        
        backBtn.frame = CGRect(x: 0, y: 0, width: width, height: height)
        btn1.frame = CGRect(x: width, y: 0, width: width, height: height)
        btn2.frame = CGRect(x: width * 2, y: 0, width: width, height: height)
        
        tabView.addSubview(backBtn)
        tabView.addSubview(btn1)
        tabView.addSubview(btn2)
        
        showBtns([backBtn, btn1, btn2])
    }
    
    func multiSelect() {
        let width = UIScreen.mainScreen().bounds.width / 3
        let height = tabView.bounds.height
        
        let ctl = slideCtl.selectController as! SelectableTableViewController
        ctl.selectMode = .Multi
        let backBtn = SubTitleButton(type: .Custom)
        backBtn.setTitle("返回", forState: [])
        backBtn.setImage(UIImage(named: "icon_back"), forState: [])
        backBtn.setTitleColor(UIColor.colorWithHex(0x69d4eb), forState: [])
        backBtn.addTarget(self, action: #selector(MainController.hideBtns), forControlEvents: .TouchUpInside)
        
        let btn1 = SubTitleButton(type: .Custom)
        btn1.setTitle(ctl.buttonNames[2], forState: [])
        btn1.setImage(UIImage(named: ctl.buttonImages[2]), forState: [])
        btn1.setTitleColor(UIColor.colorWithHex(0x95a9b7), forState: [])
        btn1.addTarget(ctl, action: ctl.actions[2], forControlEvents: .TouchUpInside)
        
        let btn2 = SubTitleButton(type: .Custom)
        btn2.setTitle(ctl.buttonNames[3], forState: [])
        btn2.setImage(UIImage(named: ctl.buttonImages[3]), forState: [])
        btn2.setTitleColor(UIColor.colorWithHex(0x69d4eb), forState: [])
        btn2.addTarget(ctl, action: ctl.actions[3], forControlEvents: .TouchUpInside)
        
        
        backBtn.frame = CGRect(x: 0, y: 0, width: width, height: height)
        btn1.frame = CGRect(x: width, y: 0, width: width, height: height)
        btn2.frame = CGRect(x: width * 2, y: 0, width: width, height: height)
        
        tabView.addSubview(backBtn)
        tabView.addSubview(btn1)
        tabView.addSubview(btn2)
        
        showBtns([backBtn, btn1, btn2])
    }
    
    func showBtns(btns:[UIButton]) {
        tabView.userInteractionEnabled = false
        
        UIView.animateWithDuration(0.1) {
            self.singleSeleceBtn.alpha = 0
            self.multiSelectBtn.alpha = 0
            self.switchAllBtn.alpha = 0
        }
        
        for (index, btn) in btns.enumerate() {
            btn.frame.origin.y = btn.frame.height
            UIView.animateWithDuration(0.25, delay: 0.1 * Double(index), usingSpringWithDamping: 0.75, initialSpringVelocity: 25, options: .CurveEaseOut, animations: {
                btn.frame.origin.y = 0
                
                }, completion: { (finished) in
                    self.tabView.userInteractionEnabled = true
                    self.buttons = btns
            })
        }
    }
    
    func hideBtns() {
        let ctl = slideCtl.selectController as! SelectableTableViewController
        if ctl.selectMode == .None {
            return
        }
        
        tabView.userInteractionEnabled = false
        ctl.selectMode = .None
        
        for (index, btn) in buttons.enumerate() {
            UIView.animateWithDuration(0.1, delay: 0.1 * Double(index), options: .CurveEaseOut, animations: {
                btn.frame.origin.y = btn.frame.height
                }, completion: { (finished) in
                    
            })
        }
        UIView.animateWithDuration(0.25, delay: 0.1, options: UIViewAnimationOptions.CurveLinear, animations: {
            
            self.singleSeleceBtn.alpha = 1
            self.multiSelectBtn.alpha = 1
            self.switchAllBtn.alpha = 1
            }) { (finished) in
                self.tabView.userInteractionEnabled = true
        }
    }
    
    func showSettings() {
        let settingCtl = SettingController(style: .Grouped)
        navigationController?.pushViewController(settingCtl, animated: true)
    }
}
