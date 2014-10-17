//
//  AddAccessoriesViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 6/4/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

let addAccessoryNotificationString = "DidAddHomeAccessory"

class AddAccessoriesViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,HMAccessoryBrowserDelegate {
    
    @IBOutlet var accessoriesTableView : UITableView!
    
    lazy var accessories = [HMAccessory]()
    
    var accessoriesManager:HMAccessoryBrowser = HMAccessoryBrowser()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Custom initialization
    }
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        accessoriesManager.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        accessoriesManager.startSearchingForNewAccessories()
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        accessoriesManager.stopSearchingForNewAccessories()
    }
    
    @IBAction func dismissAddAccessories(sender : AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return accessories.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("customCell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel.text = accessories[indexPath.row].name
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        Core.sharedInstance.currentHome?.addAccessory(accessories[indexPath.row], completionHandler:
            {
                (error:NSError!) in
                if error != nil {
                    NSLog("\(error)")
                }else{
                    NSNotificationCenter.defaultCenter().postNotificationName(addAccessoryNotificationString, object: nil)
                }
            }
        )
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath)
    {
        let accessory = accessories[indexPath.row]
        accessory.identifyWithCompletionHandler({
                (error:NSError!) in
                if error != nil {
                    println("Failed to identify \(error)")
                }
            })
    }
    
    func accessoryBrowser(browser: HMAccessoryBrowser!, didFindNewAccessory accessory: HMAccessory!)
    {
        if !contains(accessories, accessory) {
            accessories.insert(accessory, atIndex: 0)
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            accessoriesTableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func accessoryBrowser(browser: HMAccessoryBrowser!, didRemoveNewAccessory accessory: HMAccessory!)
    {
        if let index = find(accessories, accessory) {
            accessories.removeAtIndex(index)
            accessoriesTableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
        }
    }

}
