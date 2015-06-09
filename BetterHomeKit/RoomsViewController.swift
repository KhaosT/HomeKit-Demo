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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateRooms", name: assignRoomNotificationString, object: nil)
    }
    
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
                let textField = alert.textFields![0]
                if let strongSelf = self {
                    Core.sharedInstance.currentHome?.addRoomWithName(textField.text!, completionHandler:
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
    
    func updateRooms() {
        self.roomTableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "presentZonesVC" {
            if let zoneVC = segue.destinationViewController as? ZonesViewController {
                if let room = sender as? HMRoom {
                    zoneVC.pendingRoom = Room( hmRoom : room)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Core.sharedInstance.currentHome?.rooms.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("roomCell", forIndexPath: indexPath) as UITableViewCell
        
        let room = Core.sharedInstance.currentHome?.rooms[indexPath.row]

        cell.textLabel?.text = room?.name
        
        var detailText = ""
        for(var i=0; i<Core.sharedInstance.currentHome?.zones.count; i++)
        {
            let zone = Core.sharedInstance.currentHome?.zones[i]
            if let rooms = zone?.rooms
            {
                for iroom in rooms
                {
                    if iroom.name == room?.name {
                        detailText += zone!.name + " "
                    }
                }
            }
        }
        cell.detailTextLabel?.text = detailText
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let accessory = pendingAccessory {
            let room = Core.sharedInstance.currentHome!.rooms[indexPath.row]
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
                    (action:UIAlertAction!) in
                    let textField = alert.textFields![0]
                    let room = Core.sharedInstance.currentHome!.rooms[indexPath.row]
                    room.updateName(textField.text!, completionHandler:
                        {
                            error in
                            if let error = error {
                                print("Error:\(error)")
                            }else{
                                let cell = tableView.cellForRowAtIndexPath(indexPath)
                                cell?.textLabel?.text = Core.sharedInstance.currentHome!.rooms[indexPath.row].name
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
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        var options = [UITableViewRowAction]()
    
        let assignAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Assign", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                if let strongSelf = self {
                    if let room = Core.sharedInstance.currentHome?.rooms[indexPath.row] {
                        strongSelf.performSegueWithIdentifier("presentZonesVC", sender: room)
                        tableView.setEditing(false, animated: true)
                    }
                }
            }
        )
        assignAction.backgroundColor = UIColor.orangeColor()
        
        options.append(assignAction)
    
        if indexPath.row < Core.sharedInstance.currentHome?.rooms.count {
    
            let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:
                {
                
                    [weak self]
                    (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                    if let room = Core.sharedInstance.currentHome?.rooms[indexPath.row] {
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

                    tableView.setEditing(false, animated: true)

                }
            )
            
            options.append(deleteAction)
        }

        return options
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    /*
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
    */
}
