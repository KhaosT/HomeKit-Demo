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
    
    @IBOutlet var characteristicTableView : UITableView?
    var characteristics = [HMCharacteristic]()
    
    var hueCharacteristic:HMCharacteristic?
    var brightnessCharacteristic:HMCharacteristic?
    var saturationCharacteristic:HMCharacteristic?
    var onCharacteristic:HMCharacteristic?
    
    weak var currentHome:HMHome?
    
    var detailItem: HMService? {
    didSet {
        self.title = detailItem!.name
        // Update the view.
        self.configureView()
    }
    }
    
    @IBOutlet var colorButton: UIBarButtonItem?
    
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
                        if error == nil {
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier? == "showColorPicker" {
            (segue.destinationViewController as ColorPickerViewController).delegate = self
        }
        if segue.identifier? == "presentTriggerView" {
            if let characteristic = sender as? HMCharacteristic {
                (segue.destinationViewController as TriggerViewController).currentHome = currentHome
                (segue.destinationViewController as TriggerViewController).targetCharacteristic = characteristic
            }
        }
    }
    
    func configureView() {
        if detailItem?.serviceType == (HMServiceTypeLightbulb as String) {
            if let colorButton = colorButton {
                colorButton.enabled = true
            }
        }else{
            if let colorButton = colorButton {
                colorButton.enabled = false
            }
        }
        
        // Update the user interface for the detail item.
        for characteristic in detailItem!.characteristics as [HMCharacteristic] {
            if colorButton?.enabled == true {
                if characteristic.characteristicType == (HMCharacteristicTypeBrightness as String) {
                    brightnessCharacteristic = characteristic
                }
                
                if characteristic.characteristicType == (HMCharacteristicTypeHue as String) {
                    hueCharacteristic = characteristic
                }
                
                if characteristic.characteristicType == (HMCharacteristicTypeSaturation as String) {
                    saturationCharacteristic = characteristic
                }
                
                if characteristic.characteristicType == (HMCharacteristicTypePowerState as String) {
                    onCharacteristic = characteristic
                }
            }
            
            if !contains(characteristics, characteristic) {
                characteristics.append(characteristic)
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didUpdateValueForCharacteristic:", name: characteristicUpdateNotification, object: nil)
        for characteristic in characteristics {
            if (characteristic.properties as NSArray).containsObject(HMCharacteristicPropertySupportsEventNotification) {
                characteristic.enableNotification(true, completionHandler:
                    {
                        error in
                        if (error != nil) {
                            NSLog("Cannot enable notifications: \(error)")
                        }
                    }
                )
            }
            if (characteristic.properties as NSArray).containsObject(HMCharacteristicPropertyReadable) {
                characteristic.readValueWithCompletionHandler(
                    {
                        [weak self]
                        (error:NSError!) in
                        if (error != nil) {
                            NSLog("Error read Char: \(characteristic), error: \(error)")
                        }else{
                            if let strongSelf = self {
                                let index = find(strongSelf.characteristics, characteristic)
                                strongSelf.characteristicTableView?.reloadRowsAtIndexPaths([NSIndexPath(forRow: index!, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Fade)
                            }
                            
                        }
                    }
                )
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        for characteristic in characteristics {
            if contains(characteristic.properties as [String], HMCharacteristicPropertySupportsEventNotification as String) {
                characteristic.enableNotification(false, completionHandler:
                    {
                        error in
                        if (error != nil) {
                            NSLog("Cannot disable notifications: \(error)")
                        }
                    }
                )
            }
        }
        self.characteristicTableView?.setEditing(false, animated: true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func didUpdateValueForCharacteristic(aNote:NSNotification) {
        if let info = aNote.userInfo {
            if let characteristic = info["characteristic"] as? HMCharacteristic {
                NSLog("DidUpdate Value for Chara:\(characteristic), value:\(characteristic.value)")
                if contains(characteristics, characteristic) {
                    if let index = find(characteristics, characteristic) {
                        if let cell = self.characteristicTableView?.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) {
                            dispatch_async(dispatch_get_main_queue(),
                                {
                                    if let value = characteristic.value as? NSObject {
                                        cell.textLabel.text = "\(value)"
                                    }else{
                                        cell.textLabel.text = ""
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    func updateLightWithColor(color:UIColor!) {
        var HSBA = [CGFloat](count: 4, repeatedValue: 0.0)
        color.getHue(&HSBA[0], saturation: &HSBA[1], brightness: &HSBA[2], alpha: &HSBA[3])
        
        if let hueChar = hueCharacteristic {
            let hueValue = NSNumber(integer: Int(Float(HSBA[0]) * hueChar.metadata.maximumValue.floatValue))
            hueChar.writeValue(hueValue, completionHandler:
                {
                    error in
                    if let error = error {
                        NSLog("Failed to update Hue \(error)")
                    }
                }
            )
        }
        
        if let brightChar = brightnessCharacteristic {
            let brightValue = NSNumber(integer: Int(Float(HSBA[2]) * brightChar.metadata.maximumValue.floatValue))
            brightChar.writeValue(brightValue, completionHandler:
                {
                    error in
                    if let error = error {
                        NSLog("Failed to update Brightness \(error)")
                    }
                }
            )
        }
        
        if let satChar = saturationCharacteristic {
            let satValue = NSNumber(integer: Int(Float(HSBA[1]) * satChar.metadata.maximumValue.floatValue))
            satChar.writeValue(satValue, completionHandler:
                {
                    error in
                    if let error = error {
                        NSLog("Failed to update Saturation \(error)")
                    }
                }
            )
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
        if let charDesc = HomeKitUUIDs[object.characteristicType] as? String {
            cell.detailTextLabel.text = charDesc
        }else{
            cell.detailTextLabel.text = object.characteristicType
        }
        if (object.value != nil) {
            cell.textLabel.text = "\(object.value)"
        }else{
            cell.textLabel.text = ""
        }
        return cell
    }
    
    func tableView(tableView: UITableView!, editActionsForRowAtIndexPath indexPath: NSIndexPath!) -> [AnyObject]! {
        
        var options = [UITableViewRowAction]()
        
        let triggerAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Trigger", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                if let strongSelf = self {
                    let characteristic = strongSelf.characteristics[indexPath.row] as HMCharacteristic
                    NSLog("Setup Trigger for \(characteristic)")
                    strongSelf.performSegueWithIdentifier("presentTriggerView", sender: characteristic)
                    tableView.setEditing(false, animated: true)
                }
            }
        )
        triggerAction.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        
        options.append(triggerAction)
        
        return options
    }
    
    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let characteristic = characteristics[indexPath.row] as HMCharacteristic
        if contains((characteristic.properties as [String]), (HMCharacteristicPropertyWritable as String)) {
            return true
        }
        return false
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let object = characteristics[indexPath.row] as HMCharacteristic
        
        if !(object.properties as NSArray).containsObject(HMCharacteristicPropertyWritable) {
            return
        }
        
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
                    if (error != nil) {
                        NSLog("Change Char Error: \(error)")
                    }
                }
            )
        default:
            var charDesc = object.characteristicType
            charDesc = HomeKitUUIDs[object.characteristicType] as? String
            switch (object.metadata.format as NSString) {
            case HMCharacteristicMetadataFormatBool:
                if (object.value != nil) {
                    object.writeValue(!(object.value as Bool), completionHandler:
                        {
                            (error:NSError!) in
                            if (error != nil) {
                                NSLog("Change Char Error: \(error)")
                            }else{
                                dispatch_async(dispatch_get_main_queue(),
                                    {
                                        tableView.cellForRowAtIndexPath(indexPath).textLabel.text = "\(object.value)"
                                    }
                                )
                            }
                        }
                    )
                }
            case HMCharacteristicMetadataFormatInt,HMCharacteristicMetadataFormatFloat,HMCharacteristicMetadataFormatUInt8,HMCharacteristicMetadataFormatUInt16,HMCharacteristicMetadataFormatUInt32,HMCharacteristicMetadataFormatUInt64:
                let alert:UIAlertController = UIAlertController(title: "Adjust \(charDesc)", message: "Enter the value from \(object.metadata.minimumValue) to \(object.metadata.maximumValue). Unit is \(object.metadata.units)", preferredStyle: .Alert)
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
                                if (error != nil) {
                                    NSLog("Change Char Error: \(error)")
                                }else{
                                    dispatch_async(dispatch_get_main_queue(),
                                        {
                                            tableView.cellForRowAtIndexPath(indexPath).textLabel.text = "\(object.value)"
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
            case HMCharacteristicMetadataFormatString:
                let alert:UIAlertController = UIAlertController(title: "Update \(charDesc)", message: "Enter the \(charDesc) from \(object.metadata.minimumValue) to \(object.metadata.maximumValue). Unit is \(object.metadata.units)", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler(nil)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let textField = alert.textFields[0] as UITextField
                        object.writeValue("\(textField.text)", completionHandler:
                            {
                                (error:NSError!) in
                                if (error != nil) {
                                    NSLog("Change Char Error: \(error)")
                                }else{
                                    dispatch_async(dispatch_get_main_queue(),
                                        {
                                            tableView.cellForRowAtIndexPath(indexPath).textLabel.text = "\(object.value)"
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
                NSLog("Unsupported")
            }
        }
    }
    
}