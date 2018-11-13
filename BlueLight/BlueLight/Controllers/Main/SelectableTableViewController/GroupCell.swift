//
//  GroupCell.swift
//  BlueLight
//
//  Created by Rail on 6/7/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class GroupCell: SelectableCell {

    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var statusView: UIImageView!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var nameField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
        backgroundColor = UIColor.backgroundColor()
        statusView.image = UIImage(named: "icon_online")?.imageWithRenderingMode(.AlwaysTemplate)
        online = false
        
        backgroundImageView.backgroundColor = UIColor.colorWithHex(0xdfe8ee)
        infoLabel.textColor = UIColor.colorWithHex(0x666666)
        nameField.enabled = false
        
        statusView.tag = 11
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    var indexPath:NSIndexPath! {
        didSet {
            let index = indexPath.row % 5 + 1
            let imageName = "list_background_\(index)"
            backgroundImageView.image = UIImage(named: imageName)
        }
    }
    
    var online = false {
        didSet {
            statusView.tintColor = online ? onlineColor : offlineColor
        }
    }
    
    var offlineColor = UIColor.colorWithHex(0x95a9b7)
    
    var onlineColor = UIColor.themeColor() {
        didSet {
            statusView.tintColor = onlineColor
        }
    }
    
}
