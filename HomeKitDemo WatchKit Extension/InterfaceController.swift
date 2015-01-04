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
        self.updateHomes()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func addHome() {
        self.presentTextInputControllerWithSuggestions(["Home","Test Home","New Home"], allowedInputMode: WKTextInputMode.Plain, completion: {
            texts in
            if let texts = texts {
                if texts.count > 0 {
                    var homeName = texts[0] as String
                    self.homeManager.addHomeWithName(homeName, completionHandler: {
                        home,error in
                        if let error = error {
                            NSLog("Failed adding home, error:\(error)")
                        } else {
                            self.updateHomes()
                        }
                    })
                }
            }
        })
    }
    
    func updateHomes() {
        self.dismissController()
        if self.homeManager.homes.count == 0 {
            var errorInfo = ["title":"No Home Available","details":"Please make sure there is at least one home in HomeKit database."];
            self.presentControllerWithName("ErrorInfoController", context: errorInfo)
        } else {
            self.homesTable.setNumberOfRows(self.homeManager.homes.count, withRowType: "SingleLabelRow")
            for index in 0..<self.homeManager.homes.count {
                var row:SingleLabelRow = self.homesTable.rowControllerAtIndex(index) as SingleLabelRow
                var home = self.homeManager.homes[index] as HMHome
                row.textLabel.setText("\(home.name)")
            }
        }
    }
    
    func homeManagerDidUpdateHomes(manager: HMHomeManager!) {
        NSLog("HomeManagerDidUpdateHomes")
        
        if permissionTimer != nil {
            permissionTimer.invalidate()
            permissionTimer = nil
        }
        
        self.updateHomes()
    }
    
    func homeManager(manager: HMHomeManager!, didAddHome home: HMHome!) {
        self.updateHomes()
    }
    
    func homeManager(manager: HMHomeManager!, didRemoveHome home: HMHome!) {
        self.updateHomes()
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        NSLog("Did Select Row:\(rowIndex)")
        var home = self.homeManager.homes[rowIndex] as HMHome
        self.pushControllerWithName("AccessoriesController", context: home)
    }
}
