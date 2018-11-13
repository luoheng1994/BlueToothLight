//
//  SubTitleButton.swift
//  shandui
//
//  Created by Rail on 5/25/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class SubTitleButton: UIButton {
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        imageEdgeInsets = UIEdgeInsets(top:  -(titleLabel?.frame.height)! * 1.5, left: 0, bottom: 0, right: -(titleLabel?.frame.width)!)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: -(imageView?.frame.size.width)!, bottom: -(imageView?.frame.size.height)! - (titleLabel?.frame.height)! * 0.5, right: 0)
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageEdgeInsets = UIEdgeInsets(top:  -(titleLabel?.frame.height)! * 1.5, left: 0, bottom: 0, right: -(titleLabel?.frame.width)!)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: -(imageView?.frame.size.width)!, bottom: -(imageView?.frame.size.height)! - (titleLabel?.frame.height)! * 0.5, right: 0)
    }
}
