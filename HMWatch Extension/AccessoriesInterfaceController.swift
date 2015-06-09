//
//  AccessoriesInterfaceController.swift
//  HomeKitWatch
//
//  Created by Khaos Tian on 1/3/15.
//  Copyright (c) 2015 Oltica. All rights reserved.
//

import WatchKit
import Foundation
import HomeKit

@available(watchOSApplicationExtension 20000, *)
class AccessoriesInterfaceController: WKInterfaceController, HMHomeDelegate {

    var currentHome: HMHome!
    @IBOutlet weak var accessoriesTable: WKInterfaceTable!
    @IBOutlet weak var noAccessoryGroup: WKInterfaceGroup!
    
    var accessories: [HMAccessory]!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        NSLog("Context:\(context)")
        // Configure interface objects here.
        if let context = context as? HMHome {
            self.currentHome = context
            self.currentHome.delegate = self
            self.setTitle(self.currentHome.name)
            Core.sharedInstance.currentHome = self.currentHome
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.accessories = self.currentHome.accessories as [HMAccessory]
        self.updateAccessories()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateAccessories() {
        if self.accessories.count == 0 {
            self.noAccessoryGroup.setHidden(false)
        } else {
            self.noAccessoryGroup.setHidden(true)
        }
        
        self.accessoriesTable.setNumberOfRows(self.accessories.count, withRowType: "SingleLabelRow")
        for index in 0..<self.accessories.count {
            let row:SingleLabelRow = self.accessoriesTable.rowControllerAtIndex(index) as! SingleLabelRow
            let accessory = self.accessories[index] as HMAccessory
            row.textLabel.setText("\(accessory.name)")
        }
    }
    
    func home(home: HMHome, didAddAccessory accessory: HMAccessory) {
        self.accessories.append(accessory)
        
        if let index = self.accessories.indexOf(accessory) {
            self.accessoriesTable.insertRowsAtIndexes(NSIndexSet(index: index), withRowType: "SingleLabelRow")
            let row:SingleLabelRow = self.accessoriesTable.rowControllerAtIndex(index) as! SingleLabelRow
            let accessory = self.currentHome.accessories[index] as HMAccessory
            row.textLabel.setText("\(accessory.name)")
        }
        
        self.noAccessoryGroup.setHidden(true)
        
    }
    
    func home(home: HMHome, didRemoveAccessory accessory: HMAccessory) {
        if let index = self.accessories.indexOf(accessory) {
            self.accessories.removeAtIndex(index)
            self.accessoriesTable.removeRowsAtIndexes(NSIndexSet(index: index))
        }
        if self.accessories.count == 0 {
            self.noAccessoryGroup.setHidden(false)
        }
    }

    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        NSLog("Did Select Row:\(rowIndex)")
        let accessory = self.currentHome.accessories[rowIndex] as HMAccessory
        self.pushControllerWithName("ServicesController", context: accessory)
    }
}
