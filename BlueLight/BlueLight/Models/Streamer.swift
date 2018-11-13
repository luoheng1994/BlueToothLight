//
//  Streamer.swift
//  BlueLight
//
//  Created by Rail on 7/7/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Streamer)
class Streamer: NSManagedObject {
    
    var _image:UIImage?
    var displayImage:UIImage! {
        get {
            if _image != nil {
                return _image
            }
            var colors:[CGColor] = []
            let sceneList = scenes?.array as? [Scene] ?? []
            var locations:[CGFloat] = []
            let step = CGFloat(1) / CGFloat(sceneList.count - 1)
            for (index, scene) in sceneList.enumerated() {
                colors.append(scene.rgbColor.cgColor)
                locations.append(step * CGFloat(index))
            }
            
            let size = CGSize(width: 80, height: 80)
            UIGraphicsBeginImageContext(size)
            let context = UIGraphicsGetCurrentContext()!
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)
            
            let startPoint = CGPoint(x: 0, y: 0)
            let endPoint = CGPoint(x: 80, y: 80)
            
            context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: []);
            _image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return _image
        }
    }
}

