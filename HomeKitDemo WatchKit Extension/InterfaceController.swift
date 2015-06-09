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
    
    var permissionTimer: NSTimer?
    
    var isPresenting: Bool = false
    
    var homes: [HMHome]!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.addMenuItemWithItemIcon(WKMenuItemIcon.Add, title: "Add Home", action: "addHome")
        
        homeManager = HMHomeManager()
        homeManager.delegate = self
        
        permissionTimer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: Selector("showPermissionAlert"), userInfo: nil, repeats: false)
        // Configure interface objects here.
    }
    
    func showPermissionAlert() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        if !isPresenting {
            isPresenting = true
            let errorObject = ErrorObject(title: "Accept HomeKit Permission", details: "Please accept HomeKit permission on iOS side.")
            self.presentControllerWithName("ErrorInfoController", context: errorObject)
        }
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
    
    func addHome() {
        self.remoteAddHome(self)
    }
    
    func remoteAddHome(controller: WKInterfaceController) {
        controller.presentTextInputControllerWithSuggestions(["Home","Test Home","New Home"], allowedInputMode: WKTextInputMode.Plain, completion: {
            texts in
            if let texts = texts {
                if texts.count > 0 {
                    var homeName = texts[0] as! String
                    self.homeManager.addHomeWithName(homeName, completionHandler: {
                        home,error in
                        if let error = error {
                            NSLog("Failed adding home, error:\(error)")
                        } else {
                            controller.dismissController()
                            self.homes.append(home)
                            
                            if let index = self.homes.indexOf(home) {
                                self.homesTable.insertRowsAtIndexes(NSIndexSet(index: index), withRowType: "SingleLabelRow")
                                var row:SingleLabelRow = self.homesTable.rowControllerAtIndex(index) as! SingleLabelRow
                                var home = self.homeManager.homes[index] as! HMHome
                                row.textLabel.setText("\(home.name)")
                            }
                        }
                    })
                }
            }
        })
    }
    
    func updateHomes() {
        if isPresenting {
            isPresenting = false
            self.dismissController()
        }
        if let homes = self.homes {
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
        errorObject.actionButton = "Add Home"
        errorObject.action = self.remoteAddHome
        isPresenting = true
        self.presentControllerWithName("ErrorInfoController", context: errorObject)
    }
    
    func homeManagerDidUpdateHomes(manager: HMHomeManager) {
        NSLog("HomeManagerDidUpdateHomes")
        
        permissionTimer?.invalidate()
        permissionTimer = nil
        
        self.homes = manager.homes as [HMHome]
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
