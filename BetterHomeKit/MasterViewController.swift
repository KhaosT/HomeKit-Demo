//
//  MasterViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 6/4/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class MasterViewController: UITableViewController,HMHomeManagerDelegate,HMHomeDelegate {
    
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
        if !manager.primaryHome {
            let alert:UIAlertController = UIAlertController(title: "Create New Home", message: "You need a new home to continue", preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler(nil)
            alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler:
                {
                    action in
                    let textField = alert.textFields[0] as UITextField
                    manager.addHomeWithName(textField.text, completionHandler:
                        {
                            home, error in
                            NSLog("New Home \(home)")
                        })
                }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            dispatch_async(dispatch_get_main_queue(),
                {
                    self.presentViewController(alert, animated: true, completion: nil)
                })
        }else{
            mainHome = manager.primaryHome
            mainHome.delegate = self
            for accessory:HMAccessory! in manager.primaryHome.accessories {
                if !objects.containsObject(accessory) {
                    objects.insertObject(accessory, atIndex: 0)
                    tableView.insertRowsAtIndexPaths([NSIndexPath(forRow:0, inSection:0)], withRowAnimation: .Automatic)
                }
            }
        }
    }
    
    func home(home: HMHome!, didAddAccessory accessory: HMAccessory!)
    {
        for accessory:HMAccessory! in homeManager.primaryHome.accessories {
            if !objects.containsObject(accessory) {
                objects.insertObject(accessory, atIndex: 0)
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
        NSLog("Reach:\(object.reachable)")
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
                    error in
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

