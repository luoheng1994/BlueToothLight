//
//  WarmRingView.swift
//  BlueLight
//
//  Created by Rail on 6/10/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

protocol WarmRingDelegate:NSObjectProtocol {
    func warmRingView(view:WarmRingView, startChangeYellow yellow:CGFloat, white:CGFloat)
    func warmRingView(view:WarmRingView, didChangeYellow yellow:CGFloat, white:CGFloat)
    func warmRingView(view:WarmRingView, endChangeYellow yellow:CGFloat, white:CGFloat)
    
}

class WarmRingView: UIView {
    
    weak var delegate:WarmRingDelegate?
    
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
    private var _color:(yellow:CGFloat, white:CGFloat) = (0, 1)
    var color:(yellow:CGFloat, white:CGFloat) {
        get {
            return _color
        }
        set {
            _color = newValue
            currentAngle = Utils.getAngleFrom(_color.yellow, white: _color.white)
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
        backgroundImageView.image = UIImage(named: "bg_warm_ring")
        backgroundImageView.layer.shadowColor = UIColor.blackColor().CGColor
        backgroundImageView.layer.shadowRadius = 4
        backgroundImageView.layer.shadowOpacity = 0.3
        backgroundImageView.layer.shadowOffset = CGSizeZero
        
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext();
        CGContextBeginPath(ctx)
        CGContextSetLineWidth(ctx, 3)
        CGContextSetStrokeColorWithColor(ctx, UIColor.colorWithHex(0xf6c954).CGColor)
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
        color = (0 ,1)
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
        _color = Utils.getWarmFromAngle(currentAngle)
        delegate?.warmRingView(self, startChangeYellow: _color.yellow, white: _color.white)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if touching {
            
            let touch = touches.first!
            let touchPoint = touch.locationInView(self)
            currentAngle = atan2(touchPoint.y - frame.height / 2, touchPoint.x - frame.width / 2)
            
            _color = Utils.getWarmFromAngle(currentAngle)
            delegate?.warmRingView(self, didChangeYellow: _color.yellow, white: _color.white)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if touching {
            let touch = touches.first!
            let touchPoint = touch.locationInView(self)
            currentAngle = atan2(touchPoint.y - frame.height / 2, touchPoint.x - frame.width / 2)
            _color = Utils.getWarmFromAngle(currentAngle)
            delegate?.warmRingView(self, endChangeYellow: _color.yellow, white: _color.white)
            touching = false
        }
    }
    
}