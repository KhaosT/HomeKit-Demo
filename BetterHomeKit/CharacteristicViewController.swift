//
//  CharacteristicViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 6/4/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class CharacteristicViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    @IBOutlet var characteristicTableView : UITableView
    var characteristics = NSMutableArray()
    
    var detailItem: HMService? {
    didSet {
        self.title = detailItem!.name
        // Update the view.
        self.configureView()
    }
    }
    
    @IBAction func renameService(sender : AnyObject) {
        let alert:UIAlertController = UIAlertController(title: "Rename Service", message: "Enter the name you want for this service. Siri should be able to take command with this name.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default, handler:
            {
                action in
                let textField = alert.textFields[0] as UITextField
                self.detailItem!.updateName(textField.text, completionHandler:
                    {
                        error in
                        if !error {
                            self.title = textField.text
                        } else {
                            NSLog("Error:\(error)")
                        }
                    }
                )
            }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        dispatch_async(dispatch_get_main_queue(),
            {
                self.presentViewController(alert, animated: true, completion: nil)
            })
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        for characteristic : HMCharacteristic! in detailItem!.characteristics {
            if !characteristics.containsObject(characteristic) {
                characteristics.addObject(characteristic)
                characteristicTableView?.insertRowsAtIndexPaths([NSIndexPath(forRow:0, inSection:0)], withRowAnimation: .Automatic)
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
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return characteristics.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        let object = characteristics[indexPath.row] as HMCharacteristic
        cell.textLabel.text = object.characteristicType
        if object.value {
            cell.detailTextLabel.text = "\(object.value)"
        }else{
            cell.detailTextLabel.text = ""
        }
        return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let object = characteristics[indexPath.row] as HMCharacteristic
        NSLog("Char:\(object.characteristicType) \n \(object.metadata) \n\n \(object.properties)")
        
        switch object.characteristicType as NSString {
        case HMCharacteristicTypeLocked,HMCharacteristicTypePowerState:
            if object.value {
                object.writeValue(!(object.value as Bool), completionHandler:
                    {
                        error in
                        if error {
                            NSLog("Change Char Error: \(error)")
                        }else{
                            dispatch_async(dispatch_get_main_queue(),
                                {
                                    tableView.cellForRowAtIndexPath(indexPath).detailTextLabel.text = "\(object.value)"
                                }
                            )
                        }
                    }
                )
            }
        case "public.hap.characteristic.endpoint-name":
            let alert:UIAlertController = UIAlertController(title: "Rename Endpoint", message: "Enter the name you want for this endpoint", preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler(nil)
            alert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default, handler:
                {
                    action in
                    let textField = alert.textFields[0] as UITextField
                    object.writeValue("\(textField.text)", completionHandler:
                        {
                            error in
                            if error {
                                NSLog("Change Char Error: \(error)")
                            }else{
                                dispatch_async(dispatch_get_main_queue(),
                                    {
                                        tableView.cellForRowAtIndexPath(indexPath).detailTextLabel.text = "\(object.value)"
                                    }
                                )
                            }
                        }
                    )
                }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            dispatch_async(dispatch_get_main_queue(),
                {
                    self.presentViewController(alert, animated: true, completion: nil)
                })
        case HMCharacteristicTypeTargetTemperature:
            let alert:UIAlertController = UIAlertController(title: "Adjust Temperature", message: "Enter the temperature from \(object.metadata.minimumValue) to \(object.metadata.maximumValue). Unit is \(object.metadata.units)", preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler(nil)
            alert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default, handler:
                {
                    action in
                    let textField = alert.textFields[0] as UITextField
                    object.writeValue("\(textField.text)", completionHandler:
                        {
                            error in
                            if error {
                                NSLog("Change Char Error: \(error)")
                            }else{
                                dispatch_async(dispatch_get_main_queue(),
                                    {
                                        tableView.cellForRowAtIndexPath(indexPath).detailTextLabel.text = "\(object.value)"
                                    }
                                )
                            }
                        }
                    )
                }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            dispatch_async(dispatch_get_main_queue(),
                {
                    self.presentViewController(alert, animated: true, completion: nil)
                })
        default:
            NSLog("Cannot Identify type")
        }
    }
    
}