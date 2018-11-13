//
//  SelectableCell.swift
//  BlueLight
//
//  Created by Rail on 6/7/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class SelectableCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let statusView = viewWithTag(11) as! UIImageView
        if selectMode == .Single {
            statusView.image = UIImage(named: "select_single\(selected ? "_select":"")")
        }else if selectMode == .Multi {
            if multiSelectEnable {
                statusView.image = UIImage(named: "select_multi\(selected ? "_select":"")")
            }else {
                statusView.image = UIImage(named: "select_multi_disable")
            }
            
        }
    }

    
    var multiSelectEnable = true
    func setSelectMode(mode:UITableViewSelectMode, animate:Bool) {
        if animate {
            let statusView = viewWithTag(11) as! UIImageView
            statusView.alpha = 0.3
            
            self.selectMode = mode
            UIView.animateWithDuration(0.25, animations: {
                statusView.alpha = 1
            })
        }else {
            selectMode = mode
        }
    }
    
    var selectMode:UITableViewSelectMode = .None {
        didSet {
            
            var image:UIImage? = nil
            
            switch selectMode {
            case .None:
                image = UIImage(named: "icon_online")?.imageWithRenderingMode(.AlwaysTemplate)
            case .Single:
                image = UIImage(named: "select_single")
            case .Multi:
                if multiSelectEnable {
                    image = UIImage(named: "select_multi")
                }else {
                    image = UIImage(named: "select_multi_disable")
                }
            }
            let statusView = viewWithTag(11) as! UIImageView
            statusView.image = image
        }
    }
}
