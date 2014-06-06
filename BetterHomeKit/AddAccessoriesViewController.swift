//
//  AddAccessoriesViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 6/4/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class AddAccessoriesViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,HMAccessoryBrowserDelegate {

    @IBOutlet var accessoriesTableView : UITableView
    
    var accessories:NSMutableArray = NSMutableArray()
    
    weak var homeManager:HMHomeManager!
    
    var accessoriesManager:HMAccessoryBrowser = HMAccessoryBrowser()
    
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Custom initialization
    }
    
    init(coder aDecoder: NSCoder!){
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        accessoriesTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
        return accessories.count;
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
    {
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel.text = accessories.objectAtIndex(indexPath.row).name
        
        return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        homeManager.primaryHome.addAccessory(accessories.objectAtIndex(indexPath.row) as HMAccessory, completionHandler:
            {
                error in
                if error {
                    NSLog("\(error)")
                }
            }
        )
    }
    
    func accessoryBrowser(browser: HMAccessoryBrowser!, didFindNewAccessory accessory: HMAccessory!)
    {
        if !accessories.containsObject(accessories) {
            accessories.insertObject(accessory, atIndex: 0)
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            accessoriesTableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func accessoryBrowser(browser: HMAccessoryBrowser!, didRemoveNewAccessory accessory: HMAccessory!)
    {
        if accessories.containsObject(accessory) {
            let index = accessories.indexOfObject(accessory)
            accessories.removeObjectAtIndex(index)
            accessoriesTableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
        }
    }

    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
