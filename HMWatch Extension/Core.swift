//
//  Core.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 6/8/15.
//  Copyright © 2015 Nlr. All rights reserved.
//

import HomeKit

@available(watchOSApplicationExtension 20000, *)
class Core {
    static let sharedInstance: Core = Core()
    var versionIndex = 0
    var currentHome:HMHome! {
        didSet{
            versionIndex += 1
        }
    }
}
