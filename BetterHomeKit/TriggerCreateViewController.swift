//
//  TriggerViewController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 8/2/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

class TriggerCreateViewController: UIViewController, UITextFieldDelegate {
    weak var pendingTrigger:HMTimerTrigger?
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var repeatSwitch: UISwitch!
    @IBOutlet weak var repeatDaily: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let pendingTrigger = pendingTrigger {
            nameField.text = pendingTrigger.name
            datePicker.date = pendingTrigger.fireDate
            if pendingTrigger.recurrence != nil {
                if pendingTrigger.recurrence!.minute == 5 {
                    repeatSwitch.on = true
                    repeatDaily.enabled = false
                }
                
                if pendingTrigger.recurrence!.day == 1 {
                    repeatDaily.on = true
                    repeatSwitch.enabled = false
                }
                
            } else {
                repeatSwitch.on = false
                repeatDaily.on = false
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameField {
            nameField.resignFirstResponder()
        }
        return false
    }
    
    @IBAction func switchStateChanged(sender: UISwitch) {
        if sender == repeatSwitch {
            repeatDaily.on = false
            repeatDaily.enabled = !sender.on
        }
        if sender == repeatDaily {
            repeatSwitch.on = false
            repeatSwitch.enabled = !sender.on
        }
    }
    
    @IBAction func saveTrigger(sender: AnyObject) {
        if let pendingTrigger = pendingTrigger {
            let triggerName = self.nameField.text
            let calendar = NSCalendar.currentCalendar()
            let selectedDate = self.datePicker.date
            let dateComp = calendar.components([NSCalendarUnit.Second, .Minute, .Hour, .Day, .Month, .Year, .Era] , fromDate: selectedDate)
            let fireDate = calendar.dateWithEra(dateComp.era, year: dateComp.year, month: dateComp.month, day: dateComp.day, hour: dateComp.hour, minute: dateComp.minute, second: 0, nanosecond: 0)
            var recurrenceComp:NSDateComponents?
            
            if repeatSwitch.on || repeatDaily.on {
                recurrenceComp = NSDateComponents()
                if repeatSwitch.on {
                    recurrenceComp?.minute = 5
                }
                if repeatDaily.on {
                    recurrenceComp?.day = 1
                }
            }

            pendingTrigger.updateRecurrence(recurrenceComp) {
                error in
                if error != nil {
                    NSLog("Failed updating recurrence, error:\(error)")
                }
            }
            pendingTrigger.updateName(triggerName!) {
                error in
                if error != nil {
                    NSLog("Failed updating fire date, error:\(error)")
                }
            }
            pendingTrigger.updateFireDate(fireDate!) {
                error in
                if error != nil {
                    NSLog("Failed updating fire date, error:\(error)")
                } else {
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }
        } else {
            if let currentHome = Core.sharedInstance.currentHome {
                let triggerName = self.nameField.text
                let calendar = NSCalendar.currentCalendar()
                let selectedDate = self.datePicker.date
                let dateComp = calendar.components([NSCalendarUnit.Second, .Minute, .Hour, .Day, .Month, .Year, .Era] , fromDate: selectedDate)
                let fireDate = calendar.dateWithEra(dateComp.era, year: dateComp.year, month: dateComp.month, day: dateComp.day, hour: dateComp.hour, minute: dateComp.minute, second: 0, nanosecond: 0)
                
                var recurrenceComp:NSDateComponents?
                
                if repeatSwitch.on || repeatDaily.on {
                    recurrenceComp = NSDateComponents()
                    if repeatSwitch.on {
                        recurrenceComp?.minute = 5
                    }
                    if repeatDaily.on {
                        recurrenceComp?.day = 1
                    }
                }
                
                let trigger = HMTimerTrigger(name: triggerName!, fireDate: fireDate!, timeZone: nil, recurrence: recurrenceComp, recurrenceCalendar: nil)
                currentHome.addTrigger(trigger) {
                    [weak self]
                    error in
                    if error != nil {
                        NSLog("Failed to add Time Trigger, Error: \(error)")
                    } else {
                        self?.navigationController?.popViewControllerAnimated(true)
                    }
                }
            }
        }
    }
}
