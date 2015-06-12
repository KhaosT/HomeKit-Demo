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
    
    @IBOutlet var characteristicTableView : UITableView!
    var characteristics = [HMCharacteristic]()
    
    var hueCharacteristic:HMCharacteristic?
    var brightnessCharacteristic:HMCharacteristic?
    var saturationCharacteristic:HMCharacteristic?
    var onCharacteristic:HMCharacteristic?
    
    var databaseIndex: Int?
    var accessoryIdentifier: NSUUID?
    var serviceNameCache: String?
    
    var detailItem: HMService? {
    didSet {
        self.title = detailItem?.name
        
        databaseIndex = Core.sharedInstance.versionIndex
        accessoryIdentifier = detailItem!.accessory!.identifier
        serviceNameCache = detailItem?.name
        
        // Update the view.
        self.configureView()
    }
    }
    
    @IBOutlet var colorButton: UIBarButtonItem?
    
    @IBAction func renameService(sender : AnyObject) {
        let alert:UIAlertController = UIAlertController(title: "Rename Service", message: "Enter the name you want for this service. Siri should be able to take command with this name.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.Default, handler:
            {
                (action:UIAlertAction!) in
                let textField = alert.textFields![0]
                self.detailItem!.updateName(textField.text!, completionHandler:
                    {
                        error in
                        if error == nil {
                            self.title = textField.text
                        } else {
                            NSLog("Error:\(error)")
                        }
                    }
                )
            }))
        dispatch_async(dispatch_get_main_queue(),
            {
                self.presentViewController(alert, animated: true, completion: nil)
            })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showColorPicker" {
            (segue.destinationViewController as! ColorPickerViewController).delegate = self
            (segue.destinationViewController as! ColorPickerViewController).initialColor = currentLightColor()
        }
        
        if segue.identifier == "startActionAssignProcess" {
            (segue.destinationViewController as! ActionSetsViewController).pendingCharacteristic = Characteristic(hmChar: (sender as! HMCharacteristic))
        }
    }
    
    func currentLightColor() -> UIColor {
        var hue:CGFloat?
        var brightness:CGFloat?
        var saturation:CGFloat?
        
        if let hueChar = self.hueCharacteristic {
            let hueValue:NSNumber = (hueChar.value as? NSNumber) ?? (0.0 as NSNumber)
            let hueRatio:NSNumber = hueChar.metadata!.maximumValue!
            hue = CGFloat(hueValue.floatValue / hueRatio.floatValue)
        }
        
        if let brightnessChar = self.brightnessCharacteristic {
            let brightnessValue:NSNumber = (brightnessChar.value as? NSNumber) ?? (0.0 as NSNumber)
            let brightnessRatio:NSNumber = brightnessChar.metadata!.maximumValue!
            brightness = CGFloat(brightnessValue.floatValue / brightnessRatio.floatValue)
        }
        
        if let saturationChar = self.saturationCharacteristic {
            let saturationValue:NSNumber = (saturationChar.value as? NSNumber) ?? (0.0 as NSNumber)
            let saturationRatio:NSNumber = saturationChar.metadata!.maximumValue!
            saturation = CGFloat(saturationValue.floatValue / saturationRatio.floatValue)
        }
        
        return UIColor(hue: (hue ?? 0.0), saturation: (saturation ?? 0.0), brightness: (brightness ?? 0.0), alpha: 1.0)
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
        
        characteristics.removeAll(keepCapacity: true)
        
        // Update the user interface for the detail item.
        for characteristic in detailItem!.characteristics {
            if colorButton?.enabled == true {
                if characteristic.characteristicType == HMCharacteristicTypeBrightness {
                    brightnessCharacteristic = characteristic
                }
                
                if characteristic.characteristicType == HMCharacteristicTypeHue {
                    hueCharacteristic = characteristic
                }
                
                if characteristic.characteristicType == HMCharacteristicTypeSaturation {
                    saturationCharacteristic = characteristic
                }
                
                if characteristic.characteristicType == HMCharacteristicTypePowerState {
                    onCharacteristic = characteristic
                }
            }
            
            if !characteristics.contains(characteristic) {
                characteristics.append(characteristic)
            }
        }
        characteristicTableView?.reloadData()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
    
    func invalidateLocalCache() {
        if databaseIndex != Core.sharedInstance.versionIndex {
            NSLog("Invalidate Characteristic Local Cache")
            if let accessory = Core.sharedInstance.getAccessoryWithIdentifier(accessoryIdentifier) {
                for service in accessory.services {
                    if service.name == serviceNameCache {
                        detailItem = service
                        break
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "invalidateLocalCache", name: homeUpdateNotification, object: nil)
        invalidateLocalCache()
        configureView()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didUpdateValueForCharacteristic:", name: characteristicUpdateNotification, object: nil)
        for aChar in characteristics {
            if aChar.properties.contains(HMCharacteristicPropertySupportsEventNotification) {
                aChar.enableNotification(true, completionHandler:
                    {
                        error in
                        if (error != nil) {
                            NSLog("Cannot enable notifications: \(error)")
                        }
                    }
                )
            }
            if aChar.properties.contains(HMCharacteristicPropertyReadable) {
                aChar.readValueWithCompletionHandler(
                    {
                        [weak self]
                        error in
                        if (error != nil) {
                            NSLog("Error read Char: \(aChar), error: \(error)")
                        }else{
                            if let strongSelf = self {
                                let index = strongSelf.characteristics.indexOf(aChar)
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
            if characteristic.properties.contains(HMCharacteristicPropertySupportsEventNotification) {
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
                if characteristics.contains(characteristic) {
                    if let index = characteristics.indexOf(characteristic) {
                        if let cell = self.characteristicTableView?.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) {
                            dispatch_async(dispatch_get_main_queue(),
                                {
                                    if let value = characteristic.value as? NSObject {
                                        cell.textLabel?.text = "\(value)"
                                    } else {
                                        cell.textLabel?.text = ""
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
            let hueValue = NSNumber(integer: Int(Float(HSBA[0]) * hueChar.metadata!.maximumValue!.floatValue))
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
            let brightValue = NSNumber(integer: Int(Float(HSBA[2]) * brightChar.metadata!.maximumValue!.floatValue))
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
            let satValue = NSNumber(integer: Int(Float(HSBA[1]) * satChar.metadata!.maximumValue!.floatValue))
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return characteristics.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    func generateGeneralCell(tableView: UITableView, indexPath: NSIndexPath, object: HMCharacteristic) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        
        if let charDesc = HomeKitUUIDs[object.characteristicType] {
            cell.detailTextLabel?.text = charDesc
        }else{
            cell.detailTextLabel?.text = object.characteristicType
        }
        if (object.value != nil) {
            cell.textLabel?.text = "\(object.value!)"
        }else{
            cell.textLabel?.text = ""
        }
        return cell
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let object = characteristics[indexPath.row] as HMCharacteristic
        
        return generateGeneralCell(tableView, indexPath: indexPath, object: object)
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        var options = [UITableViewRowAction]()
        
        let triggerAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Action", handler:
            {
                [weak self]
                (action:UITableViewRowAction!, indexPath:NSIndexPath!) in
                if let strongSelf = self {
                    let characteristic = strongSelf.characteristics[indexPath.row] as HMCharacteristic
                    strongSelf.performSegueWithIdentifier("startActionAssignProcess", sender: characteristic)
                    tableView.setEditing(false, animated: true)
                }
            }
        )
        triggerAction.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        
        options.append(triggerAction)
        
        return options
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let characteristic = characteristics[indexPath.row] as HMCharacteristic
        if characteristic.properties.contains(HMCharacteristicPropertyWritable) {
            return true
        }
        return false
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let object = characteristics[indexPath.row] as HMCharacteristic
        
        if !object.properties.contains(HMCharacteristicPropertyWritable) {
            return
        }
        
        NSLog("Char:\(object.characteristicType)")
        
        if let metadata = object.metadata {
            print("Meta:\(metadata)")
        }
        
        NSLog("Properties:\(object.properties)")

        switch object.characteristicType {
        case HMCharacteristicTypeIdentify:
            object.writeValue(true, completionHandler:
                {
                    error in
                    if (error != nil) {
                        NSLog("Change Char Error: \(error)")
                    }
                }
            )
        default:
            var charDesc = object.characteristicType
            if let desc = HomeKitUUIDs[object.characteristicType] {
                charDesc = desc
            }
            switch (object.metadata!.format!) {
            case HMCharacteristicMetadataFormatBool:
                if (object.value != nil) {
                    object.writeValue(!(object.value as! Bool), completionHandler:
                        {
                            error in
                            if (error != nil) {
                                NSLog("Change Char Error: \(error)")
                            }else{
                                dispatch_async(dispatch_get_main_queue(),
                                    {
                                        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                                            cell.textLabel?.text = "\(object.value!)"
                                        }
                                    }
                                )
                            }
                        }
                    )
                } else {
                    object.writeValue(true, completionHandler:
                        {
                            error in
                            if (error != nil) {
                                NSLog("Change Char Error: \(error)")
                            }
                        }
                    )
                }
            case HMCharacteristicMetadataFormatInt,HMCharacteristicMetadataFormatFloat,HMCharacteristicMetadataFormatUInt8,HMCharacteristicMetadataFormatUInt16,HMCharacteristicMetadataFormatUInt32,HMCharacteristicMetadataFormatUInt64:
                let alert:UIAlertController = UIAlertController(title: "Adjust \(charDesc)", message: "Enter the value from \(object.metadata!.minimumValue) to \(object.metadata!.maximumValue). Unit is \(object.metadata!.units)", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler(nil)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let textField = alert.textFields![0]
                        let f = NSNumberFormatter()
                        f.numberStyle = NSNumberFormatterStyle.DecimalStyle
                        object.writeValue(f.numberFromString(textField.text!)!, completionHandler:
                            {
                                error in
                                if (error != nil) {
                                    NSLog("Change Char Error: \(error)")
                                }else{
                                    dispatch_async(dispatch_get_main_queue(),
                                        {
                                            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                                                cell.textLabel?.text = "\(object.value!)"
                                            }
                                        }
                                    )
                                }
                            }
                        )
                    }))
                dispatch_async(dispatch_get_main_queue(),
                    {
                        self.presentViewController(alert, animated: true, completion: nil)
                    })
            case HMCharacteristicMetadataFormatString:
                let alert:UIAlertController = UIAlertController(title: "Update \(charDesc)", message: "Enter the \(charDesc) from \(object.metadata!.minimumValue) to \(object.metadata!.maximumValue). Unit is \(object.metadata!.units)", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler(nil)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:
                    {
                        (action:UIAlertAction!) in
                        let textField = alert.textFields![0]
                        object.writeValue("\(textField.text!)", completionHandler:
                            {
                                error in
                                if (error != nil) {
                                    NSLog("Change Char Error: \(error)")
                                }else{
                                    dispatch_async(dispatch_get_main_queue(),
                                        {
                                            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                                                cell.textLabel?.text = "\(object.value!)"
                                            }
                                        }
                                    )
                                }
                            }
                        )
                    }))
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