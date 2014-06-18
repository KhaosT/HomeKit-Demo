//
//  MasterViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 6/4/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class MasterViewController: UITableViewController,HMHomeManagerDelegate,HMHomeDelegate,HMAccessoryDelegate {
    
    var objects = NSMutableArray()
    
    var homeManager:HMHomeManager = HMHomeManager()
    
    var mainHome:HMHome!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeManager.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("ViewWillAppear")
        if homeManager != nil && homeManager.primaryHome != nil {
            for accessory in homeManager.primaryHome.accessories as HMAccessory[] {
                if !objects.containsObject(accessory) {
                    objects.insertObject(accessory, atIndex: 0)
                    accessory.delegate = self
                    tableView.insertRowsAtIndexPaths([NSIndexPath(forRow:0, inSection:0)], withRowAnimation: .Automatic)
                }
            }
        }
    }
    
    @IBAction func addUserToHome(sender: AnyObject) {
        let alert = UIAlertController(title: "New User", message: "Enter the iCloud address of user you want to add", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler:
            {
                (action:UIAlertAction!) in
                let textField = alert.textFields[0] as UITextField
                self.mainHome.addUser(textField.text, privilege: HMHomeUserPrivilege.Regular, completionHandler: { error in
                    if error {
                        NSLog("Add user failed: \(error)")
                    }
                    
                    })
            }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        dispatch_async(dispatch_get_main_queue(),
            {
                self.presentViewController(alert, animated: true, completion: nil)
            })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // #pragma mark - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let indexPath = self.tableView.indexPathForSelectedRow()
            let object = objects[indexPath.row] as HMAccessory
            (segue.destinationViewController as DetailViewController).detailItem = object
        }
        if segue.identifier == "showAddNewAccessories" {
            (segue.destinationViewController as AddAccessoriesViewController).homeManager = homeManager
        }
    }
    
    func homeManagerDidUpdateHomes(manager: HMHomeManager!)
    {
        NSLog("DidUpdateHomes:\(manager)")
        for home in manager.homes as HMHome[] {
            NSLog("Home:\(home)")
        }
        if !manager.primaryHome {
            if manager.homes != nil && manager.homes.count > 0 {
                manager.updatePrimaryHome(manager.homes[0] as HMHome, completionHandler:
                    { (error:NSError!) in
                        NSLog("DidSetPrimaryHome")
                    })
            }else{
                let alert:UIAlertController = UIAlertController(title: "Create New Home", message: "You need a new home to continue", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler(nil)
                alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let textField = alert.textFields[0] as UITextField
                        manager.addHomeWithName(textField.text, completionHandler:
                            {
                                (home:HMHome!, error:NSError!) in
                                NSLog("New Home \(home)")
                                manager.updatePrimaryHome(home, completionHandler:
                                    { (error:NSError!) in
                                        NSLog("DidSetPrimaryHome")
                                    })
                            })
                    }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                dispatch_async(dispatch_get_main_queue(),
                    {
                        self.presentViewController(alert, animated: true, completion: nil)
                    })
            }
        }else{
            mainHome = manager.primaryHome
            mainHome.delegate = self
            for accessory in manager.primaryHome.accessories as HMAccessory[] {
                if !objects.containsObject(accessory) {
                    objects.insertObject(accessory, atIndex: 0)
                    accessory.delegate = self
                    tableView.insertRowsAtIndexPaths([NSIndexPath(forRow:0, inSection:0)], withRowAnimation: .Automatic)
                }
            }
        }
    }
    
    func home(home: HMHome!, didAddUser userID: String!)
    {
        NSLog("Did Add user: \(userID)")
    }
    
    func home(home: HMHome!, didAddAccessory accessory: HMAccessory!)
    {
        for accessory in homeManager.primaryHome.accessories as HMAccessory[] {
            if !objects.containsObject(accessory) {
                objects.insertObject(accessory, atIndex: 0)
                accessory.delegate = self
                tableView.insertRowsAtIndexPaths([NSIndexPath(forRow:0, inSection:0)], withRowAnimation: .Automatic)
            }
        }
    }
    
    func home(home: HMHome!, didRemoveAccessory accessory: HMAccessory!)
    {
        if objects.containsObject(accessory) {
            let index = objects.indexOfObject(accessory)
            objects.removeObjectAtIndex(index)
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow:index, inSection:0)], withRowAnimation: .Fade)
        }
    }
    
    func accessoryDidUpdateReachability(accessory: HMAccessory!)
    {
        if objects.containsObject(accessory) {
            for service in accessory.services as HMService[] {
                for characteristic in service.characteristics as HMCharacteristic[] {
                    if (characteristic.properties as NSArray).containsObject(HMCharacteristicPropertyReadable) {
                        characteristic.readValueWithCompletionHandler(
                            {
                                (error:NSError!) in
                                if error {
                                    NSLog("Error read Char: \(characteristic), error: \(error)")
                                }else{
                                    NSLog("Successfully update Char :\(characteristic.characteristicType)")
                                }
                            }
                        )
                    }
                }
            }
            let index = objects.indexOfObject(accessory)
            let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow:index, inSection:0))
            if accessory.reachable {
                cell.textLabel.textColor = UIColor.greenColor()
            }else{
                cell.textLabel.textColor = UIColor.redColor()
            }
        }
    }
    
    // #pragma mark - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        let object = objects[indexPath.row] as HMAccessory
        if object.reachable {
            cell.textLabel.textColor = UIColor.greenColor()
        }else{
            cell.textLabel.textColor = UIColor.redColor()
        }
        cell.textLabel.text = object.name
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if indexPath.row < objects.count && ( objects[indexPath.row] as HMAccessory).bridged {
            return false
        }
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let isBridge = (objects.objectAtIndex(indexPath.row) as HMAccessory).identifiersForBridgedAccessories
            homeManager.primaryHome.removeAccessory(objects.objectAtIndex(indexPath.row) as HMAccessory, completionHandler:
                {
                    (error:NSError!) in
                    if error {
                        NSLog("Delete Accessory error: \(error)")
                    }else{
                        dispatch_async(dispatch_get_main_queue(),
                            {
                                if isBridge {
                                    self.objects.removeAllObjects()
                                    self.objects.addObjectsFromArray(self.homeManager.primaryHome.accessories)
                                    self.tableView.reloadData()
                                }else{
                                    self.objects.removeObjectAtIndex(indexPath.row)
                                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                                }
                            }
                        )
                    }
                })
        }
    }

}

