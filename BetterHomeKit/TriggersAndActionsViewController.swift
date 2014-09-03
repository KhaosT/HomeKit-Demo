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
    
    @IBOutlet weak var atTableView: UITableView!
    
    @IBAction func dismissView(sender: AnyObject) {
        self.atTableView.setEditing(false, animated: true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tableCell", forIndexPath: indexPath) as UITableViewCell
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Action Sets"
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "Triggers"
        }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 0:
            self.performSegueWithIdentifier("presentActionSets", sender: nil)
        case 1:
            self.performSegueWithIdentifier("presentTriggers", sender: nil)
        default:
            NSLog("Something Wrong at here :(")
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}
