//
//  SelectableTableViewController.swift
//  BlueLight
//
//  Created by Rail on 5/25/16.
//  Copyright © 2016 Rail. All rights reserved.
//

import UIKit


enum UITableViewSelectMode: Int {
    case None
    case Single
    case Multi
}


class SelectableTableViewController: UITableViewController, UITextFieldDelegate{
    
    
    var buttonNames:[String]!
    var buttonImages:[String]!
    var actions:[Selector]!
    
    var selectIndexs:[Int] = []
    
    var tap:UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tap = UITapGestureRecognizer(target: self, action: #selector(SelectableTableViewController.hideKeyboard))
        tap.enabled = false
        view.addGestureRecognizer(tap)
        clearsSelectionOnViewWillAppear = true
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SelectableTableViewController.keyboardWillShown(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SelectableTableViewController.keyboardWillHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    var selectMode:UITableViewSelectMode = .None {
        didSet {
            tableView.reloadData()
            selectIndexs = []
            for cell in tableView.visibleCells {
                let selectableCell = cell as! SelectableCell
                selectableCell.setSelectMode(selectMode, animate: true)
            }
            if selectMode == .Multi {
                tableView.allowsMultipleSelection = true
            }else if selectMode == .Single {
                tableView.allowsMultipleSelection = false
            }
            
        }
    }
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let selectableCell = cell as! SelectableCell
        selectableCell.selectMode = selectMode
        
        selectableCell.selected = selectIndexs.contains(indexPath.row)
        
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SelectableCell
        if selectMode == .Multi && !cell.multiSelectEnable {
            return
        }
        
        if selectMode == .Single {
            for index in selectIndexs {
                let ontherCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0))
                ontherCell?.selected = false
            }
            selectIndexs = []
        }
        cell.selected = true
        if !selectIndexs.contains(indexPath.row) {
            selectIndexs.append(indexPath.row)
            NSLog("\(selectIndexs)")
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SelectableCell
        if selectMode == .Multi && !cell.multiSelectEnable {
            return
        }
        selectIndexs.removeAtIndex(selectIndexs.indexOf(indexPath.row)!)

    }
    
    //MARK:- Rename
    var editingField:UITextField?
    var moveOffset:CGFloat = 0
    var editingIndex:Int?
    
    func rename() {
        if selectIndexs.count > 0 {
            let indexPath = NSIndexPath(forRow: selectIndexs[0], inSection: 0)
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .None, animated: false)
            
            let cell = tableView.cellForRowAtIndexPath(indexPath as NSIndexPath)
            let nameField = cell?.valueForKey("nameField") as! UITextField
            nameField.enabled = true
            nameField.delegate = self
            nameField.returnKeyType = .Done
            nameField.becomeFirstResponder()
            editingField = nameField
            editingIndex = selectIndexs[0]
            tap.enabled = true
        }
    }
    
    func keyboardWillShown(notification:NSNotification) {
        if selectIndexs.count > 0 {
            let indexPath = NSIndexPath(forRow: selectIndexs[0], inSection: 0)
            let cell = tableView.cellForRowAtIndexPath(indexPath as NSIndexPath)!
            let screenHeight = UIScreen.mainScreen().bounds.height
            let point = cell.convertPoint(CGPointZero, toView: tableView)
            let offset = tableView.contentOffset
            
            let toTop = point.y - offset.y
            let keyboardHeight = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue().height ?? 0
            
            moveOffset = toTop - screenHeight + keyboardHeight + 194
            
            if moveOffset > 0 {
                tableView.contentOffset.y = tableView.contentOffset.y + moveOffset
            }
        }
    }
    
    func keyboardWillHidden(notification:NSNotification) {
        if moveOffset > 0 {
            tableView.contentOffset.y = tableView.contentOffset.y - moveOffset
        }
        moveOffset = 0
        editingField?.enabled = false
        editingField = nil
        tap.enabled = false
    }
    
    func hideKeyboard(gesture:UITapGestureRecognizer) {
        if editingField != nil {
            editingField?.resignFirstResponder()
        }
    }
    
    //MARK: TextFieldDelegate
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        
        let name = textField.text
        changeName(name, index: editingIndex)
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.enabled = false
        return true
    }
    
    //MARK: - for override
    func changeName(name:String?, index:Int?) {
        
    }
}
