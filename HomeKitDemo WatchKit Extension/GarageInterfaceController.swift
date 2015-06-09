//
//  GarageInterfaceController.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 5/13/15.
//  Copyright (c) 2015 Nlr. All rights reserved.
//

import WatchKit
import Foundation
import HomeKit

class GarageInterfaceController: WKInterfaceController, HMAccessoryDelegate {

    @IBOutlet weak var currentStateLabel: WKInterfaceLabel!
    @IBOutlet weak var currentLockLabel: WKInterfaceLabel!
    @IBOutlet weak var targetDoorStateSwitch: WKInterfaceSwitch!
    @IBOutlet weak var targetLockState: WKInterfaceSwitch!
    
    var currentService: HMService!
    var currentDoorStateChar: HMCharacteristic!
    var targetDoorStateChar: HMCharacteristic!
    var lockCurrentStateChar: HMCharacteristic!
    var lockTargetStateChar: HMCharacteristic!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let context = context as? HMService {
            self.currentService = context
            
            for charactertistic in self.currentService.characteristics as [HMCharacteristic] {
                switch charactertistic.characteristicType {
                case HMCharacteristicTypeCurrentDoorState:
                    self.currentDoorStateChar = charactertistic
                    if let value = self.currentDoorStateChar.value as? Int {
                        self.updateCurrentDoorState(value)
                    }
                case HMCharacteristicTypeTargetDoorState:
                    self.targetDoorStateChar = charactertistic
                    if let value = self.targetDoorStateChar.value as? Int {
                        self.targetDoorStateSwitch.setOn(value == 0)
                    }
                    if self.currentService.accessory.reachable {
                        self.targetDoorStateSwitch.setEnabled(true)
                    }
                case HMCharacteristicTypeCurrentLockMechanismState:
                    self.lockCurrentStateChar = charactertistic
                    if let value = self.lockCurrentStateChar.value as? Int {
                        self.updateCurrentLockState(value)
                    }
                case HMCharacteristicTypeTargetLockMechanismState:
                    self.lockTargetStateChar = charactertistic
                    if let value = self.lockTargetStateChar.value as? Int {
                        self.targetLockState.setOn(value == 1)
                    }
                    if self.currentService.accessory.reachable {
                        self.targetLockState.setEnabled(true)
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
        self.currentService.accessory.delegate = self
        self.updatesCharacteristicsNotifications(true)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        self.updatesCharacteristicsNotifications(false)
    }
    
    func updateCurrentDoorState(value: Int) {
        switch value {
        case 0:
            self.currentStateLabel.setText("Current: Open")
        case 1:
            self.currentStateLabel.setText("Current: Closed")
        case 2:
            self.currentStateLabel.setText("Current: Opening")
        case 3:
            self.currentStateLabel.setText("Current: Closing")
        case 4:
            self.currentStateLabel.setText("Current: Stopped")
        default:
            self.currentStateLabel.setText("Current: Unknown")
        }
    }
    
    func updateCurrentLockState(value: Int) {
        switch value {
        case 0:
            self.currentLockLabel.setText("Lock: Unsecured")
        case 1:
            self.currentLockLabel.setText("Lock: Secured")
        case 2:
            self.currentLockLabel.setText("Lock: Jammed")
        default:
            self.currentLockLabel.setText("Lock: Unknown")
        }
    }
    
    func updatesCharacteristicsNotifications(state: Bool) {
        if let characteristic = self.currentDoorStateChar {
            characteristic.enableNotification(state, completionHandler: {
                error in
                if let error = error {
                    NSLog("Notification fail, error:\(error)")
                }
            })
        }
        if let characteristic = self.targetDoorStateChar {
            characteristic.enableNotification(state, completionHandler: {
                error in
                if let error = error {
                    NSLog("Notification fail, error:\(error)")
                }
            })
        }
        if let characteristic = self.lockCurrentStateChar {
            characteristic.enableNotification(state, completionHandler: {
                error in
                if let error = error {
                    NSLog("Notification fail, error:\(error)")
                }
            })
        }
        if let characteristic = self.lockTargetStateChar {
            characteristic.enableNotification(state, completionHandler: {
                error in
                if let error = error {
                    NSLog("Notification fail, error:\(error)")
                }
            })
        }
    }

    @IBAction func didChangeTargetDoorState(value: Bool) {
        self.targetDoorStateChar.writeValue(!value, completionHandler: {
            error in
            if let error = error {
                NSLog("Failed updating target door state")
            }
        })
    }
    
    @IBAction func didChangeTargetLockState(value: Bool) {
        self.lockTargetStateChar.writeValue(value, completionHandler: {
            error in
            if let error = error {
                NSLog("Failed updating target lock state")
            }
        })
    }
    
    func accessory(accessory: HMAccessory, service: HMService, didUpdateValueForCharacteristic characteristic: HMCharacteristic) {
        switch characteristic {
        case self.currentDoorStateChar:
            if let value = self.currentDoorStateChar.value as? Int {
                self.updateCurrentDoorState(value)
            }
        case self.targetDoorStateChar:
            if let value = self.targetDoorStateChar.value as? Int {
                self.targetDoorStateSwitch.setOn(value == 0)
            }
        case self.lockCurrentStateChar:
            if let value = self.lockCurrentStateChar.value as? Int {
                self.updateCurrentLockState(value)
            }
        case self.lockTargetStateChar:
            if let value = self.lockTargetStateChar.value as? Int {
                self.targetLockState.setOn(value == 1)
            }
        default:
            NSLog("Update for Char:\(characteristic)")
        }
    }
}
