//
//  RefreshHeader.swift
//  BlueLight
//
//  Created by Rail on 5/27/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import Foundation
import MJRefresh


class RefreshHeader: MJRefreshGifHeader {
    override func prepare() {
        super.prepare()
        
        let scal = UIScreen.mainScreen().scale
        let width:CGFloat = 30 * scal
        let margin:CGFloat = 8 * scal
        
        var idleImages = [UIImage]()
        let imageSize = CGSize(width: width, height: width)
        
        let image = UIImage(named: "refresh_pull")
        for i in 0...71 {
            UIGraphicsBeginImageContext(imageSize)
            let ctx = UIGraphicsGetCurrentContext()!
            CGContextScaleCTM(ctx, 1, 1)
            CGContextTranslateCTM(ctx, width / 2, width / 2)
            CGContextRotateCTM(ctx, CGFloat(M_PI * 2) * CGFloat(i) / 72)
            
            CGContextSetFillColorWithColor(ctx, UIColor.colorWithHex(0x999999).CGColor)
            CGContextAddArc(ctx, 0, 0, width / 2, 0, 2 * CGFloat(M_PI), 0); //添加一个圆
            CGContextDrawPath(ctx, .Fill)
            CGContextDrawImage(ctx, CGRect(x: margin / 2 - width / 2, y: margin / 2 - width / 2, width: width - margin, height: width - margin), image!.CGImage)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            idleImages.append(UIImage(CGImage: image!.CGImage!, scale: scal, orientation: .Up))
            UIGraphicsEndImageContext()
        }
        
        setImages(idleImages, duration: 0.5, forState: .Idle)
        
        let refreshingImages = idleImages.reverse() as [UIImage]
        setImages(refreshingImages, duration: 0.5, forState: .Pulling)
        setImages(refreshingImages, duration: 0.5, forState: .Refreshing)
        
    }
}
