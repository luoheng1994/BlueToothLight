//
//  SceneCell.swift
//  BlueLight
//
//  Created by Rail on 7/7/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

enum SceneEditMode: Int {
    case none
    case delete
    case picker
    
}

class SceneCell: UICollectionViewCell {

    let colorView = UIImageView()
    
    
    var displayImage:UIImage? {
        didSet {
            colorView.image = displayImage
        }
    }
    
    var selectMode:SceneEditMode = .none
    
    func setSelectMode(mode:SceneEditMode, animate:Bool) {
        selectMode = mode
        if mode == .delete {
            if deleteBtn.hidden {
                deleteBtn.hidden = false
                if animate {
                    deleteBtn.alpha = 0
                    UIView.animateWithDuration(0.25, animations: {
                        self.deleteBtn.alpha = 1
                    })
                }
            }
        }else {
            if !deleteBtn.hidden {
                if animate {
                    UIView.animateWithDuration(0.25, animations: {
                        self.deleteBtn.alpha = 0
                        }, completion: { (finished) in
                            if finished {
                                self.deleteBtn.hidden = true
                            }
                    })
                }else {
                    self.deleteBtn.hidden = true
                    
                }
            }
        }
    }
    
    var deleteBlock:((view:UICollectionViewCell) -> Void)?
    
    let deleteBtn = UIButton()
    
    let nameLabel = UILabel()
    
    let indexView = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        colorView.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        colorView.layer.cornerRadius = 8
        
        colorView.clipsToBounds = true
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 2, height: 3)
        
        contentView.addSubview(colorView)
        colorView.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        
        deleteBtn.frame = CGRect(x: frame.width / 2 + 23, y: frame.height / 2 - 47, width: 24, height: 24)
        deleteBtn.setImage(UIImage(named: "icon_delete"), forState: [])
        deleteBtn.hidden = true
        deleteBtn.addTarget(self, action: #selector(SceneCell.doDelete), forControlEvents: .TouchUpInside)
        contentView.addSubview(deleteBtn)
        
        nameLabel.frame = CGRect(x: frame.width / 2 - 35, y: frame.height / 2 + 36, width: 70, height: 22)
        nameLabel.textAlignment = .Center
        nameLabel.font = UIFont.systemFontOfSize(15)
        nameLabel.textColor = UIColor.colorWithHex(0x333333)
        contentView.addSubview(nameLabel)
        
        indexView.frame = CGRect(x: frame.width / 2 + 23, y: frame.height / 2 - 47, width: 24, height: 24)
        indexView.layer.cornerRadius = 12
        indexView.layer.borderColor = UIColor.whiteColor().CGColor
        indexView.layer.borderWidth = 1
        indexView.textAlignment = .Center
        indexView.hidden = true
        indexView.clipsToBounds = true
        contentView.addSubview(indexView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func doDelete() {
        deleteBlock?(view: self)
    }
    
    let backColors:[UIColor] = [UIColor.bewitchedTree(),
                                UIColor.lightHeartBlue(),
                                UIColor.sillyFizz(),
                                UIColor.mustardAddicted(),
                                UIColor.trueBlush()
                                ]
    func showIndex(index:Int) {
        indexView.text = String(index)
        
        indexView.backgroundColor = backColors[index - 1]
        indexView.hidden = false
    }
    
    func hideIndex() {
        indexView.hidden = true
    }
    
}
