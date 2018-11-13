//
//  ColorRingView.swift
//  BlueLight
//
//  Created by Rail on 6/10/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

protocol ColorRingDelegate:NSObjectProtocol {
    func colorRingView(view:ColorRingView, startChangeRed red:CGFloat, green:CGFloat, blue:CGFloat)
    func colorRingView(view:ColorRingView, didChangeRed red:CGFloat, green:CGFloat, blue:CGFloat)
    func colorRingView(view:ColorRingView, endChangeRed red:CGFloat, green:CGFloat, blue:CGFloat)
    
}

class ColorRingView: UIView {
    
    weak var delegate:ColorRingDelegate?
    
    var borderMargin:CGFloat = 20
    
    let contetView = UIView()
    
    private let backgroundView = UIView()
    private let backgroundImageView = UIImageView()
    private let centerView = UIImageView()
    private let centerViewWidth:CGFloat = 80
    
    private var currentAngle:CGFloat! {
        didSet {
            redraw()
        }
    }
    private var _color:(red:CGFloat, green:CGFloat, blue:CGFloat) = (0, 0, 0)
    var color:(red:CGFloat, green:CGFloat, blue:CGFloat) {
        get {
            return _color
        }
        set {
            _color = newValue
            currentAngle = Utils.getAngleFrom(_color.red, green: _color.green, blue: _color.blue)
        }
    }
    
    override func didMoveToSuperview() {
        multipleTouchEnabled = false
        
        addSubview(backgroundImageView)
        addSubview(backgroundView)
        addSubview(contetView)
        addSubview(centerView)
        
        backgroundColor = UIColor.clearColor()
        contetView.backgroundColor = UIColor.clearColor()
        backgroundView.backgroundColor = UIColor.clearColor()
        
        
        contetView.frame = bounds
        backgroundView.frame = bounds
        
        
        backgroundImageView.frame = CGRect(x: borderMargin, y: borderMargin, width: frame.width - borderMargin * 2, height: frame.height - borderMargin * 2)
        backgroundImageView.image = UIImage(named: "bg_color_ring")
        backgroundImageView.layer.shadowColor = UIColor.blackColor().CGColor
        backgroundImageView.layer.shadowRadius = 4
        backgroundImageView.layer.shadowOpacity = 0.3
        backgroundImageView.layer.shadowOffset = CGSizeZero
        
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext();
        CGContextBeginPath(ctx)
        CGContextSetLineWidth(ctx, 3)
        CGContextSetStrokeColorWithColor(ctx, UIColor.colorWithHex(0x63d2f0).CGColor)
        CGContextAddArc(ctx, frame.width / 2, frame.height / 2, frame.width / 2 - 1.5, 0, pi * 2, 1)
        CGContextStrokePath(ctx)
        backgroundView.layer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
        
        centerView.image = UIImage(named: "bg_center")
        centerView.layer.shadowColor = UIColor.blackColor().CGColor
        centerView.layer.shadowRadius = 1
        centerView.layer.shadowOpacity = 0.5
        centerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        centerView.layer.cornerRadius = centerViewWidth / 2
        centerView.frame = CGRect(x: frame.width / 2 - centerViewWidth / 2, y: frame.height / 2 - centerViewWidth / 2, width: centerViewWidth, height: centerViewWidth)
        color = (1, 0, 0)
    }
    
    func redraw() {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()
        
        let radius = frame.width / 2 - 35
        let iconRadius:CGFloat = 10
        let point = CGPoint(x: frame.width / 2 + radius * cos(currentAngle), y: frame.height / 2 + radius * sin(currentAngle))
        CGContextBeginPath(ctx)
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextAddArc(ctx, point.x, point.y, iconRadius, 0, pi * 2, 1)
        CGContextFillPath(ctx)
        
        CGContextBeginPath(ctx)
        CGContextSetLineWidth(ctx, 2)
        CGContextSetStrokeColorWithColor(ctx, UIColor.colorWithHex(0xdcdcdc).CGColor)
        CGContextAddArc(ctx, point.x, point.y, iconRadius - 1, 0, pi * 2, 1)
        CGContextStrokePath(ctx)
        contetView.layer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
    }
    
    //MARK: - Touch Action
    
    private var touching = false
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let touchPoint = touch.locationInView(self)
        
        if CGRectContainsPoint(centerView.frame, touchPoint) {
            return
        }
        touching = true
        
        currentAngle = atan2(touchPoint.y - frame.height / 2, touchPoint.x - frame.width / 2)
        _color = Utils.getRGBFromAngle(currentAngle)
        delegate?.colorRingView(self, startChangeRed: color.red, green: color.green, blue: color.blue)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if touching {
            
            let touch = touches.first!
            let touchPoint = touch.locationInView(self)
            currentAngle = atan2(touchPoint.y - frame.height / 2, touchPoint.x - frame.width / 2)
            
            _color = Utils.getRGBFromAngle(currentAngle)
            delegate?.colorRingView(self, didChangeRed: color.red, green: color.green, blue: color.blue)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if touching {
            let touch = touches.first!
            let touchPoint = touch.locationInView(self)
            currentAngle = atan2(touchPoint.y - frame.height / 2, touchPoint.x - frame.width / 2)
            _color = Utils.getRGBFromAngle(currentAngle)
            delegate?.colorRingView(self, endChangeRed: color.red, green: color.green, blue: color.blue)
            touching = false
        }
    }
    
    
    
}