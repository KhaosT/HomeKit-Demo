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
let homeUpdateNotification = "didUpdateHomeManagerForHome"
let changeHomeNotification = "didUpdateCurrentHome"

class AccessoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate ,HMHomeManagerDelegate,HMHomeDelegate,HMAccessoryDelegate {
    
    var objects = [HMAccessory]()
    
    var homeManager:HMHomeManager = HMHomeManager()
    
    @IBOutlet var accessoriesTableView: UITableView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateHomeAccessories()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateHomeAccessories", name: addAccessoryNotificationString, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateHomeAccessories", name: assignAccessoryNotificationString, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateHomeAccessories", name: changeHomeNotification, object: nil)
        homeManager.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func updateHomeAccessories() {
        if Core.sharedInstance.currentHome != nil {
            self.objects.removeAll(keepCapacity: false)
            if let accessories = Core.sharedInstance.currentHome?.accessories {
                for accessory in accessories {
                    if !objects.contains(accessory) {
                        objects.insert(accessory, atIndex: 0)
                        accessory.delegate = self
                    }
                }
                accessoriesTableView.reloadData()
            }
        }
    }
    
    func handleError(error: NSError) {
        if error.code == 4097 {
            let alert = UIAlertController(title: "XPC Connection rejected!", message: "It appears that homed denies the xpc connection request from this app. This normally happens because the app doesn't have a HomeKit dev entitlement. Please may sure you have enabled the HomeKit capability in Xcode.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        if let errorCode = HMErrorCode(rawValue: error.code) {
            let alert = UIAlertController(title: "Oops!", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            switch errorCode {
            case .HomeAccessNotAuthorized:
                alert.message = "Access to HomeKit has been denied. Please enable HomeKit access for this app."
            case .HomeWithSimilarNameExists:
                alert.message = "A home with similar name alread exist, please try to use a different name."
            case .KeychainSyncNotEnabled:
                alert.message = "HomeKit requires Keychain Sync enabled when there is an iCloud account on device."
            case .MissingEntitlement:
                alert.message = "HomeKit requires the app to have HomeKit dev entitlement."
            case .NotSignedIntoiCloud:
                alert.message = "You need to sign in iCloud to process."
            case .CloudDataSyncInProgress:
                alert.message = "For iOS < 8.1, there is a issue syncing with CloudKit that may causes HomeKit database locked up. Currently there is no known reliable workaround on this issue, Sign out and sign in iCloud sometime may resolve this issue."
            default:
                alert.message = "An unknown error occurs. Error code: \(error.code). Please refer HMError.h for more details."
            }
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // #pragma mark - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let indexPath = accessoriesTableView.indexPathForSelectedRow
            if let indexPath = indexPath {
                let object = objects[indexPath.row] as HMAccessory
                accessoriesTableView.deselectRowAtIndexPath(indexPath, animated: true)
                (segue.destinationViewController as! ServiceViewController).detailItem = object
            }
        }
        
        if segue.identifier == "presentHomes" {
            if let naviController = (segue.destinationViewController as? UINavigationController) {
                let homeVC = naviController.viewControllers[0] as! HomesViewController
                homeVC.homeManager = self.homeManager
            }
        }
        
        if segue.identifier == "presentRoomsVC" {
            if let naviController = (segue.destinationViewController as? UINavigationController) {
                let roomVC = naviController.viewControllers[0] as! RoomsViewController
                if let accessory = sender as? HMAccessory {
                    roomVC.pendingAccessory = Accessory(hmAccessory: accessory)
                }
            }
        }
    }
    
    func homeManagerDidUpdateHomes(manager: HMHomeManager)
    {
        NSLog("DidUpdateHomes:\(manager)")
        for home in manager.homes {
            NSLog("Home:\(home)")
        }
        if manager.primaryHome == nil {
            NSLog("No Primary Home, try to setup one")
            if manager.homes.count > 0 {
                NSLog("There are homes in HMHomeManager, choose the first one.")
                manager.updatePrimaryHome(manager.homes[0], completionHandler:
                    {
                        error in
                        if error != nil {
                            self.handleError(error!)
                        }
                        Core.sharedInstance.currentHome = manager.homes[0]
                        NSLog("DidSetPrimaryHome")
                })
            }else{
                NSLog("No Home is available, ask user to add one.")
                let alert:UIAlertController = UIAlertController(title: "Create New Home", message: "You need a new home to continue", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler(nil)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let textField = alert.textFields![0]
                        manager.addHomeWithName(textField.text!, completionHandler:
                            {
                                home, error in
                                if error != nil {
                                    NSLog("Failed adding home, Error:\(error)")
                                    self.handleError(error!)
                                } else {
                                    NSLog("New Home \(home)")
                                    manager.updatePrimaryHome(home!, completionHandler:
                                        {
                                            error in
                                            if error != nil {
                                                NSLog("Failed updating primary home, Error: \(error)")
                                                self.handleError(error!)
                                            } else {
                                                Core.sharedInstance.currentHome = manager.homes[0]
                                                NSLog("DidSetPrimaryHome")
                                            }
                                        }
                                    )
                                }
                        })
                }))
                dispatch_async(dispatch_get_main_queue(),
                    {
                        self.presentViewController(alert, animated: true, completion: nil)
                })
            }
        }else{
            NSLog("Find primary Home :)")
            Core.sharedInstance.currentHome = manager.primaryHome
            Core.sharedInstance.currentHome?.delegate = self
            removeEverything()
            self.updateHomeAccessories()
            NSNotificationCenter.defaultCenter().postNotificationName(homeUpdateNotification, object: nil)
        }
    }
    
    func home(home: HMHome, didAddUser user: HMUser) {
        NSLog("Did Add user: \(user)")
    }
    
    func home(home: HMHome, didAddAccessory accessory: HMAccessory)
    {
        for accessory in Core.sharedInstance.currentHome!.accessories as [HMAccessory] {
            if !objects.contains(accessory) {
                objects.insert(accessory, atIndex: 0)
                accessory.delegate = self
                accessoriesTableView.insertRowsAtIndexPaths([NSIndexPath(forRow:0, inSection:0)], withRowAnimation: .Automatic)
            }
        }
    }
    
    func home(home: HMHome, didRemoveAccessory accessory: HMAccessory)
    {
        if objects.contains(accessory) {
            let index = objects.indexOf(accessory)
            objects.removeAtIndex(index!)
            accessoriesTableView.deleteRowsAtIndexPaths([NSIndexPath(forRow:index!, inSection:0)], withRowAnimation: .Fade)
        }
    }
    
    func accessoryDidUpdateServices(accessory: HMAccessory)
    {
        NSLog("Did update services for accessory: \(accessory)")
    }
    
    func accessoryDidUpdateReachability(accessory: HMAccessory)
    {
        if accessory.reachable {
            if objects.contains(accessory) {
                for service in accessory.services as [HMService] {
                    for characteristic in service.characteristics {
                        if characteristic.properties.contains(HMCharacteristicPropertyReadable) {
                            characteristic.readValueWithCompletionHandler(
                                {
                                    error in
                                    if error != nil {
                                        NSLog("Error read Char: \(characteristic), error: \(error)")
                                    }
                                }
                            )
                        }
                    }
                }
                let index = objects.indexOf(accessory)
                let cell = accessoriesTableView.cellForRowAtIndexPath(NSIndexPath(forRow:index!, inSection:0))
                if accessory.reachable {
                    if let cell = cell {
                        cell.textLabel?.textColor = UIColor(red: 0.043, green: 0.827, blue: 0.094, alpha: 1.0)
                    }
                }else{
                    if let cell = cell {
                        cell.textLabel?.textColor = UIColor.redColor()
                    }
                }
            }

        }
    }
    
    func accessory(accessory: HMAccessory, service: HMService, didUpdateValueForCharacteristic characteristic: HMCharacteristic)
    {
        NSLog("didUpdateValueForCharacteristic:\(characteristic)")
        NSNotificationCenter.defaultCenter().postNotificationName(characteristicUpdateNotification, object: nil, userInfo: ["accessory":accessory,"service":service,"characteristic":characteristic])
    }
    
    // #pragma mark - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.objects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let object = objects[indexPath.row] as HMAccessory
        if object.reachable {
            cell.textLabel?.textColor = UIColor(red: 0.043, green: 0.827, blue: 0.094, alpha: 1.0)
        }else{
            cell.textLabel?.textColor = UIColor.redColor()
        }
        cell.textLabel?.text = object.name
        
        cell.detailTextLabel?.text = object.room?.name
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func removeEverything() {
        self.objects.removeAll(keepCapacity: false)
        self.objects += (Core.sharedInstance.currentHome!.accessories)
        for accessory in self.objects {
            accessory.delegate = self
        }
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        var options = [UITableViewRowAction]()
        
        let assignAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Assign", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                if let strongSelf = self {
                    strongSelf.performSegueWithIdentifier("presentRoomsVC", sender: strongSelf.objects[indexPath.row])
                    tableView.setEditing(false, animated: true)
                }
            }
        )
        assignAction.backgroundColor = UIColor.orangeColor()
        
        options.append(assignAction)
        
        let identifyAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Identify", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                if let strongSelf = self {
                    let accessory = strongSelf.objects[indexPath.row] as HMAccessory
                    accessory.identifyWithCompletionHandler(
                        {
                            error in
                            if (error != nil) {
                                print("Failed to identify \(error)")
                            }else{
                                print("Successfully identify accessory")
                            }
                        }
                    )
                    tableView.setEditing(false, animated: true)
                }
            }
        )
        identifyAction.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        
        options.append(identifyAction)
        
        if indexPath.row < objects.count && !( objects[indexPath.row] as HMAccessory).bridged {
            
            let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:
                {
                    [weak self]
                    (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                    let isBridge = self?.objects[indexPath.row].identifiersForBridgedAccessories
                    Core.sharedInstance.currentHome?.removeAccessory(self!.objects[indexPath.row], completionHandler:
                        {
                            [weak self]
                            error in
                            if error != nil {
                                NSLog("Delete Accessory error: \(error)")
                            }else{
                                dispatch_async(dispatch_get_main_queue(),
                                    {
                                        if (isBridge != nil) {
                                            self?.removeEverything()
                                            self?.accessoriesTableView.reloadData()
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
            
            options.append(deleteAction)
            
        }
        
        return options
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}

