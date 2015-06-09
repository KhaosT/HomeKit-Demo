//
//  Core.swift
//  HomeKitWatch
//
//  Created by Khaos Tian on 1/3/15.
//  Copyright (c) 2015 Oltica. All rights reserved.
//

import HomeKit

@available(watchOSApplicationExtension 20000, *)
private let _sharedCore = Core()

@available(watchOSApplicationExtension 20000, *)
class Core {
    class var sharedInstance : Core {
        return _sharedCore
    }
    
    var versionIndex = 0
    var currentHome:HMHome! {
        didSet{
            versionIndex += 1
        }
    }
    
    init() {
        
    }
}