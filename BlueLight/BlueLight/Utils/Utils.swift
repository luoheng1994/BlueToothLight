//
//  Utils.swift
//  shandui
//
//  Created by Rail on 5/21/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit


let pi = CGFloat(M_PI)
let pi_3 = CGFloat(M_PI / 3)

//MARK: - tip message 

class Utils {
    
    static var instance:Utils {
        struct Static {
            static let instance: Utils = Utils()
        }
        return Static.instance
    }
    
    init() {
        
        loadingView.backgroundColor = UIColor.blackColor()
        loadingView.alpha = 0
        loadingView.layer.cornerRadius = 8
        loadingView.clipsToBounds = true
        loadingView.frame = CGRect(x: 0, y: 0, width: 130, height: 60)
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        indicator.frame = CGRect(x: 15, y: 15, width: 30, height: 30)
        indicator.startAnimating()
        loadingView.addSubview(indicator)
        loadingLabel.frame = CGRect(x: 45, y: 15, width: 70, height: 30)
        loadingLabel.textColor = UIColor.whiteColor()
        loadingLabel.font = UIFont.systemFontOfSize(14)
        loadingLabel.textAlignment = .Center
        loadingView.addSubview(indicator)
        loadingView.addSubview(loadingLabel)
    }
    
    var tipView = UILabel()
    
    var tipTimer:NSTimer?
    
    func showTip(message: String) {
        
        tipTimer?.invalidate()
        tipTimer = nil
        
        let view = UIApplication.sharedApplication().keyWindow?.rootViewController?.view
        tipView.backgroundColor = UIColor.blackColor()
        tipView.alpha = 0
        tipView.textColor = UIColor.whiteColor()
        tipView.font = UIFont.systemFontOfSize(15)
        tipView.textAlignment = .Center
        tipView.layer.cornerRadius = 8
        tipView.clipsToBounds = true
        
        let str:NSString = message
        let size = str.sizeWithAttributes([NSFontAttributeName: UIFont.systemFontOfSize(15)])
        
        let screenSize = UIScreen.mainScreen().bounds.size
        let width = size.width + 40
        tipView.frame = CGRect(x: 0, y: 0 , width: width, height: 60)
        tipView.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2 + 60)
        tipView.text = message
        view?.addSubview(tipView)
        
        UIView.animateWithDuration(0.25) {
            self.tipView.alpha = 0.9
        }
        tipTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(Utils.hideTipMessage), userInfo: nil, repeats: false)
        
        
    }
    
    @objc func hideTipMessage() {
        UIView.animateWithDuration(0.25, animations: {
            self.tipView.alpha = 0
            }) { (complete) in
                if complete {
                    self.tipView.removeFromSuperview()
                    self.tipTimer = nil
                }
        }
    }
    
    //MARK: Loading
    let loadingView = UIView()
    let loadingLabel = UILabel()
    func showLoading(msg:String?, showBg:Bool) {
        let view = UIApplication.sharedApplication().keyWindow?.rootViewController?.view
        showLoading(msg, showBg: showBg, inView: view)
    }
    
    func showLoading(msg:String?, inView:UIView?) {
        showLoading(msg, showBg: true, inView: inView)
    }
    
    func showLoading(msg:String?, showBg:Bool, inView:UIView?) {
        loadingView.backgroundColor = showBg ? UIColor.blackColor() : UIColor.clearColor()
        inView?.userInteractionEnabled = false
        let screenSize = UIScreen.mainScreen().bounds.size
        inView?.addSubview(loadingView)
        loadingView.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2 + 60)
        loadingLabel.text = msg ?? "连接中"
        UIView.animateWithDuration(0.1) {
            self.loadingView.alpha = 0.7
        }
    }
    
    
    
    func hideLoading() {
        let view = self.loadingView.superview
        view?.userInteractionEnabled = true
        UIView.animateWithDuration(0.1, animations: {
            self.loadingView.alpha = 0
        }) { (complete) in
            if complete {
                self.loadingView.removeFromSuperview()
            }
        }
    }
}

extension Utils {
    class func getRGBFromAngle(angle:CGFloat) -> (red:CGFloat, green:CGFloat, blue:CGFloat) {
        
        var red:CGFloat = 0
        var blue:CGFloat = 0
        var green:CGFloat = 0
        if angle > 0 && angle < pi_3 * 2 {
            blue = angle / pi_3 / 2
            red = 1 - blue
        }else if angle < 0 && angle > -pi_3 * 2 {
            red = angle / pi_3 / 2 + 1
            green = 1 - red
        }else if angle > pi_3 * 2 {
            green = angle / pi_3 / 2 - 1
            blue = 1 - green
        }else if angle < -pi_3 * 2 {
            green = angle / pi_3 / 2 + 2
            blue = 1 - green
        }
        return (red, green, blue)
    }
    
    class func getAngleFrom(red:CGFloat, green:CGFloat, blue:CGFloat) -> CGFloat {
        if red > 0 && blue > 0 {
            return blue * pi_3 * 2
        }else if red > 0 && green >= 0 {
            return (red - 1) * pi_3 * 2
        }else if blue > 0.5 {
            return (green + 1) * pi_3 * 2
        }else {
            return (green - 2) * pi_3 * 2
        }
    }
    
    class func getWarmFromAngle(angle:CGFloat) -> (yellow:CGFloat, white:CGFloat) {
        let _angle = angle < 0 ? -angle : angle
        let yellow = _angle / pi
        return (yellow, 1 - yellow)
        
    }
    
    class func getAngleFrom(yellow:CGFloat, white:CGFloat) -> CGFloat {
        let angle = yellow * pi
        return -angle
    }
    
    
    
    class func convertDisplayColor(hexColor:UInt32, white:UInt32) -> UIColor {
        var red = hexColor >> 16 & 0xFF
        var green = hexColor >> 8 & 0xFF
        var blue = hexColor & 0xFF
        if red > 127 {
            red = 255
            blue = blue * 2
            green = green * 2
        }else if green > 127 {
            green = 255
            blue = blue * 2
            red = red * 2
        }else if blue > 127 {
            blue = 255
            green = green * 2
            red = red * 2
        }
        red = red + (255 - red) * white / 255
        green = green + (255 - green) * white / 255
        blue = blue + (255 - blue) * white / 255
        return UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
    
    class func convertYWToRGB(yellow:UInt8, white:UInt8) -> UIColor {
        let red = (255 * 255 - 11 * CGFloat(yellow)) / 255 / 255
        let green = (255 * 255 - 67 * CGFloat(yellow)) / 255 / 255
        let blue = (255 * 255 - 190 * CGFloat(yellow)) / 255 / 255
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

//MARK: -
func localize(key:String) -> String {
    return NSLocalizedString(key, comment: "");
}

func localize(keys:[String]) -> [String] {
    var locals = [String]()
    for key in keys {
        locals.append(NSLocalizedString(key, comment: ""))
    }
    return locals;
}


