//
//  HomesViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 9/18/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class HomesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    weak var homeManager:HMHomeManager?
    @IBOutlet var homesTableView: UITableView!
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.homesTableView.setEditing(false, animated: false)
    }
    
    @IBAction func dismissHomeController(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func addHome(sender: AnyObject) {
        let alert:UIAlertController = UIAlertController(title: "Add Home", message: "Add home to HomeKit", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler:
            {
                [weak self]
                (action:UIAlertAction!) in
                let textField = alert.textFields?[0]
                if let strongSelf = self {
                    strongSelf.homeManager?.addHomeWithName(textField!.text!, completionHandler:
                        {
                            room,error in
                            if let error = error {
                                NSLog("Add home error:\(error)")
                            }else{
                                strongSelf.homesTableView.reloadData()
                            }
                        }
                    )
                }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let homes = self.homeManager?.homes {
            return homes.count
        }else{
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        let home = self.homeManager!.homes[indexPath.row]
        
        cell.textLabel?.text = home.name
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let home = self.homeManager!.homes[indexPath.row]
        
        Core.sharedInstance.currentHome = home
        
        NSNotificationCenter.defaultCenter().postNotificationName(changeHomeNotification, object: nil)
        
        self.dismissHomeController(self)
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        var options = [UITableViewRowAction]()
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                if let home = self?.homeManager?.homes[indexPath.row] {
                    self?.homeManager?.removeHome(home) {
                        error in
                        if error != nil {
                            NSLog("Failed removing home, error:\(error)")
                        } else {
                            self?.homesTableView.reloadData()
                        }
                    }
                }
                tableView.setEditing(false, animated: true)
            }
        )
        
        options.append(deleteAction)
        
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Rename", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                let alert:UIAlertController = UIAlertController(title: "Rename Home", message: "Update the name of the home", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler(nil)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let textField = alert.textFields?[0]
                        let home = self?.homeManager!.homes[indexPath.row]
                        home!.updateName(textField!.text!, completionHandler:
                            {
                                error in
                                if let error = error {
                                    print("Error:\(error)")
                                }else{
                                    let cell = tableView.cellForRowAtIndexPath(indexPath)
                                    cell?.textLabel?.text = self?.homeManager?.homes[indexPath.row].name
                                }
                            }
                        )
                }))
                self?.presentViewController(alert, animated: true, completion: nil)
            }
        )
        editAction.backgroundColor = UIColor.orangeColor()
        options.append(editAction)
        
        let primaryAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "🏡", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                let home = self?.homeManager?.homes[indexPath.row]
                self?.homeManager?.updatePrimaryHome(home!, completionHandler: {
                    error in
                    if let error = error {
                        print("Error:\(error)")
                    } else {
                        Core.sharedInstance.currentHome = home
                        
                        NSNotificationCenter.defaultCenter().postNotificationName(changeHomeNotification, object: nil)
                        
                        self?.dismissHomeController(self!)
                    }
                })
            }
        )
        primaryAction.backgroundColor = UIColor.cyanColor()
        options.append(primaryAction)
        
        return options
    }
    
}
