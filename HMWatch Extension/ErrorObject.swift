//
//  ErrorObject.swift
//  BetterHomeKit
//
//  Created by Khaos Tian on 1/3/15.
//  Copyright (c) 2015 Nlr. All rights reserved.
//

import Foundation
import WatchKit

class ErrorObject {
    var title: String?
    var details: String?
    
    var actionButton: String?
    var action: ((WKInterfaceController)->())?
    
    init(title: String, details: String) {
        self.title = title
        self.details = details
    }
}