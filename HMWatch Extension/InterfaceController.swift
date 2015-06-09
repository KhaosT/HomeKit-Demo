//
//  InterfaceController.swift
//  HMWatch Extension
//
//  Created by Khaos Tian on 6/8/15.
//  Copyright © 2015 Nlr. All rights reserved.
//

import WatchKit
import Foundation
import HomeKit


@available(watchOSApplicationExtension 20000, *)
class InterfaceController: WKInterfaceController, HMHomeManagerDelegate {
    @IBOutlet weak var homesTable: WKInterfaceTable!

    var homeManager: HMHomeManager!
    var homes: [HMHome]!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        homeManager = HMHomeManager()
        homeManager.delegate = self
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.updateHomes()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateHomes() {
        if self.homes != nil {
            if self.homes.count == 0 {
                self.presentNoHomeVC()
            } else {
                self.homesTable.setNumberOfRows(self.homes.count, withRowType: "SingleLabelRow")
                for index in 0..<self.homes.count {
                    let row:SingleLabelRow = self.homesTable.rowControllerAtIndex(index) as! SingleLabelRow
                    let home = self.homes[index]
                    row.textLabel.setText("\(home.name)")
                }
            }
        }
        
    }
    
    func presentNoHomeVC() {
        let errorObject = ErrorObject(title: "No Home Available", details: "Please make sure there is at least one home in HomeKit database.")
        self.presentControllerWithName("ErrorInfoController", context: errorObject)
    }
    
    func homeManagerDidUpdateHomes(manager: HMHomeManager) {
        NSLog("HomeManagerDidUpdateHomes")
        
        self.homes = manager.homes
        self.updateHomes()
    }
    
    func homeManager(manager: HMHomeManager, didAddHome home: HMHome) {
        self.homes.append(home)
        
        if let index = self.homes.indexOf(home) {
            self.homesTable.insertRowsAtIndexes(NSIndexSet(index: index), withRowType: "SingleLabelRow")
            let row:SingleLabelRow = self.homesTable.rowControllerAtIndex(index) as! SingleLabelRow
            let home = self.homeManager.homes[index] as HMHome
            row.textLabel.setText("\(home.name)")
        }
    }
    
    func homeManager(manager: HMHomeManager, didRemoveHome home: HMHome) {
        if let index = self.homes.indexOf(home) {
            self.homesTable.removeRowsAtIndexes(NSIndexSet(index: index))
            self.homes.removeAtIndex(index)
        }
        
        if self.homes.count == 0 {
            self.presentNoHomeVC()
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        NSLog("Did Select Row:\(rowIndex)")
        let home = self.homeManager.homes[rowIndex] as HMHome
        self.pushControllerWithName("AccessoriesController", context: home)
    }
}
