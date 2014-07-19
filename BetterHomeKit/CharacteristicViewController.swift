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
    var characteristics = [HMCharacteristic]()
    
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
                (action:UIAlertAction!) in
                let textField = alert.textFields[0] as UITextField
                self.detailItem!.updateName(textField.text, completionHandler:
                    {
                        (error:NSError!) in
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
        for characteristic in detailItem!.characteristics as [HMCharacteristic] {
            if !contains(characteristics, characteristic) {
                characteristics += characteristic
                characteristicTableView?.insertRowsAtIndexPaths([NSIndexPath(forRow:0, inSection:0)], withRowAnimation: .Automatic)
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        for characteristic in characteristics {
            if (characteristic.properties as NSArray).containsObject(HMCharacteristicPropertyReadable) {
                characteristic.readValueWithCompletionHandler(
                    {
                        [weak self]
                        (error:NSError!) in
                        if error {
                            NSLog("Error read Char: \(characteristic), error: \(error)")
                        }else{
                            if let strongSelf = self {
                                let index = find(strongSelf.characteristics, characteristic)
                                strongSelf.characteristicTableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Fade)
                            }
                            
                        }
                    }
                )
            }
        }
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
        if let charaType = object.characteristicType {
            NSLog("Char:\(charaType)")
        }
        
        if let metadata = object.metadata {
            println("Meta:\(metadata)")
        }
        
        if let properties = object.properties {
            NSLog("Properties:\(properties)")
        }
        
        switch object.characteristicType as NSString {
        case HMCharacteristicTypeIdentify:
            object.writeValue(true, completionHandler:
                {
                    (error:NSError!) in
                    if error {
                        NSLog("Change Char Error: \(error)")
                    }
                }
            )
        case HMCharacteristicTypeHue,HMCharacteristicTypeSaturation,HMCharacteristicTypeBrightness:
            let alert:UIAlertController = UIAlertController(title: "Adjust \(object.characteristicType)", message: "Enter the value from \(object.metadata.minimumValue) to \(object.metadata.maximumValue). Unit is \(object.metadata.units)", preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler(nil)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:
                {
                    (action:UIAlertAction!) in
                    let textField = alert.textFields[0] as UITextField
                    let f = NSNumberFormatter()
                    f.numberStyle = NSNumberFormatterStyle.DecimalStyle
                    object.writeValue(f.numberFromString(textField.text), completionHandler:
                        {
                            (error:NSError!) in
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
        case HMCharacteristicTypeLocked,HMCharacteristicTypePowerState:
            if object.value {
                object.writeValue(!(object.value as Bool), completionHandler:
                    {
                        (error:NSError!) in
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
                    (action:UIAlertAction!) in
                    let textField = alert.textFields[0] as UITextField
                    object.writeValue("\(textField.text)", completionHandler:
                        {
                            (error:NSError!) in
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
                    (action:UIAlertAction!) in
                    let textField = alert.textFields[0] as UITextField
                    object.writeValue("\(textField.text)", completionHandler:
                        {
                            (error:NSError!) in
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