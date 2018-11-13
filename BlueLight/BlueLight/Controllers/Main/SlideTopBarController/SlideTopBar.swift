//
//  SlideTopBar.swift
//  SweetCoffee
//
//  Created by Rail on 16/3/17.
//  Copyright © 2016年 Rail. All rights reserved.
//

import UIKit

class SlideTopBar: UIView {
    
    var currentIndex:Int = 0
    
    var titleLabels:[UILabel] = [UILabel]()
    
    var titles:[String]!
    
    var didChangeIndex:((index:Int)->Void)!
    
    var contentView = UIView()
    var textView = UIView()
    
    var colorLayer = CALayer()
    var bottomView = UIView()
    var bottomBackgroundView = UIView()
    
    var titleWidth:CGFloat = 0
    
    override func drawRect(rect: CGRect) {
        contentView.frame = bounds
        addSubview(contentView)
        textView.frame = bounds
        contentView.addSubview(textView)
        
        titleWidth = rect.width / CGFloat(titles.count)
        
        titleLabels.removeAll()
        
        let textlayer = CATextLayer()
        textlayer.frame = bounds
        
        let y = (rect.height - 20) / 2
        for i in 0 ..< titles.count {
            let layer = CATextLayer()
            layer.string = titles[i]
            layer.fontSize = 16.0
            layer.contentsScale = UIScreen.mainScreen().scale
            layer.alignmentMode = kCAAlignmentCenter
            layer.frame = CGRect(x: titleWidth * CGFloat(i), y: y, width: titleWidth, height: titleBarHeight)
            textlayer.addSublayer(layer)
            
            
            let label = UILabel()
            label.tag = i
            label.frame = layer.frame
            label.userInteractionEnabled = true
            addSubview(label)
            titleLabels.append(label)
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SlideTopBar.onTap(_:))))
            
        }
        textView.layer.mask = textlayer
        
        let blackLayer = CALayer()
        blackLayer.frame = bounds
        blackLayer.backgroundColor = UIColor.blackColor().CGColor
        colorLayer.backgroundColor = UIColor.themeColor().CGColor
        colorLayer.frame = CGRect(x: 0, y: 0, width: titleWidth, height: titleBarHeight)
        colorLayer.speed = 100.0
        blackLayer.addSublayer(colorLayer)
        textView.layer.addSublayer(blackLayer)
        
        bottomBackgroundView.frame =  CGRect(x: 0, y: titleBarHeight - 3, width: rect.width, height: 3)
        bottomBackgroundView.backgroundColor = UIColor.colorWithHex(0xbeccd8)
        contentView.addSubview(bottomBackgroundView)
        
        bottomView.frame = CGRect(x: 0, y: titleBarHeight - 3, width: titleWidth, height: 3)
        bottomView.backgroundColor = UIColor.themeColor()
        contentView.addSubview(bottomView)
        
        
        
        
    }
    
    func onTap(tap:UIGestureRecognizer) {
        let index = Int(tap.view!.tag)
        if currentIndex != index {
            currentIndex = index
            didChangeIndex(index:index)
        }
    }
    
    func changeIndex(index:Int) {
        currentIndex = index
        let x = titleWidth * CGFloat(index)
        colorLayer.frame.origin.x = x
        bottomView.frame.origin.x = x
    }
    
    func scrollView(offsetRatio:CGFloat) {
        colorLayer.frame.origin.x = titleWidth * offsetRatio
        let x = titleWidth * offsetRatio
        colorLayer.frame.origin.x = x
        bottomView.frame.origin.x = x
        
    }
    
    
}