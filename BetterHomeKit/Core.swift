import HomeKit

private let _sharedCore = Core()

class Core {
    class var sharedInstance : Core {
        return _sharedCore
    }
    
    var versionIndex = 0
    var currentHome:HMHome? {
        didSet{
            versionIndex += 1
        }
    }
    
    init() {
        
    }
    
    func getAccessoryWithIdentifier(uuid: NSUUID?) -> HMAccessory? {
        if let uuid = uuid {
            if let currentHome = currentHome {
                for accessory in currentHome.accessories {
                    if accessory.identifier == uuid {
                        return accessory
                    }
                }
            }
        }
        
        return nil
    }
}