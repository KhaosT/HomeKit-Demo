//
//  DetailViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 6/4/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class ServiceViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,HMAccessoryDelegate {

    @IBOutlet var servicesTableView : UITableView?
    var services = [HMService]()
    
    var currentIdentifier: NSUUID?
    var databaseIndex: Int?
    
    var detailItem: HMAccessory? {
        didSet {
            self.title = detailItem?.name
            databaseIndex = Core.sharedInstance.versionIndex
            currentIdentifier = detailItem?.identifier.copy() as? NSUUID
            // Update the view.
            self.configureView()
        }
    }
    
    @IBAction func renameService(sender : AnyObject) {
        let alert:UIAlertController = UIAlertController(title: "Rename Accessory", message: "Enter the name you want for this accessory", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default, handler:
            {
                (action:UIAlertAction!) in
                let textField = alert.textFields?[0]
                self.detailItem!.updateName(textField!.text!, completionHandler: {
                    error in
                    if error != nil {
                        NSLog("Error:\(error)")
                    } else {
                        self.title = textField!.text
                    }
                })
            }))
        dispatch_async(dispatch_get_main_queue(),
            {
                self.presentViewController(alert, animated: true, completion: nil)
            })
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        services.removeAll(keepCapacity: true)
        if let detailItem = detailItem {
            for service in detailItem.services as [HMService] {
                if !services.contains(service) {
                    services.append(service)
                }
            }
            servicesTableView?.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "invalidateLocalCache", name: homeUpdateNotification, object: nil)
        invalidateLocalCache()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func invalidateLocalCache() {
        if databaseIndex != Core.sharedInstance.versionIndex {
            detailItem = Core.sharedInstance.getAccessoryWithIdentifier(currentIdentifier)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showCharacteristic" {
            let indexPath = servicesTableView?.indexPathForSelectedRow
            if let indexPath = indexPath {
                let object = services[indexPath.row] as HMService
                servicesTableView?.deselectRowAtIndexPath(indexPath, animated: true)
                (segue.destinationViewController as! CharacteristicViewController).detailItem = object
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let object = services[indexPath.row]
        cell.textLabel?.text = object.name
        if let serviceDesc = HomeKitUUIDs[object.serviceType] {
            cell.detailTextLabel?.text = serviceDesc
        }else{
            cell.detailTextLabel?.text = object.serviceType
        }
        
        return cell
    }
    
    func accessoryDidUpdateName(accessory: HMAccessory) {
        NSLog("accessoryDidUpdateName \(accessory)")
    }
    
    func accessory(accessory: HMAccessory, didUpdateNameForService service: HMService) {
        NSLog("\(accessory) didUpdateNameForService \(service.name)")
    }
    
    func accessoryDidUpdateServices(accessory: HMAccessory) {
        NSLog("accessoryDidUpdateServices \(accessory.services)")
    }
    
    func accessoryDidUpdateReachability(accessory: HMAccessory) {
        NSLog("accessoryDidUpdateReachability \(accessory.reachable)")
    }
    
    func accessory(accessory: HMAccessory, service: HMService, didUpdateValueForCharacteristic characteristic: HMCharacteristic) {
        NSLog("didUpdateValueForCharacteristic \(characteristic)")
    }

}

