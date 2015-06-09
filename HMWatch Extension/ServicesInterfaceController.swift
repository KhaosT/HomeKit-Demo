//
//  ServicesInterfaceController.swift
//  HomeKitWatch
//
//  Created by Khaos Tian on 1/3/15.
//  Copyright (c) 2015 Oltica. All rights reserved.
//

import WatchKit
import Foundation
import HomeKit

@available(watchOSApplicationExtension 20000, *)
class ServicesInterfaceController: WKInterfaceController, HMAccessoryDelegate {
    
    var currentAccessory: HMAccessory!
    @IBOutlet weak var servicesTable: WKInterfaceTable!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let context = context as? HMAccessory {
            self.currentAccessory = context
            self.setTitle(self.currentAccessory.name)
        }
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.currentAccessory.delegate = self
        self.updateServices()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateServices() {
        self.servicesTable.setNumberOfRows(self.currentAccessory.services.count, withRowType: "SingleLabelRow")
        for index in 0..<self.currentAccessory.services.count {
            let row:SingleLabelRow = self.servicesTable.rowControllerAtIndex(index) as! SingleLabelRow
            let service = self.currentAccessory.services[index] as HMService
            if let serviceDesc = HomeKitUUIDs[service.serviceType] {
                row.textLabel.setText("\(serviceDesc)")
            }else{
                row.textLabel.setText("\(service.serviceType)")
            }
        }
    }
    
    func accessoryDidUpdateServices(accessory: HMAccessory) {
        self.updateServices()
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        NSLog("Did Select Row:\(rowIndex)")
        let service = self.currentAccessory.services[rowIndex] as HMService
        switch service.serviceType {
        case HMServiceTypeLightbulb:
            NSLog("Light Bulb")
            self.pushControllerWithName("LightBulbController", context: service)
        case HMServiceTypeThermostat:
            NSLog("Thermostat")
            self.pushControllerWithName("ThermostatController", context: service)
        case HMServiceTypeLockMechanism:
            NSLog("Lock Mechanism")
            self.pushControllerWithName("LockMechanismVC", context: service)
        case HMServiceTypeGarageDoorOpener:
            NSLog("Garage")
            self.pushControllerWithName("GarageVC", context: service)
        default:
            NSLog("Other")
            self.presentControllerWithName("UnsupportedServiceController", context: nil)
        }
    }
}
