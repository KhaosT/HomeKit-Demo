//
//  TriggersViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 8/6/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class TriggersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var triggers = [HMTrigger]()
    
    var dateFormatter = NSDateFormatter()
    
    @IBOutlet weak var triggersTableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "HH:mm"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateTriggers()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.triggersTableview.setEditing(false, animated: false)
    }
    
    func updateTriggers () {
        triggers.removeAll(keepCapacity: false)
        if let currentHome = Core.sharedInstance.currentHome {
            triggers += currentHome.triggers as [HMTrigger]
        }
        triggersTableview.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetailedTrigger" {
            let triggerVC = segue.destinationViewController as! TriggerDetailViewController
            triggerVC.currentTrigger = sender as? HMTrigger
        }
        
        if segue.identifier == "updateTrigger" {
            let triggerVC = segue.destinationViewController as! TriggerCreateViewController
            triggerVC.pendingTrigger = sender as? HMTimerTrigger
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return triggers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TriggerCell", forIndexPath: indexPath) as UITableViewCell
        
        let trigger = triggers[indexPath.row] as! HMTimerTrigger
        cell.textLabel?.text = trigger.name
        
        if trigger.enabled {
            cell.textLabel?.textColor = UIColor(red: 0.043, green: 0.827, blue: 0.094, alpha: 1.0)
            cell.detailTextLabel?.textColor = UIColor(red: 0.043, green: 0.827, blue: 0.094, alpha: 1.0)
        } else {
            cell.textLabel?.textColor = UIColor.lightGrayColor()
            cell.detailTextLabel?.textColor = UIColor.lightGrayColor()
        }
        
        var actions = trigger.actionSets.map{$0.name}
        var detailText = ""
        
        for name in actions {
            detailText += "\(name) "
        }
        
        detailText += "| Fire Date: \(dateFormatter.stringFromDate(trigger.fireDate)) "
        
        if trigger.lastFireDate != nil {
            detailText += "| Last Fire: \(dateFormatter.stringFromDate(trigger.lastFireDate!))"
        }
        
        cell.detailTextLabel?.text = detailText
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let trigger = triggers[indexPath.row]
        
        self.performSegueWithIdentifier("showDetailedTrigger", sender: trigger)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        var options = [UITableViewRowAction]()
        
        let trigger = triggers[indexPath.row] as! HMTimerTrigger
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:
            {
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                Core.sharedInstance.currentHome?.removeTrigger(trigger) {
                    error in
                    if error != nil {
                        NSLog("Failed removing trigger, error: \(error)")
                    } else {
                        self.updateTriggers()
                    }
                }
                tableView.setEditing(false, animated: true)
            }
        )
        
        options.append(deleteAction)
        
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Edit", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                self?.performSegueWithIdentifier("updateTrigger", sender: trigger)
                tableView.setEditing(false, animated: true)
            }
        )
        editAction.backgroundColor = UIColor.orangeColor()
        options.append(editAction)
        
        if trigger.enabled {
            let disableAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Disable", handler:
                {
                    [weak self]
                    (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                    if let strongSelf = self {
                        trigger.enable(false) {
                            [weak self]
                            error in
                            if error != nil {
                                NSLog("Failed disabling trigger, error: \(error)")
                            } else {
                                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                            }
                        }
                    }
                    tableView.setEditing(false, animated: true)
                }
            )
            disableAction.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
            
            options.append(disableAction)
        } else {
            let enableAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Enable", handler:
                {
                    [weak self]
                    (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                    if let strongSelf = self {
                        trigger.enable(true) {
                            [weak self]
                            error in
                            if error != nil {
                                NSLog("Failed enabling trigger, error: \(error)")
                            } else {
                                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                            }
                        }
                    }
                    tableView.setEditing(false, animated: true)
                }
            )
            enableAction.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
            
            options.append(enableAction)
        }
        
        return options
    }
}
