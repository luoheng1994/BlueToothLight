//
//  AppDelegate.swift
//  BlueLight
//
//  Created by Rail on 5/17/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]? = [:]) -> Bool {
        application.setStatusBarHidden(false, with: .slide)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().setBackgroundImage(UIImage(named: "navi_background"), for: .default)
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        AppInfo.shareInfo.checkInit()
        return true
    }

    
    func applicationWillResignActive(application: UIApplication) {
        
        
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        
        
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        
        
    }
    
    func applicationWillTerminate(application: UIApplication) {
        
        
    }

}

