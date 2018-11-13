//
//  SlideTopBarController.swift
//  SweetCoffee
//
//  Created by Rail on 16/3/17.
//  Copyright © 2016年 Rail. All rights reserved.
//

import UIKit

let titleBarHeight:CGFloat = 40


class SlideTopBarController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    init(titles:[String], controllers:[UIViewController]) {
        self.titles = titles
        self.controllers = controllers
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var startScroll:(()->Void)?
    
    let horizonalCellID = "HorizonalCell"
    
    let topBar = SlideTopBar()
    let tableView = UITableView()
    var controllers:[UIViewController]!
    var titles:[String]!
    
    
    var currentIndex:Int = 0
    
    var selectController:UIViewController! {
        return controllers[currentIndex]
    }
    
    func changeIndex(index:Int, animate:Bool) {
        if currentIndex == index {
            return
        }
        self.startScroll?()
        self.currentIndex = index
        topBar.changeIndex(index)
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .None, animated: animate)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = .None
        
        view.backgroundColor = UIColor.grayColor()
        
        for controller in controllers! {
            addChildViewController(controller)
        }
        topBar.backgroundColor = UIColor.backgroundColor()
        topBar.titles = titles
        topBar.didChangeIndex = {index in
            self.startScroll?()
            self.currentIndex = index
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .None, animated: true)
            
        }
        let width = view.bounds.width
        topBar.frame = CGRect(x: 0, y: 0, width: width, height: titleBarHeight)
        
        view.addSubview(tableView)
        view.addSubview(topBar)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .None
        tableView.scrollsToTop = false
        tableView.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        tableView.showsVerticalScrollIndicator = false
        tableView.pagingEnabled = true
        tableView.bounces = false
        
        tableView.keyboardDismissMode = .OnDrag
        tableView.frame = CGRect(x: 0, y: titleBarHeight, width: width, height: view.bounds.height - titleBarHeight - 160)
    }
    
    //MARK TableView
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controllers.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.frame.width
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Default, reuseIdentifier: horizonalCellID)
        cell.contentView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        cell.selectionStyle = .None
        cell.backgroundColor = UIColor.backgroundColor()
        let controller = controllers[indexPath.row]
        controller.view.frame = cell.contentView.bounds
        cell.contentView.addSubview(controller.view)
        return cell
    }
    
    //MARK ScrollView
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollStop(true)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollStop(true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollStop(false)
        startScroll?()
    }
    
    
    func scrollStop(didScrollStop:Bool) {
        let offset = tableView.contentOffset.y
        let width = tableView.frame.width
        let offsetRatio = offset / width
        let focusIndex = Int((offset + width / 2) / width)
        
        if offset != CGFloat(focusIndex) * width {
            topBar.scrollView(offsetRatio)
        }
        
        if didScrollStop {
            currentIndex = focusIndex
            topBar.changeIndex(focusIndex)
        }
        
    }
    
}