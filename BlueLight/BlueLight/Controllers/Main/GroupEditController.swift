//
//  GroupEditController.swift
//  BlueLight
//
//  Created by Rail on 6/17/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit

class GroupEditController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var group:Group!
    var devices:[Device] = []
    
    let tableView = UITableView()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.backgroundColor()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "完成", style: .Plain, target: nil, action: nil)
        title = group.displayName
        let rect = view.frame
        
        title = group.name
        tableView.frame = CGRect(x: 0, y: 0, width: rect.width, height: rect.height - 100)
        tableView.editing = true
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.clearColor()
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        let bottomView = UIView()
        bottomView.backgroundColor = UIColor.colorWithHex(0xf2f2f2)
        bottomView.frame = CGRect(x: 0, y: rect.height - 100, width: rect.width, height: 100)
        bottomView.layer.shadowColor = UIColor.blackColor().CGColor
        bottomView.layer.shadowOffset = CGSize(width: 0, height: -5)
        bottomView.layer.shadowRadius = 8
        bottomView.layer.shadowOpacity = 0.1
        view.addSubview(bottomView)
        let addBtn = SubTitleButton(type: .Custom)
        addBtn.setTitle("添加灯", forState: [])
        addBtn.setImage(UIImage(named: "icon_add"), forState: [])
        addBtn.setTitleColor(UIColor.grayColor(), forState: [])
        addBtn.setTitleColor(UIColor.blackColor(), forState: .Highlighted)
        addBtn.frame = CGRect(x: rect.width / 2 - 50, y: 0, width: 100, height: 100)
        addBtn.addTarget(self, action: #selector(GroupEditController.addLight), forControlEvents: .TouchUpInside)
        bottomView.addSubview(addBtn)
        
    }

    
    //MARK: Action
    func addLight() {
        let ctl = GroupAddLightController()
        ctl.group = group
        navigationController?.pushViewController(ctl, animated: true)
    }
    override func viewWillAppear(animated: Bool) {
        refreshData()
    }
    
    func refreshData() {
        devices = group.devices?.allObjects as? [Device] ?? []
        tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return group.devices!.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "Value1 cell")
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.displayName
        cell.detailTextLabel?.text = device.displayType
        cell.detailTextLabel?.font = UIFont.systemFontOfSize(14)
        cell.backgroundColor = UIColor.clearColor()
        let seprator = UIView()
        seprator.backgroundColor = UIColor.colorWithHex(0xdfe8ee)
        seprator.frame = CGRect(x: -100, y: 78, width: view.frame.width + 200, height: 2)
        cell.contentView.addSubview(seprator)
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return .Delete
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            let device = devices[indexPath.row]
            if let client = device.client {
                Utils.instance.showLoading("删除中", showBg: true)
                BlueService.instance.remove([client], fromGroup: (group.identify?.unsignedCharValue)!, callBack: {
                    Utils.instance.hideLoading()
                    Utils.instance.showTip("删除成功")
                    self.refreshData()
                    
                })
            }
        }
    }
    
    override func navigationShouldPopOnBackButton() -> Bool {
        BlueService.instance.getGroup()
        return true
    }

}
