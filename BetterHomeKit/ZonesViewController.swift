//
//  ZonesViewController.swift
//  BetterHomeKit
//
//  Created by Roy Arents on 01-11-14.
//  Copyright (c) 2014 Nlr. All rights reserved.
//
// Heavily inspired by KhaosT's RoomsViewController.swift

import UIKit
import HomeKit

let assignRoomNotificationString = "DidAssignRoomToZone"

class ZonesViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var pendingRoom:Room?
    @IBOutlet var zoneTableView: UITableView!
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.zoneTableView.setEditing(false, animated: false)
    }
    
    @IBAction func dismissZoneController(sender: AnyObject) {
        if let _ = pendingRoom {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func addZone(sender: AnyObject) {
        let alert:UIAlertController = UIAlertController(title: "Add Zone", message: "Add zone to current Home", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler:
            {
                [weak self]
                (action:UIAlertAction!) in
                let textField = alert.textFields![0]
                if let strongSelf = self {
                    Core.sharedInstance.currentHome?.addZoneWithName(textField.text!, completionHandler:
                        {
                            room,error in
                            if let error = error {
                                NSLog("Add zone error:\(error)")
                            }else{
                                strongSelf.zoneTableView.reloadData()
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
        return Core.sharedInstance.currentHome?.zones.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("zoneCell", forIndexPath: indexPath) as UITableViewCell
        
        let zone = Core.sharedInstance.currentHome!.zones[indexPath.row]
        
        var detailText = ""
        
        if zone.rooms.count > 0 {
            detailText += "|"
            let roomNames = zone.rooms.map { $0.name }
            
            for name in roomNames {
                detailText += "\(name)|"
            }
        }
        
        cell.textLabel?.text = zone.name
        cell.detailTextLabel?.text = detailText
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        NSLog("pendingRoom \(pendingRoom) name= \(pendingRoom)")
        if let room = pendingRoom {
            let zone = Core.sharedInstance.currentHome!.zones[indexPath.row]
            NSLog("zone \(zone)")
            zone.addRoom(room.toHMRoom(), completionHandler:
                {
                    [weak self]
                    error in
                    if let error = error {
                        NSLog("Assign Room \(room) to zone \(zone) error:\(error)")
                        // Try to remove it?
                        zone.removeRoom(room.toHMRoom(), completionHandler:
                            {
                                [weak self]
                                error in
                                if let error = error {
                                    NSLog("Removing Room \(room) to zone \(zone) error:\(error)")
                                }else{
                                    NSLog("Successfully removed the room")
                                    NSNotificationCenter.defaultCenter().postNotificationName(assignRoomNotificationString, object: nil)
                                    self?.dismissZoneController(zone)
                                }
                            }
                        )
                    }else{
                        NSLog("Successfully assigned the room")
                        NSNotificationCenter.defaultCenter().postNotificationName(assignRoomNotificationString, object: nil)
                        self?.dismissZoneController(zone)
                    }
                }
            )
        }else{
            let alert:UIAlertController = UIAlertController(title: "Rename Zone", message: "Update the name of the zone", preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler(nil)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default, handler:
                {
                    [weak self]
                    (action:UIAlertAction!) in
                    let textField = alert.textFields![0]
                    let zone = Core.sharedInstance.currentHome!.zones[indexPath.row]
                    zone.updateName(textField.text!, completionHandler:
                        {
                            error in
                            if let error = error {
                                print("Error:\(error)")
                            }else{
                                let cell = tableView.cellForRowAtIndexPath(indexPath)
                                cell?.textLabel?.text = Core.sharedInstance.currentHome?.zones[indexPath.row].name
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
            if let zone = Core.sharedInstance.currentHome?.zones[indexPath.row] {
                Core.sharedInstance.currentHome?.removeZone(zone) {
                    [weak self]
                    error in
                    if error != nil {
                        NSLog("Failed removing zone, error:\(error)")
                    } else {
                        self?.zoneTableView.reloadData()
                    }
                }
            }
        }
    }
}
