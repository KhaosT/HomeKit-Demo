//
//  MasterViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 6/4/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

let characteristicUpdateNotification = "didUpdateValueForCharacteristic"

class MasterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate ,HMHomeManagerDelegate,HMHomeDelegate,HMAccessoryDelegate {
    
    var objects = [HMAccessory]()
    
    var homeManager:HMHomeManager = HMHomeManager()
    
    @IBOutlet var accessoriesTableView: UITableView?
    
    var mainHome:HMHome!
    
    weak var pendingAccessory:HMAccessory?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateHomeAccessories()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateHomeAccessories", name: addAccessoryNotificationString, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateHomeAccessories", name: assignAccessoryNotificationString, object: nil)
        homeManager.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func updateHomeAccessories() {
        if homeManager != nil && homeManager.primaryHome != nil {
            for accessory in homeManager.primaryHome.accessories as [HMAccessory] {
                if !contains(objects, accessory) {
                    objects.insert(accessory, atIndex: 0)
                    accessory.delegate = self
                }
            }
            accessoriesTableView?.reloadData()
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
        if segue.identifier? == "showDetail" {
            let indexPath = accessoriesTableView?.indexPathForSelectedRow()
            if let indexPath = indexPath {
                let object = objects[indexPath.row] as HMAccessory
                accessoriesTableView?.deselectRowAtIndexPath(indexPath, animated: true)
                (segue.destinationViewController as DetailViewController).detailItem = object
            }
        }
        if segue.identifier? == "showAddNewAccessories" {
            (segue.destinationViewController as AddAccessoriesViewController).homeManager = homeManager
        }
        
        if segue.identifier? == "presentRoomsVC" {
            let naviController = segue.destinationViewController as UINavigationController
            if let naviController = (segue.destinationViewController as? UINavigationController) {
                let roomVC = naviController.viewControllers?[0] as RoomsViewController
                roomVC.currentHome = mainHome
                if let accessory = pendingAccessory {
                    roomVC.pendingAccessory = accessory
                    pendingAccessory = nil
                }
            }
        }
    }
    
    func homeManagerDidUpdateHomes(manager: HMHomeManager!)
    {
        NSLog("DidUpdateHomes:\(manager)")
        for home in manager.homes as [HMHome] {
            NSLog("Home:\(home)")
        }
        if !manager.primaryHome {
            if manager.homes?.count > 0 {
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
            removeEverything()
            self.updateHomeAccessories()
        }
    }
    
    func home(home: HMHome!, didAddUser userID: String!)
    {
        NSLog("Did Add user: \(userID)")
    }
    
    func home(home: HMHome!, didAddAccessory accessory: HMAccessory!)
    {
        for accessory in homeManager.primaryHome.accessories as [HMAccessory] {
            if !contains(objects, accessory) {
                objects.insert(accessory, atIndex: 0)
                accessory.delegate = self
                accessoriesTableView?.insertRowsAtIndexPaths([NSIndexPath(forRow:0, inSection:0)], withRowAnimation: .Automatic)
            }
        }
    }
    
    func home(home: HMHome!, didRemoveAccessory accessory: HMAccessory!)
    {
        if contains(objects, accessory) {
            let index = find(objects, accessory)
            objects.removeAtIndex(index!)
            accessoriesTableView?.deleteRowsAtIndexPaths([NSIndexPath(forRow:index!, inSection:0)], withRowAnimation: .Fade)
        }
    }
    
    func accessoryDidUpdateServices(accessory: HMAccessory!)
    {
        NSLog("Did update services for accessory: \(accessory)")
    }
    
    func accessoryDidUpdateReachability(accessory: HMAccessory!)
    {
        if accessory.reachable {
            if contains(objects, accessory) {
                for service in accessory.services as [HMService] {
                    for characteristic in service.characteristics as [HMCharacteristic] {
                        if (characteristic.properties as NSArray).containsObject(HMCharacteristicPropertyReadable) {
                            characteristic.readValueWithCompletionHandler(
                                {
                                    (error:NSError!) in
                                    if error {
                                        NSLog("Error read Char: \(characteristic), error: \(error)")
                                    }
                                }
                            )
                        }
                    }
                }
                let index = find(objects, accessory)
                let cell = accessoriesTableView?.cellForRowAtIndexPath(NSIndexPath(forRow:index!, inSection:0))
                if accessory.reachable {
                    if let cell = cell {
                        cell.textLabel.textColor = UIColor(red: 0.043, green: 0.827, blue: 0.094, alpha: 1.0)
                    }
                }else{
                    if let cell = cell {
                        cell.textLabel.textColor = UIColor.redColor()
                    }
                }
            }

        }
    }
    
    func accessory(accessory: HMAccessory!, service: HMService!, didUpdateValueForCharacteristic characteristic: HMCharacteristic!)
    {
        NSLog("didUpdateValueForCharacteristic:\(characteristic)")
        NSNotificationCenter.defaultCenter().postNotificationName(characteristicUpdateNotification, object: nil, userInfo: ["accessory":accessory,"service":service,"characteristic":characteristic])
    }
    
    // #pragma mark - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        let object = objects[indexPath.row] as HMAccessory
        if object.reachable {
            cell.textLabel.textColor = UIColor(red: 0.043, green: 0.827, blue: 0.094, alpha: 1.0)
        }else{
            cell.textLabel.textColor = UIColor.redColor()
        }
        cell.textLabel.text = object.name
        
        cell.detailTextLabel.text = object.room?.name
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func removeEverything() {
        self.objects.removeAll(keepCapacity: false)
        self.objects += (self.homeManager.primaryHome.accessories as [HMAccessory])
        for accessory in self.objects {
            accessory.delegate = self
        }
    }
    
    func tableView(tableView: UITableView!, editActionsForRowAtIndexPath indexPath: NSIndexPath!) -> [AnyObject]! {
        
        var options = [UITableViewRowAction]()
        
        let assignAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Assign", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                if let strongSelf = self {
                    strongSelf.pendingAccessory = strongSelf.objects[indexPath.row]
                    strongSelf.performSegueWithIdentifier("presentRoomsVC", sender: self)
                    tableView.setEditing(false, animated: true)
                }
            }
        )
        assignAction.backgroundColor = UIColor.orangeColor()
        
        options += assignAction
        
        let identifyAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Identify", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                if let strongSelf = self {
                    let accessory = strongSelf.objects[indexPath.row] as HMAccessory
                    accessory.identifyWithCompletionHandler(
                        {
                            (error:NSError!) in
                            if error {
                                println("Failed to identify \(error)")
                            }else{
                                println("Successfully identify accessory")
                            }
                        }
                    )
                    tableView.setEditing(false, animated: true)
                }
            }
        )
        identifyAction.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        
        options += identifyAction
        
        if indexPath.row < objects.count && !( objects[indexPath.row] as HMAccessory).bridged {
            
            let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:
                {
                    [weak self]
                    (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                    let isBridge = (self?.objects[indexPath.row] as HMAccessory).identifiersForBridgedAccessories
                    self?.homeManager.primaryHome.removeAccessory(self?.objects[indexPath.row] as HMAccessory, completionHandler:
                        {
                            [weak self]
                            (error:NSError!) in
                            if error {
                                NSLog("Delete Accessory error: \(error)")
                            }else{
                                dispatch_async(dispatch_get_main_queue(),
                                    {
                                        if isBridge {
                                            self?.removeEverything()
                                            self?.accessoriesTableView?.reloadData()
                                        }else{
                                            self?.objects.removeAtIndex(indexPath.row)
                                            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                                        }
                                    }
                                )
                            }
                        }
                    )
                    tableView.setEditing(false, animated: true)
                }
            )
            
            options += deleteAction
            
        }
        
        return options
    }
    
    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        
    }
}

