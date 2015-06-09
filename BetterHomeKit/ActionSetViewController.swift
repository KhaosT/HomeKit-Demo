//
//  ActionSetViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 8/6/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class ActionSetViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var actionsTableView: UITableView!
    
    weak var currentActionSet:HMActionSet?
    
    var actions = [HMAction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentActionSet = currentActionSet {
            self.title = "\(currentActionSet.name)"
        }
        
        updateActions()
    }
    
    func updateActions () {
        actions.removeAll(keepCapacity: false)
        if let currentActionSet = currentActionSet {
            let cActions = currentActionSet.actions
            var generator = cActions.generate()
            while let act = generator.next(){
                actions.append(act)
            }
        }
        actionsTableView.reloadData()
    }

    @IBAction func executeActionSet(sender: AnyObject) {
        if let currentHome = Core.sharedInstance.currentHome {
            currentHome.executeActionSet(currentActionSet!) {
                error in
                if error != nil {
                    NSLog("Failed executing action set, error:\(error)")
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ActionCell", forIndexPath: indexPath) as UITableViewCell
        
        let action = actions[indexPath.row] as! HMCharacteristicWriteAction
        
        if let charDesc = HomeKitUUIDs[action.characteristic.characteristicType] {
            cell.textLabel?.text = charDesc
        }else{
            cell.textLabel?.text = action.characteristic.characteristicType
        }
        
        cell.detailTextLabel?.text = "Accessory: \(action.characteristic.service!.accessory!.name) | Target Value: \(action.targetValue)"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let _action = actions[indexPath.row] as! HMCharacteristicWriteAction
        
        let object = _action.characteristic
        var charDesc = object.characteristicType
        if let desc = HomeKitUUIDs[object.characteristicType] {
            charDesc = desc
        }
        switch (object.metadata!.format!) {
        case HMCharacteristicMetadataFormatBool:
            let alert:UIAlertController = UIAlertController(title: "Target \(charDesc)", message: "Please choose the target state for this action", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "On", style: UIAlertActionStyle.Default, handler:
                {
                    (action:UIAlertAction!) in
                    _action.updateTargetValue(true) {
                        error in
                        if error != nil {
                            NSLog("Failed adding action to action set, error: \(error)")
                        } else {
                            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                        }
                    }
            }))
            alert.addAction(UIAlertAction(title: "Off", style: UIAlertActionStyle.Default, handler:
                {
                    (action:UIAlertAction!) in
                    _action.updateTargetValue(false) {
                        error in
                        if error != nil {
                            NSLog("Failed adding action to action set, error: \(error)")
                        } else {
                            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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
                    let textField = alert.textFields![0]
                    let f = NSNumberFormatter()
                    f.numberStyle = NSNumberFormatterStyle.DecimalStyle
                    _action.updateTargetValue(f.numberFromString(textField.text!)!) {
                        error in
                        if error != nil {
                            NSLog("Failed adding action to action set, error: \(error)")
                        } else {
                            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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
                    let textField = alert.textFields![0]
                    _action.updateTargetValue(textField.text!) {
                        error in
                        if error != nil {
                            NSLog("Failed adding action to action set, error: \(error)")
                        } else {
                            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let action = actions[indexPath.row]
            self.currentActionSet?.removeAction(action) {
                [weak self]
                error in
                if error != nil {
                    NSLog("Failed removing action from action set, error:\(error)")
                } else {
                    self?.updateActions()
                }
            }
        }
    }

}
