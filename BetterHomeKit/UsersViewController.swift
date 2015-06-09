//
//  UsersViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 8/6/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class UsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var usersTableView: UITableView!
    
    lazy var usersArray = [HMUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUsers()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.usersTableView.setEditing(false, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchUsers() {
        usersArray.removeAll(keepCapacity: false)
        if let currentHome = Core.sharedInstance.currentHome {
            for user in currentHome.users as [HMUser]{
                usersArray.append(user)
            }
        }
        usersTableView.reloadData()
    }
    
    @IBAction func addUser(sender: AnyObject) {
        /*let alert = UIAlertController(title: "New User", message: "Enter the iCloud address of user you want to add. (The users list will get updated once user accept the invitation.)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler:
            {
                [weak self]
                (action:UIAlertAction!) in
                let textField = alert.textFields?[0] as UITextField
                Core.sharedInstance.currentHome?.addUserWithCompletionHandler {
                    user, error in
                    if error != nil {
                        NSLog("Add user failed: \(error)")
                    } else {
                        self?.fetchUsers()
                    }
                }
        }))*/
        Core.sharedInstance.currentHome?.addUserWithCompletionHandler {
            user, error in
            if error != nil {
                NSLog("Add user failed: \(error)")
                if error!.code == 41 {
                    let alert = UIAlertController(title: "Failed", message: "Failed to add user to home. Normally this happens because not all accessories are reachable. Please try again after all accessories are reachable.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            } else {
                self.fetchUsers()
            }
        }
        /*dispatch_async(dispatch_get_main_queue(),
            {
                self.presentViewController(alert, animated: true, completion: nil)
        })*/
    }

    @IBAction func dismissVC(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel?.text = usersArray[indexPath.row].name
        cell.detailTextLabel?.text = "User"
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let userID = usersArray[indexPath.row]
            Core.sharedInstance.currentHome?.removeUser(userID) {
                [weak self]
                error in
                if error != nil {
                    NSLog("Failed removing user, error:\(error)")
                } else {
                    self?.fetchUsers()
                }
            }
        }
    }
    
}
