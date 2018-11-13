//
//  ColorPanelView.swift
//  BlueLight
//
//  Created by Rail on 6/10/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

protocol ColorPanelDelegate:NSObjectProtocol {
    func colorPanelView(view:ColorPanelView, startChangeRed red:CGFloat, green:CGFloat, blue:CGFloat, white:CGFloat)
    func colorPanelView(view:ColorPanelView, didChangeRed red:CGFloat, green:CGFloat, blue:CGFloat, white:CGFloat)
    func colorPanelView(view:ColorPanelView, endChangeRed red:CGFloat, green:CGFloat, blue:CGFloat, white:CGFloat)
    
}

class ColorPanelView: UIView {
    
    weak var delegate:ColorPanelDelegate?
    
    var borderMargin:CGFloat = 20
    
    var radiusMax:CGFloat = 0
    
    let contetView = UIView()
    
    private let backgroundView = UIView()
    private let backgroundImageView = UIImageView()
    private let centerView = UIImageView()
    private let centerViewWidth:CGFloat = 80
    
    private var currentStatus:(angle:CGFloat, radius:CGFloat)! {
        didSet {
            redraw()
        }
    }
    private var _color:(red:CGFloat, green:CGFloat, blue:CGFloat, white:CGFloat) = (1, 0, 0, 0)
    
    var color:(red:CGFloat, green:CGFloat, blue:CGFloat, white:CGFloat) {
        get {
            return _color
        }
        set {
            _color = newValue
            let angle = Utils.getAngleFrom(_color.red, green: _color.green, blue: _color.blue)
            let radius = (1 - _color.white) * radiusMax
            currentStatus = (angle, radius)
        }
    }
    var realColor:(red:CGFloat, green:CGFloat, blue:CGFloat, white:CGFloat) = (0, 0, 0, 0)
    
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
        backgroundImageView.image = UIImage(named: "bg_color_panel")
        backgroundImageView.layer.shadowColor = UIColor.blackColor().CGColor
        backgroundImageView.layer.shadowRadius = 4
        backgroundImageView.layer.shadowOpacity = 0.3
        backgroundImageView.layer.shadowOffset = CGSizeZero
        
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext();
        CGContextBeginPath(ctx)
        CGContextSetLineWidth(ctx, 3)
        CGContextSetStrokeColorWithColor(ctx, UIColor.colorWithHex(0xb99dec).CGColor)
        CGContextAddArc(ctx, frame.width / 2, frame.height / 2, frame.width / 2 - 1.5, 0, pi * 2, 1)
        CGContextStrokePath(ctx)
        backgroundView.layer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
        
        radiusMax = frame.width / 2 - 30
        color = (1, 0, 0, 0)
    }
    
    func redraw() {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()
        
        
        let iconRadius:CGFloat = 10
        let point = CGPoint(x: frame.width / 2 + currentStatus.radius * cos(currentStatus.angle), y: frame.height / 2 + currentStatus.radius * sin(currentStatus.angle))
        if point.x.isNaN || point.y.isNaN {
            return
        }
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
    
    private func doTouch(touch:UITouch) {
        let touchPoint = touch.locationInView(self)
        
        let angle = atan2(touchPoint.y - frame.height / 2, touchPoint.x - frame.width / 2)
        let color = Utils.getRGBFromAngle(angle)
        var radius = (touchPoint.y - frame.height / 2 ) / sin(angle)
        if radius < 0 {
            radius = -radius
        }
        if radius > radiusMax {
            radius = radiusMax
        }
        
        let rad = radius / radiusMax
        _color.white = 1 - radius / radiusMax
        _color.blue = color.blue * rad
        _color.red = color.red * rad
        _color.green = color.green * rad
        
        realColor.red = color.red
        realColor.green = color.green
        realColor.blue = color.blue
        realColor.white = _color.white
        
        
        
        //        NSLog("\(_color)")
        currentStatus = (angle, radius)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        doTouch(touches.first!)
        delegate?.colorPanelView(self, startChangeRed: _color.red, green: _color.green, blue: _color.blue, white: _color.white)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        doTouch(touches.first!)
        delegate?.colorPanelView(self, didChangeRed: _color.red, green: _color.green, blue: _color.blue, white: _color.white)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        doTouch(touches.first!)
        delegate?.colorPanelView(self, endChangeRed: _color.red, green: _color.green, blue: _color.blue, white: _color.white)
    }
    
}