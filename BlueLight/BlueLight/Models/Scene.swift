//
//  Scene.swift
//  BlueLight
//
//  Created by Rail on 7/7/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Scene)
class Scene: NSManagedObject {

    var _image:UIImage?
    var displayImage:UIImage! {
        get {
            if _image != nil {
                return _image
            }
            let realColor = rgbColor
            _image = UIColor.imageFromColor(color: realColor!, size: CGSize(width: 80, height: 80))
            return _image
        }
    }
    
    
    var rgbColor:UIColor! {
        get {
            let lightType = BlueLightType(rawValue: (type?.intValue)!)!
            let hexColor:UInt32 = (color?.uint32Value)!
            var realColor = UIColor.white
            switch lightType {
            case .RGBW:
                let white = hexColor >> 24 & 0xFF
                realColor = Utils.convertDisplayColor(hexColor: hexColor & 0xFFFFFF, white: white)
            case .RGB:
                realColor = Utils.convertDisplayColor(hexColor: hexColor & 0xFFFFFF, white: 0)
            default:
                let yellow = UInt8(hexColor >> 8 & 0xff)
                let white = UInt8(hexColor & 0xff)
                realColor = Utils.convertYWToRGB(yellow: yellow, white: white)
                
            }
            return realColor
        }
    }
}

