//
//  ThermostatInterfaceController.swift
//  HomeKitWatch
//
//  Created by Khaos Tian on 1/3/15.
//  Copyright (c) 2015 Oltica. All rights reserved.
//

import WatchKit
import Foundation
import HomeKit

class ThermostatInterfaceController: WKInterfaceController, HMAccessoryDelegate {

    @IBOutlet weak var currentTempLabel: WKInterfaceLabel!
    @IBOutlet weak var targetTempLabel: WKInterfaceLabel!
    @IBOutlet weak var targetTempSlider: WKInterfaceSlider!
    
    var currentService:HMService!
    
    var currentTempChar: HMCharacteristic!
    var targetTempChar: HMCharacteristic!
    var targetMode: HMCharacteristic!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let context = context as? HMService {
            self.currentService = context
            
            if let name = self.currentService.accessory.name {
                self.setTitle("Thermostat")
            }
            
            for charactertistic in self.currentService.characteristics as [HMCharacteristic] {
                switch charactertistic.characteristicType {
                case HMCharacteristicTypeCurrentTemperature:
                    self.currentTempChar = charactertistic
                    if let value = self.currentTempChar.value as? Float {
                        self.currentTempLabel.setText("Current Temp: \(Int(value))°")
                    } else {
                        self.currentTempLabel.setText("Current Temp: ?°")
                    }
                case HMCharacteristicTypeTargetTemperature:
                    self.targetTempChar = charactertistic
                    if let value = self.targetTempChar.value as? Float {
                        self.targetTempLabel.setText("\(Int(value))°")
                        self.targetTempSlider.setValue(value)
                    } else {
                        self.targetTempLabel.setText("?°")
                        self.targetTempSlider.setEnabled(false)
                    }
                case HMCharacteristicTypeTargetHeatingCooling:
                    self.targetMode = charactertistic
                default:
                    NSLog("Unhandled Char:\(charactertistic)")
                }
            }
        }
        // Configure interface objects here.
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
    
    func updatesCharacteristicsNotifications(state: Bool) {
        if let characteristic = self.currentTempChar {
            characteristic.enableNotification(state, completionHandler: {
                error in
                if let error = error {
                    NSLog("Disable Notification fail, error:\(error)")
                }
            })
        }
        if let characteristic = self.targetTempChar {
            characteristic.enableNotification(state, completionHandler: {
                error in
                if let error = error {
                    NSLog("Disable Notification fail, error:\(error)")
                }
            })
        }
    }

    @IBAction func setTargetHeating() {
        self.targetMode.writeValue(1, completionHandler: {
            error in
            if let error = error {
                NSLog("Failed setting target mode to heating, error:\(error)")
            }
        })
    }
    
    @IBAction func setTargetCooling() {
        self.targetMode.writeValue(2, completionHandler: {
            error in
            if let error = error {
                NSLog("Failed setting target mode to cooling, error:\(error)")
            }
        })
    }
    
    @IBAction func didUpdateTargetTemp(value: Float) {
        self.targetTempLabel.setText("\(Int(value))°")
        self.targetTempChar.writeValue(value, completionHandler: {
            error in
            if let error = error {
                NSLog("Failed updating target temp, error:\(error)")
            }
        })
    }
    
    func accessory(accessory: HMAccessory, service: HMService, didUpdateValueForCharacteristic characteristic: HMCharacteristic) {
        switch characteristic {
        case self.currentTempChar:
            if let value = self.currentTempChar.value as? Float {
                self.currentTempLabel.setText("Current Temp: \(Int(value))°")
            }
        case self.targetTempChar:
            if let value = self.targetTempChar.value as? Float {
                self.targetTempLabel.setText("\(Int(value))°")
                self.targetTempSlider.setValue(value)
            }
        default:
            NSLog("Update for Char:\(characteristic)")
        }
    }
}
