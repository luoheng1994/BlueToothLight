//
//  UIViewController+BackButtonHandler.swift
//  Solenoid
//
//  Created by Rail on 2/17/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit
extension UIViewController {
    
    public func navigationShouldPopOnBackButton() -> Bool {
        return true
    }
}

extension UINavigationController: UINavigationBarDelegate {
    public func navigationBar(navigationBar: UINavigationBar, shouldPopItem item: UINavigationItem) -> Bool {
        if viewControllers.count < navigationBar.items?.count {
            return true
        }
        if topViewController!.navigationShouldPopOnBackButton() {
            dispatch_async(dispatch_get_main_queue(), { 
                self.popViewControllerAnimated(true)
                
            })
        }else {
            for subview in navigationBar.subviews {
                if (subview.alpha < 1) {
                    UIView.animateWithDuration(0.25, animations: { () -> Void in
                        subview.alpha = 1
                    })
                }
            }
        }
        
        return false
    }
    
    func hideNavigationBarItems() {
        for subview in navigationBar.subviews {
            if subview is UIButton {
                subview.hidden = true
            }
        }
    }
    
    func showNavigationBarItems() {
        for subview in navigationBar.subviews {
            if subview is UIButton {
                subview.hidden = false
            }
        }
    }
}
