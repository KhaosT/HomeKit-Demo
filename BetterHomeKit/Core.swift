import HomeKit

private let _sharedCore = Core()

class Core {
    class var sharedInstance : Core {
        return _sharedCore
    }
    
    var currentHome:HMHome?
    
    init() {
        
    }
}