//
//  TriggerViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 8/2/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class TriggerViewController: UIViewController {
    
    weak var currentHome:HMHome?
    weak var targetCharacteristic:HMCharacteristic?

    @IBOutlet weak var targetValueField: UITextField!
    @IBOutlet weak var targetState: UISwitch!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var nameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if targetCharacteristic?.metadata.format == (HMCharacteristicMetadataFormatBool as String) {
            targetValueField.hidden = true
            targetState.hidden = false
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveTrigger(sender: AnyObject) {
        if let targetCharacteristic = targetCharacteristic {
            var targetValue: AnyObject?
            
            switch (targetCharacteristic.metadata.format as NSString) {
            case HMCharacteristicMetadataFormatBool:
                targetValue = targetState.on
            case HMCharacteristicMetadataFormatInt,HMCharacteristicMetadataFormatFloat,HMCharacteristicMetadataFormatUInt8,HMCharacteristicMetadataFormatUInt16,HMCharacteristicMetadataFormatUInt32,HMCharacteristicMetadataFormatUInt64:
                let f = NSNumberFormatter()
                f.numberStyle = NSNumberFormatterStyle.DecimalStyle
                targetValue = f.numberFromString(targetValueField.text)
            case HMCharacteristicMetadataFormatString:
                targetValue = targetValueField.text
            default:
                NSLog("Unsupported")
            }
            
            let action = HMCharacteristicWriteAction(characteristic: targetCharacteristic, targetValue: targetValue)
            if let currentHome = currentHome {
                currentHome.addActionSetWithName(nameField.text) {
                    (actionSet: HMActionSet!, error: NSError!) in
                    if error != nil {
                        NSLog("Failed to add action set, Error: \(error)")
                    } else {
                        actionSet.addAction(action) {
                            error in
                            if error != nil {
                                NSLog("Failed to add Action to Action Set Error: \(error)")
                            }else {
                                let calendar = NSCalendar.currentCalendar()
                                let selectedDate = self.datePicker.date
                                let dateComp = calendar.components(NSCalendarUnit.CalendarUnitSecond | .CalendarUnitMinute | .CalendarUnitHour | .CalendarUnitDay | .CalendarUnitMonth | .CalendarUnitYear | .CalendarUnitEra , fromDate: selectedDate)
                                let trigger = HMTimerTrigger(name: self.nameField.text.stringByAppendingString("Trigger"), fireDate: calendar.dateWithEra(dateComp.era, year: dateComp.year, month: dateComp.month, day: dateComp.day, hour: dateComp.hour, minute: dateComp.minute, second: 0, nanosecond: 0), timeZone: nil, recurrence: nil, recurrenceCalendar: nil)
                                NSLog("Trigger FireDate:\(trigger.fireDate)")
                                self.currentHome?.addTrigger(trigger) {
                                    error in
                                    if error != nil {
                                        NSLog("Failed to add Time Trigger, Error: \(error)")
                                    } else {
                                        trigger.addActionSet(actionSet) {
                                            error in
                                            if error != nil {
                                                NSLog("Failed to add action set to Time Trigger, Error: \(error)")
                                            }else{
                                                trigger.enable(true) {
                                                    error in
                                                    if error != nil {
                                                        NSLog("Failed to enable the trigger, Error: \(error)")
                                                    } else {
                                                        self.navigationController.popViewControllerAnimated(true)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
