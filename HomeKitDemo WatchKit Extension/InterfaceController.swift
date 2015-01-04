//
//  InterfaceController.swift
//  HomeKitWatch WatchKit Extension
//
//  Created by Khaos Tian on 1/3/15.
//  Copyright (c) 2015 Oltica. All rights reserved.
//

import WatchKit
import Foundation
import HomeKit

class InterfaceController: WKInterfaceController, HMHomeManagerDelegate {

    var homeManager: HMHomeManager!
    @IBOutlet weak var homesTable: WKInterfaceTable!
    
    var permissionTimer: NSTimer!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        NSLog("Awake");
        homeManager = HMHomeManager()
        homeManager.delegate = self
        
        permissionTimer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "showPermissionAlert", userInfo: nil, repeats: false)
        // Configure interface objects here.
    }
    
    @objc func showPermissionAlert() {
        permissionTimer.invalidate()
        permissionTimer = nil
        var errorInfo = ["title":"Accept HomeKit Permission","details":"Please accept HomeKit permission on iOS side."];
        self.presentControllerWithName("ErrorInfoController", context: errorInfo)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func homeManagerDidUpdateHomes(manager: HMHomeManager!) {
        NSLog("HomeManagerDidUpdateHomes")
        
        if permissionTimer != nil {
            permissionTimer.invalidate()
            permissionTimer = nil
        }
        
        if manager.homes.count == 0 {
            var errorInfo = ["title":"No Home Available","details":"Please make sure there is at least one home in HomeKit database."];
            self.presentControllerWithName("ErrorInfoController", context: errorInfo)
        } else {
            self.homesTable.setNumberOfRows(manager.homes.count, withRowType: "SingleLabelRow")
            for index in 0..<manager.homes.count {
                var row:SingleLabelRow = self.homesTable.rowControllerAtIndex(index) as SingleLabelRow
                var home = manager.homes[index] as HMHome
                row.textLabel.setText("\(home.name)")
            }
        }
        
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        NSLog("Did Select Row:\(rowIndex)")
        var home = self.homeManager.homes[rowIndex] as HMHome
        self.pushControllerWithName("AccessoriesController", context: home)
    }
}
