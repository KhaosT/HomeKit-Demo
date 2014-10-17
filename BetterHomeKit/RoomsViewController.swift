//
//  RoomsViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 7/19/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

let assignAccessoryNotificationString = "DidAssignAccessoryToRoom"

class RoomsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var pendingAccessory:Accessory?
    @IBOutlet var roomTableView: UITableView!
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.roomTableView.setEditing(false, animated: false)
    }
    
    @IBAction func dismissRoomController(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func addRoom(sender: AnyObject) {
        let alert:UIAlertController = UIAlertController(title: "Add Room", message: "Add room to current Home", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler:
            {
                [weak self]
                (action:UIAlertAction!) in
                let textField = alert.textFields?[0] as UITextField
                if let strongSelf = self {
                    Core.sharedInstance.currentHome?.addRoomWithName(textField.text, completionHandler:
                        {
                            room,error in
                            if let error = error {
                                NSLog("Add room error:\(error)")
                            }else{
                                strongSelf.roomTableView.reloadData()
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
        if let rooms = Core.sharedInstance.currentHome?.rooms {
            return rooms.count
        }else{
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("roomCell", forIndexPath: indexPath) as UITableViewCell
        
        let room = Core.sharedInstance.currentHome?.rooms?[indexPath.row] as HMRoom

        cell.textLabel.text = room.name
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let accessory = pendingAccessory {
            let room = Core.sharedInstance.currentHome?.rooms[indexPath.row] as HMRoom
            Core.sharedInstance.currentHome?.assignAccessory(accessory.toHMAccessory(), toRoom: room, completionHandler:
                {
                    [weak self]
                    error in
                    if let error = error {
                        NSLog("Assign Accessory \(accessory) to room \(room) error:\(error)")
                    }else{
                        NSLog("Successfully assigned the accessory")
                        NSNotificationCenter.defaultCenter().postNotificationName(assignAccessoryNotificationString, object: nil)
                        self?.dismissRoomController(room)
                    }
                }
            )
        }else{
            let alert:UIAlertController = UIAlertController(title: "Rename Room", message: "Update the name of the room", preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler(nil)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default, handler:
                {
                    [weak self]
                    (action:UIAlertAction!) in
                    let textField = alert.textFields?[0] as UITextField
                    let room = Core.sharedInstance.currentHome?.rooms?[indexPath.row] as HMRoom
                    room.updateName(textField.text, completionHandler:
                        {
                            error in
                            if let error = error {
                                println("Error:\(error)")
                            }else{
                                let cell = tableView.cellForRowAtIndexPath(indexPath)
                                cell?.textLabel.text = Core.sharedInstance.currentHome?.rooms?[indexPath.row].name
                            }
                        }
                    )
                }))
            dispatch_async(dispatch_get_main_queue(),
                {
                    self.presentViewController(alert, animated: true, completion: nil)
                })
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let room = Core.sharedInstance.currentHome?.rooms[indexPath.row] as? HMRoom {
                Core.sharedInstance.currentHome?.removeRoom(room) {
                    [weak self]
                    error in
                    if error != nil {
                        NSLog("Failed removing room, error:\(error)")
                    } else {
                        self?.roomTableView.reloadData()
                    }
                }
            }
        }
    }
}
