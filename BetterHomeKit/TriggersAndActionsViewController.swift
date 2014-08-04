//
//  TriggersAndActionsViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 8/2/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class TriggersAndActionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    weak var currentHome:HMHome?
    
    var actAndTriggerArray = [AnyObject]()
    
    @IBOutlet weak var atTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateLocalArray()
        
        // Do any additional setup after loading the view.
    }
    
    func updateLocalArray () {
        actAndTriggerArray.removeAll(keepCapacity: false)
        if let currentHome = currentHome {
            actAndTriggerArray += currentHome.actionSets as [AnyObject]
            actAndTriggerArray += currentHome.triggers as [AnyObject]
        }
        atTableView.reloadData()
        
    }
    
    @IBAction func dismissView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return actAndTriggerArray.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier("actionCell", forIndexPath: indexPath) as UITableViewCell
        
        if let action = actAndTriggerArray[indexPath.row] as? HMActionSet {
            cell.textLabel.text = action.name
            cell.detailTextLabel.text = "ActionSet"
        }
        
        if let trigger = actAndTriggerArray[indexPath.row] as? HMTrigger {
            cell.textLabel.text = trigger.name
            var actions = trigger.actionSets.map{$0.name}
            var actionsText = "ActionSets: "
            for name in actions {
                actionsText += "\(name) "
            }
            cell.detailTextLabel.text = actionsText
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let action = actAndTriggerArray[indexPath.row] as? HMActionSet {
                currentHome?.removeActionSet(action) {
                    [weak self]
                    error in
                    if error != nil {
                        NSLog("Failed to remove ActionSet: \(error)")
                    }else{
                        self?.updateLocalArray()
                    }
                }
            }
            if let trigger = actAndTriggerArray[indexPath.row] as? HMTrigger {
                currentHome?.removeTrigger(trigger) {
                    [weak self]
                    error in
                    if error != nil {
                        NSLog("Failed to remove Trigger: \(error)")
                    }else{
                        self?.updateLocalArray()
                    }
                }
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
