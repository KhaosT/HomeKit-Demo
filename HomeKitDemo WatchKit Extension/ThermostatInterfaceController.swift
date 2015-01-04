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

class ThermostatInterfaceController: WKInterfaceController {

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
                self.setTitle("\(name) - Thermo")
            }
            
            for charactertistic in self.currentService.characteristics as [HMCharacteristic] {
                switch charactertistic.characteristicType {
                case HMCharacteristicTypeCurrentTemperature:
                    self.currentTempChar = charactertistic
                    self.currentTempLabel.setText("Current Temp: \(self.currentTempChar.value)°")
                case HMCharacteristicTypeTargetTemperature:
                    self.targetTempChar = charactertistic
                    self.targetTempLabel.setText("\(Int(self.targetTempChar.value as Float))°")
                    self.targetTempSlider.setValue(self.targetTempChar.value as Float)
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
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
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
}
