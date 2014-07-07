//
//  OTIHomeCore.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 6/6/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import UIKit
import HomeKit

let OTIHomeCoreSharedInstance = OTIHomeCore()

class OTIHomeCore: NSObject,HMHomeManagerDelegate,HMHomeDelegate,HMAccessoryDelegate {
    class var sharedInstance:OTIHomeCore {
        return OTIHomeCoreSharedInstance
    }
    
    let homeManger:HMHomeManager = HMHomeManager()
    var primaryHome:HMHome!
    
    init() {
        super.init()
        
        homeManger.delegate = self
        if homeManger.primaryHome {
            primaryHome = homeManger.primaryHome
        }
    }
    
    func homeManagerDidUpdateHomes(manager: HMHomeManager!)
    {
        NSLog("homeManagerDidUpdateHomes: \(manager)")
        if homeManger.primaryHome {
            primaryHome = homeManger.primaryHome
            for accessory in primaryHome.accessories as [HMAccessory]{
                NSLog("Accessory: \(accessory)")
            }
        }
    }
    
    func homeManagerDidUpdatePrimaryHome(manager: HMHomeManager!)
    {
        NSLog("homeManagerDidUpdatePrimaryHome: \(manager)")
        if homeManger.primaryHome {
            primaryHome = homeManger.primaryHome
        }
    }
    
    func homeManager(manager: HMHomeManager!, didAddHome home: HMHome!)
    {
        NSLog("homeManager:didAddHome: \(home)")
    }
    
    func homeManager(manager: HMHomeManager!, didRemoveHome home: HMHome!)
    {
        NSLog("homeManager:didRemoveHome: \(home)")
    }
}