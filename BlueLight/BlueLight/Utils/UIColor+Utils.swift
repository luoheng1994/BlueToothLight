//
//  UIColor+Utils.swift
//  SweetCoffee
//
//  Created by Rail on 16/3/16.
//  Copyright © 2016年 Rail. All rights reserved.
//

import UIKit

extension UIColor {
    
    public class func colorWithHex(hexValue:UInt32, alpha:CGFloat) -> UIColor {
        return UIColor(red: (CGFloat)((hexValue & 0xFF0000) >> 16) / 255.0,
                       green: (CGFloat)((hexValue & 0xFF00) >> 8) / 255.0,
                       blue: (CGFloat)(hexValue & 0xFF) / 255.0,
                       alpha: alpha)
    }
    
    public class func colorWithHex(hexValue:UInt32) -> UIColor {
        return colorWithHex(hexValue, alpha: 1.0);
    }
    
    public class func themeColor() -> UIColor {
        return colorWithHex(0x499bf5);
    }
    
    public class func buttonColor() -> UIColor {
        return colorWithHex(0x69d4eb)
    }
    
//    public class func buttonDisableTextColor() -> UIColor {
//        return colorWithHex(0x73b3e1)
//    }
    
    public class func backgroundColor() -> UIColor {
        return colorWithHex(0xf3fafe)
    }
    
    public class func bewitchedTree() -> UIColor {
        return colorWithHex(0x19caad)
    }
    
    public class func mysticalGreen() -> UIColor {
        return colorWithHex(0x8cc7b5)
    }
    
    public class func lightHeartBlue() -> UIColor {
        return colorWithHex(0xa0eee1)
    }
    
    public class func glassGall() -> UIColor {
        return colorWithHex(0xbee7e9)
    }
    
    public class func sillyFizz() -> UIColor {
        return colorWithHex(0xbeedc7)
    }
    
    public class func brainSand() -> UIColor {
        return colorWithHex(0xd6d5b7)
    }
    
    public class func mustardAddicted() -> UIColor {
        return colorWithHex(0xd1ba74)
    }
    
    public class func magicPowder() -> UIColor {
        return colorWithHex(0xe6ceac)
    }
    
    public class func trueBlush() -> UIColor {
        return colorWithHex(0xecad9e)
    }
    
    public class func merryCranesbill() -> UIColor {
        return colorWithHex(0xf4606c)
    }
    
    public class func imageFromColor(color:UIColor, size:CGSize) -> UIImage{
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
}
