//
//  LockMechanismInterfaceController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 1/16/15.
//  Copyright (c) 2015 Nlr. All rights reserved.
//

import WatchKit
import Foundation
import HomeKit

@available(watchOSApplicationExtension 20000, *)
class LockMechanismInterfaceController: WKInterfaceController, HMAccessoryDelegate {

    @IBOutlet weak var currentStateLabel: WKInterfaceLabel!
    @IBOutlet weak var lockSwitch: WKInterfaceSwitch!
    
    var currentService:HMService!
    
    var currentLockChar: HMCharacteristic!
    var targetLockChar: HMCharacteristic!
    
    var currentStates = ["Unsecured","Secured","Jammed","Unknown"]
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        if let context = context as? HMService {
            self.currentService = context
            
            self.setTitle("Lock")
            
            for charactertistic in self.currentService.characteristics as [HMCharacteristic] {
                switch charactertistic.characteristicType {
                case HMCharacteristicTypeCurrentLockMechanismState:
                    self.currentLockChar = charactertistic
                    if let value = self.currentLockChar.value as? Int {
                        self.currentStateLabel.setText("\(currentStates[value])")
                    } else {
                        self.currentStateLabel.setText("?")
                    }
                case HMCharacteristicTypeTargetLockMechanismState:
                    self.targetLockChar = charactertistic
                    if !self.currentService.accessory!.reachable {
                        self.lockSwitch.setEnabled(false)
                    }
                    if let value = self.targetLockChar.value as? Int {
                        if value == 0 {
                            self.lockSwitch.setOn(false)
                        } else {
                            self.lockSwitch.setOn(true)
                        }
                    }
                default:
                    NSLog("Unhandled Char:\(charactertistic)")
                }
            }
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.currentService.accessory?.delegate = self
        self.updatesCharacteristicsNotifications(true)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        self.updatesCharacteristicsNotifications(false)
    }
    
    func updatesCharacteristicsNotifications(state: Bool) {
        if let characteristic = self.currentLockChar {
            characteristic.enableNotification(state, completionHandler: {
                error in
                if let error = error {
                    NSLog("Disable Notification fail, error:\(error)")
                }
            })
        }
        if let characteristic = self.targetLockChar {
            characteristic.enableNotification(state, completionHandler: {
                error in
                if let error = error {
                    NSLog("Disable Notification fail, error:\(error)")
                }
            })
        }
    }
    
    @IBAction func changeLockState(value: Bool) {
        let targetState:Int = value ? 1 : 0
        self.targetLockChar.writeValue(targetState, completionHandler: {
            error in
            if let error = error {
                NSLog("Failed Updating Lock State")
            }
        })
    }
    
    
    func accessory(accessory: HMAccessory, service: HMService, didUpdateValueForCharacteristic characteristic: HMCharacteristic) {
        switch characteristic {
        case self.currentLockChar:
            if let value = self.currentLockChar.value as? Int {
                self.currentStateLabel.setText("\(currentStates[value])")
            } else {
                self.currentStateLabel.setText("?")
            }
        case self.targetLockChar:
            NSLog("Target Lock")
            if let value = self.targetLockChar.value as? Int {
                if value == 0 {
                    self.lockSwitch.setOn(false)
                } else {
                    self.lockSwitch.setOn(true)
                }
            }
        default:
            NSLog("Update for Char:\(characteristic)")
        }
    }
}
