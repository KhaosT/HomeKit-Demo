//
//  ActionSetViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 8/6/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class ActionSetsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    weak var pendingTrigger:HMTrigger?
    var pendingCharacteristic: Characteristic?
    
    var actionSets = [HMActionSet]()
    
    @IBOutlet weak var actionSetsTableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateActionSets()
    }
    
    func updateActionSets () {
        actionSets.removeAll(keepCapacity: false)
        if let currentHome = Core.sharedInstance.currentHome {
            actionSets += currentHome.actionSets as [HMActionSet]
        }
        actionSetsTableview.reloadData()
    }

    @IBAction func addActionSet(sender: AnyObject) {
        let alert:UIAlertController = UIAlertController(title: "Add Action Set", message: "Add Action Set to current Home", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler:
            {
                [weak self]
                (action:UIAlertAction!) in
                let textField = alert.textFields![0]
                Core.sharedInstance.currentHome?.addActionSetWithName(textField.text!){
                    [weak self]
                    actionSet, error in
                    if error != nil {
                        NSLog("Failed to add action set, Error: \(error)")
                    } else {
                        self?.updateActionSets()
                    }
                }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetailedActionSet" {
            let actionVC = segue.destinationViewController as! ActionSetViewController
            actionVC.currentActionSet = sender as? HMActionSet
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionSets.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ActionSetCell", forIndexPath: indexPath) as UITableViewCell
        
        let actionSet = actionSets[indexPath.row]
        cell.textLabel?.text = actionSet.name
        cell.detailTextLabel?.text = "Actions:\(actionSet.actions.count)"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let actionSet = actionSets[indexPath.row]
        
        if let pendingTrigger = pendingTrigger {
            pendingTrigger.addActionSet(actionSet) {
                [weak self]
                error in
                if error != nil {
                    NSLog("Failed adding action set to trigger, error:\(error)")
                } else {
                    self?.navigationController?.popViewControllerAnimated(true)
                }
            }
        } else if let pendingChar = pendingCharacteristic?.toHMCharacteristic() {
            let object = pendingChar
            var charDesc = object.characteristicType
            charDesc = HomeKitUUIDs[object.characteristicType]!
            switch (object.metadata!.format!) {
            case HMCharacteristicMetadataFormatBool:
                let alert:UIAlertController = UIAlertController(title: "Target \(charDesc)", message: "Please choose the target state for this action", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "On", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let writeAction = HMCharacteristicWriteAction(characteristic: object, targetValue: true)
                        actionSet.addAction(writeAction) {
                            error in
                            if error != nil {
                                NSLog("Failed adding action to action set, error: \(error)")
                            } else {
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        }
                }))
                alert.addAction(UIAlertAction(title: "Off", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let writeAction = HMCharacteristicWriteAction(characteristic: object, targetValue: false)
                        actionSet.addAction(writeAction) {
                            error in
                            if error != nil {
                                NSLog("Failed adding action to action set, error: \(error)")
                            } else {
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        }
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                dispatch_async(dispatch_get_main_queue(),
                    {
                        self.presentViewController(alert, animated: true, completion: nil)
                })
            case HMCharacteristicMetadataFormatInt,HMCharacteristicMetadataFormatFloat,HMCharacteristicMetadataFormatUInt8,HMCharacteristicMetadataFormatUInt16,HMCharacteristicMetadataFormatUInt32,HMCharacteristicMetadataFormatUInt64:
                let alert:UIAlertController = UIAlertController(title: "Target \(charDesc)", message: "Enter the target state for this action from \(object.metadata!.minimumValue) to \(object.metadata!.maximumValue). Unit is \(object.metadata!.units)", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler(nil)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let textField = alert.textFields?[0]
                        let f = NSNumberFormatter()
                        f.numberStyle = NSNumberFormatterStyle.DecimalStyle
                        let writeAction = HMCharacteristicWriteAction(characteristic: object, targetValue: f.numberFromString(textField!.text!)!)
                        actionSet.addAction(writeAction) {
                            error in
                            if error != nil {
                                NSLog("Failed adding action to action set, error: \(error)")
                            } else {
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        }
                }))
                dispatch_async(dispatch_get_main_queue(),
                    {
                        self.presentViewController(alert, animated: true, completion: nil)
                })
            case HMCharacteristicMetadataFormatString:
                let alert:UIAlertController = UIAlertController(title: "Target \(charDesc)", message: "Enter the target \(charDesc) from \(object.metadata!.minimumValue) to \(object.metadata!.maximumValue). Unit is \(object.metadata!.units)", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler(nil)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let textField = alert.textFields?[0]
                        let writeAction = HMCharacteristicWriteAction(characteristic: object, targetValue: textField!.text!)
                        actionSet.addAction(writeAction) {
                            error in
                            if error != nil {
                                NSLog("Failed adding action to action set, error: \(error)")
                            } else {
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        }
                }))
                dispatch_async(dispatch_get_main_queue(),
                    {
                        self.presentViewController(alert, animated: true, completion: nil)
                })
            default:
                NSLog("Unsupported")
            }
        } else {
            self.performSegueWithIdentifier("showDetailedActionSet", sender: actionSet)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        var options = [UITableViewRowAction]()
        
        let actionSet = actionSets[indexPath.row] as HMActionSet
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler:
            {
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                Core.sharedInstance.currentHome?.removeActionSet(actionSet) {
                    error in
                    if error != nil {
                        NSLog("Failed removing action set, error: \(error)")
                    } else {
                        self.updateActionSets()
                    }
                }
                tableView.setEditing(false, animated: true)
            }
        )
        
        options.append(deleteAction)
        
        let renameAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Rename", handler:
            {
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                let alert:UIAlertController = UIAlertController(title: "Rename Action Set", message: "Update the name of the Action Set", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler(nil)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let textField = alert.textFields?[0]
                        actionSet.updateName(textField!.text!) {
                            error in
                            if let error = error {
                                print("Error:\(error)")
                            }else{
                                let cell = tableView.cellForRowAtIndexPath(indexPath)
                                cell?.textLabel?.text = actionSet.name
                            }
                        }
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                tableView.setEditing(false, animated: true)
            }
        )
        renameAction.backgroundColor = UIColor.orangeColor()
        options.append(renameAction)
        
        return options
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }

}
