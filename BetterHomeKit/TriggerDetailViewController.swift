//
//  TriggerDetailViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 8/6/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class TriggerDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var actionSetTableView: UITableView!
    
    weak var currentTrigger:HMTrigger?
    
    var actionSets = [HMActionSet]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentTrigger = currentTrigger {
            self.title = "\(currentTrigger.name)"
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        updateActionSets()
    }
    
    func updateActionSets () {
        actionSets.removeAll(keepCapacity: false)
        if let currentTrigger = currentTrigger {
            actionSets += currentTrigger.actionSets as [HMActionSet]
        }
        actionSetTableView.reloadData()
    }
    
    @IBAction func addActionSet(sender: AnyObject) {
        self.performSegueWithIdentifier("showActionSetsSelection", sender: currentTrigger)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showActionSetsSelection" {
            let actionVC = segue.destinationViewController as! ActionSetsViewController
            actionVC.pendingTrigger = sender as? HMTrigger
        }
        if segue.identifier == "showActionSetDetails" {
            let actionVC = segue.destinationViewController as! ActionSetViewController
            actionVC.currentActionSet = sender as? HMActionSet
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionSets.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ActionSetCell", forIndexPath: indexPath) as UITableViewCell
        
        let actionSet = actionSets[indexPath.row] as HMActionSet
        
        cell.textLabel?.text = "\(actionSet.name)"
        cell.detailTextLabel?.text = "Actions:\(actionSet.actions.count)"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let actionSet = actionSets[indexPath.row]
        
        self.performSegueWithIdentifier("showActionSetDetails", sender: actionSet)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let actionSet = actionSets[indexPath.row]
            currentTrigger?.removeActionSet(actionSet) {
                error in
                if error != nil {
                    NSLog("Failed to remove action set from Trigger, error:\(error)")
                } else {
                    self.updateActionSets()
                }
            }
        }
    }
    
}