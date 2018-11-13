//
//  LightControlRootController.swift
//  BlueLight
//
//  Created by Rail on 6/15/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit
import RESideMenu

class LightControlRootController: RESideMenu, RESideMenuDelegate {
    
    var colorSender:ColorSendAdapter!

    
    override func viewDidLoad() {
        
        title = colorSender.displayTitle
        parallaxEnabled = false
        scaleContentView = true
        contentViewScaleValue = 0.9
        scaleMenuView = false
        contentViewShadowEnabled = true
        contentViewShadowRadius = 4.5
        
        let contentCtl = LightControlController()
        contentCtl.colorSender = colorSender
        contentViewController = contentCtl
        
        let rightCtl = SideListController()
        rightCtl.devices = colorSender.devices
        rightMenuViewController = rightCtl
        delegate = self
        
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_menu"), style: .Plain, target: self, action: #selector(LightControlRootController.showList))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "返回", style: .Plain, target: nil, action: nil)
        
    }
    
    override func navigationShouldPopOnBackButton() -> Bool {
        
        return true
    }
    
    
    //MARK: Action
    
    func showList() {
        presentRightMenuViewController()
    }
    
    //MARK: RESideMenuDelegate
    func sideMenu(sideMenu: RESideMenu!, willHideMenuViewController menuViewController: UIViewController!) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func sideMenu(sideMenu: RESideMenu!, willShowMenuViewController menuViewController: UIViewController!) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

}
