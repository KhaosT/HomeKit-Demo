import HomeKit

class Accessory {
    var internalAccessory: HMAccessory
    var databaseIndex: Int
    
    let accessoryIdentifier: NSUUID
    
    init(hmAccessory:HMAccessory) {
        internalAccessory = hmAccessory
        databaseIndex = Core.sharedInstance.versionIndex
        accessoryIdentifier = hmAccessory.identifier.copy() as! NSUUID
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleCacheInvalidation", name: homeUpdateNotification, object: nil)
    }
    
    @objc func handleCacheInvalidation() {
        if databaseIndex != Core.sharedInstance.versionIndex {
            NSLog("Invalidate Accessory Internal Cache")
            if let accessory = Core.sharedInstance.getAccessoryWithIdentifier(accessoryIdentifier) {
                internalAccessory = accessory
            }
        }
    }
    
    func toHMAccessory() -> HMAccessory {
        return internalAccessory
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

class Characteristic {
    var internalChar: HMCharacteristic
    
    let characteristicType: String
    let accessoryIdentifier: NSUUID
    let serviceName: String?
    let serviceType: String
    
    var databaseIndex: Int
    
    init(hmChar:HMCharacteristic) {
        internalChar = hmChar
        databaseIndex = Core.sharedInstance.versionIndex

        characteristicType = "\(hmChar.characteristicType)"
        accessoryIdentifier = hmChar.service!.accessory!.identifier.copy() as! NSUUID
        serviceName = hmChar.service!.name
        serviceType = hmChar.service!.serviceType
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleCacheInvalidation", name: homeUpdateNotification, object: nil)
    }
    
    @objc func handleCacheInvalidation() {
        if databaseIndex != Core.sharedInstance.versionIndex {
            NSLog("Invalidate Characteristic Internal Cache")
            if let accessory = Core.sharedInstance.getAccessoryWithIdentifier(accessoryIdentifier) {
                for service in accessory.services {
                    if service.serviceType == serviceType {
                        if service.name == serviceName {
                            for characteristic in service.characteristics {
                                if characteristic.characteristicType == characteristicType {
                                    NSLog("Recovered Characteristic")
                                    internalChar = characteristic
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func toHMCharacteristic() -> HMCharacteristic {
        return internalChar
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

class Room {
    var internalRoom: HMRoom
    
    let roomName: String
    var databaseIndex: Int
    
    init(hmRoom:HMRoom) {
        internalRoom = hmRoom
        roomName = internalRoom.name
        databaseIndex = Core.sharedInstance.versionIndex
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleCacheInvalidation", name: homeUpdateNotification, object: nil)
    }
    
    @objc func handleCacheInvalidation() {
        if databaseIndex != Core.sharedInstance.versionIndex {
            NSLog("Invalidate Room Internal Cache")
            if let currentHome = Core.sharedInstance.currentHome {
                for room in currentHome.rooms {
                    if room.name == roomName {
                        NSLog("Recovered Room")
                        internalRoom = room
                        return
                    }
                }
            }
        }
    }
    
    func toHMRoom() -> HMRoom {
        return internalRoom
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}