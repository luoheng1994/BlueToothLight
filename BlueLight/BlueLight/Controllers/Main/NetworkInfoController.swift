//
//  NetworkInfoController.swift
//  BlueLight
//
//  Created by Rail on 7/1/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class NetworkInfoController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "设置网络名称"
        tableView.backgroundColor = UIColor.backgroundColor()
        tableView.separatorColor = UIColor.colorWithHex(0xdfe8ee)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.allowsSelection = false
        
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 200
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UITableViewHeaderFooterView()
        
        let infoLabel = UILabel()
        infoLabel.textColor = UIColor.colorWithHex(0x999999)
        infoLabel.font = UIFont.systemFontOfSize(14)
        infoLabel.text = "设置到一个独立的网络，将附近的灯加入到网络中，通过密码加密发送数据"
        infoLabel.frame = CGRect(x: 20, y: 20, width: view.frame.width - 40, height: 40)
        infoLabel.lineBreakMode = .ByWordWrapping
        infoLabel.numberOfLines = 0
        footer.contentView.addSubview(infoLabel)
        
        let saveBtn = UIButton(type: .System)
        saveBtn.setTitle("保存", forState: [])
        saveBtn.setTitleColor(UIColor.whiteColor(), forState: [])
        saveBtn.backgroundColor = UIColor.themeColor()
        saveBtn.layer.cornerRadius = 8
        saveBtn.frame = CGRect(x: 20, y: 90, width: view.frame.width - 40, height: 50)
        saveBtn.addTarget(self, action: #selector(NetworkInfoController.doSave), forControlEvents: .TouchUpInside)
        footer.contentView.addSubview(saveBtn)
        return footer
    }
    
    let userNameField = UITextField()
    let userPwdField = UITextField()
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value2, reuseIdentifier: "value2 cell")
        cell.textLabel?.font = UIFont.systemFontOfSize(16)
        cell.textLabel?.textColor = UIColor.blackColor()
        if indexPath.row == 0 {
            cell.textLabel?.text = "网络名:"
            userNameField.frame = CGRect(x: 120, y: 0, width: view.frame.width, height: 50)
            userNameField.borderStyle = .None
            userNameField.text = AppInfo.shareInfo.userName
            cell.contentView.addSubview(userNameField)
        }else if indexPath.row == 1 {
            cell.textLabel?.text = "登陆密码:"
            userPwdField.frame = CGRect(x: 120, y: 0, width: view.frame.width, height: 50)
            userPwdField.borderStyle = .None
            userPwdField.keyboardType = .EmailAddress
            userPwdField.text = AppInfo.shareInfo.userPwd
            cell.contentView.addSubview(userPwdField)
        }
        return cell
    }
    
    //MARK: action
    func doSave() {
        let userName = userNameField.text
        let userPwd = userPwdField.text
        
        if userName?.characters.count == 0 {
            Utils.instance.showTip("请输入网路名称")
            return
        }
        
        if userPwd?.characters.count == 0 {
            Utils.instance.showTip("请输入密码")
            return
        }
        let oldPwd = AppInfo.shareInfo.userPwd!
        
        
        AppInfo.shareInfo.userName = userName
        AppInfo.shareInfo.userPwd = userPwd
        
        Utils.instance.showLoading("设置中", showBg: true)
        BlueService.instance.setCurrentNetword(oldPwd) { (success) in
            Utils.instance.hideLoading()
            BlueService.instance.reLogin()
            if success {
                Utils.instance.showTip("设置成功")
            }else {
                Utils.instance.showTip("设置失败")
            }
            
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
    
}
