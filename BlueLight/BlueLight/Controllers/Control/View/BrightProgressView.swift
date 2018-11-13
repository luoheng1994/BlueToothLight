//
//  BrightProgressView.swift
//  BlueLight
//
//  Created by Rail on 6/10/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

protocol BrightProgressDelegate:NSObjectProtocol {
    
    func brightProgress(progress:BrightProgressView, startChangeValue value:CGFloat)
    func brightProgress(progress:BrightProgressView, didChangeValue value:CGFloat)
    func brightProgress(progress:BrightProgressView, endChangeValue value:CGFloat)
    
}

class BrightProgressView: UIView {
    
    weak var delegate:BrightProgressDelegate?
    
    let contentView = UIView()
    
    var onColor = UIColor.colorWithHex(0x5ad7ee)
    var offColor = UIColor.colorWithHex(0xdcdcdc)
    var selectColor = UIColor.colorWithHex(0x3695c4)
    
    
    var border:CGFloat = 10
    var iconRadius:CGFloat = 10
    
    private let angleMax = CGFloat(M_PI_2)
    private var circleCenter:CGPoint!
    private var radius:CGFloat!
    
    private var startAngle:CGFloat!
    private var endAngle:CGFloat!
    private var currentAngle:CGFloat! {
        didSet {
            var angle = angleMax / 2 + CGFloat(M_PI_2) - currentAngle
            if angle < 0 {
                angle = 0
                currentAngle = angleMax / 2 + CGFloat(M_PI_2)
            }else if angle > angleMax {
                angle = angleMax
                currentAngle = CGFloat(M_PI_2) - angleMax / 2
            }
            _value = angle / angleMax
            //            NSLog("\(_value)")
            redraw()
        }
    }
    
    private let drawLayer = CALayer()
    
    private var _value:CGFloat = 0.5
    var value:CGFloat {
        get {
            return _value
        }
        set {
            _value = newValue
            let angle = _value * angleMax
            currentAngle = angleMax / 2 + CGFloat(M_PI_2) - angle
        }
        
    }
    
    override func didMoveToSuperview() {
        let centerHeight = (frame.width / 2 - iconRadius) / tan(angleMax / 2)
        circleCenter = CGPoint(x: frame.width / 2, y: -centerHeight + iconRadius)
        radius = (frame.width / 2 - iconRadius) / sin(angleMax / 2)
        
        //        drawLayer.beginTime = CACurrentMediaTime()
        //        drawLayer.speed = 2.0
        //        drawLayer.doubleSided = false
        contentView.layer.addSublayer(drawLayer)
        
        contentView.backgroundColor = UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
        startAngle = CGFloat(M_PI_2) + angleMax / 2
        endAngle = CGFloat(M_PI_2) - angleMax / 2
        value = 0.5
        
        addSubview(contentView)
    }
    
    override func drawRect(rect: CGRect) {
        contentView.frame = rect
        drawLayer.frame = rect
    }
    
    func redraw() {
        let rect = bounds
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext();
        CGContextBeginPath(ctx)
        CGContextSetLineWidth(ctx, border)
        CGContextSetStrokeColorWithColor(ctx, onColor.CGColor)
        CGContextAddArc(ctx, circleCenter.x, circleCenter.y, radius, currentAngle, startAngle, 0)
        CGContextStrokePath(ctx)
        
        CGContextBeginPath(ctx)
        CGContextSetLineWidth(ctx, border)
        CGContextSetStrokeColorWithColor(ctx, offColor.CGColor)
        CGContextAddArc(ctx, circleCenter.x, circleCenter.y, radius, endAngle, currentAngle, 0)
        CGContextStrokePath(ctx)
        
        CGContextBeginPath(ctx)
        CGContextSetFillColorWithColor(ctx, onColor.CGColor)
        CGContextAddArc(ctx, iconRadius, iconRadius, iconRadius - 1.5, 0, CGFloat(M_PI) * 2, 1)
        CGContextFillPath(ctx)
        
        CGContextBeginPath(ctx)
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextAddArc(ctx, rect.width - iconRadius, iconRadius, iconRadius, 0, CGFloat(M_PI) * 2, 1)
        CGContextFillPath(ctx)
        
        CGContextBeginPath(ctx)
        CGContextSetLineWidth(ctx, 3)
        CGContextSetStrokeColorWithColor(ctx, offColor.CGColor)
        CGContextAddArc(ctx, rect.width - iconRadius, iconRadius, iconRadius - 1.5, 0, CGFloat(M_PI) * 2, 1)
        CGContextStrokePath(ctx)
        
        let point = CGPoint(x: circleCenter.x + radius * sin(CGFloat(M_PI_2) - currentAngle), y: circleCenter.y + radius * cos(CGFloat(M_PI_2) - currentAngle))
        
        CGContextBeginPath(ctx)
        CGContextSetFillColorWithColor(ctx, UIColor.whiteColor().CGColor)
        CGContextAddArc(ctx, point.x, point.y, iconRadius, 0, CGFloat(M_PI) * 2, 1)
        CGContextFillPath(ctx)
        
        CGContextBeginPath(ctx)
        CGContextSetLineWidth(ctx, 3)
        CGContextSetStrokeColorWithColor(ctx, selectColor.CGColor)
        CGContextAddArc(ctx, point.x, point.y, iconRadius - 1.5, 0, CGFloat(M_PI) * 2, 1)
        CGContextStrokePath(ctx)
        
        drawLayer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
    }
    
    //MARK: - Touch Action
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let touchPoint = touch.locationInView(self)
        currentAngle = atan2(touchPoint.y - circleCenter.y, touchPoint.x - circleCenter.x)
        
        delegate?.brightProgress(self, startChangeValue: value)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touch = touches.first!
        let touchPoint = touch.locationInView(self)
        currentAngle = atan2(touchPoint.y - circleCenter.y, touchPoint.x - circleCenter.x)
        
        delegate?.brightProgress(self, didChangeValue: value)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let touchPoint = touch.locationInView(self)
        currentAngle = atan2(touchPoint.y - circleCenter.y, touchPoint.x - circleCenter.x)
        
        delegate?.brightProgress(self, endChangeValue: value)
    }
    
}