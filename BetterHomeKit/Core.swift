import HomeKit
import CoreLocation

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
    
    var proximityManager: ProximityManager?
    
    init() {
        self.proximityManager = ProximityManager()
    }
    
    func getAccessoryWithIdentifier(uuid: NSUUID?) -> HMAccessory? {
        if let uuid = uuid {
            if let currentHome = currentHome {
                for accessory in currentHome.accessories as [HMAccessory] {
                    if accessory.identifier == uuid {
                        return accessory
                    }
                }
            }
        }
        
        return nil
    }
}

class ProximityManager {
    
    var locationDelegator: CLLocationDelegator?
    var locationManager: CLLocationManager?
    var beaconRegion: CLBeaconRegion?
    var isMonitoring: Bool = false
    
    var targetActionSet: HMActionSet?
    
    init() {
        self.locationDelegator = CLLocationDelegator(callback: self)
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self.locationDelegator!
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "e2c56db5-dffb-48d2-b060-d0f5a71096e0"), identifier: "MacBeacon");
        

        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Authorized {
            self.monitorBeacon()
        } else {
            self.locationManager?.requestAlwaysAuthorization()
        }
    }
    
    func monitorBeacon() {
        if !self.isMonitoring {
            NSLog("Start Monitoring Region:\(self.beaconRegion)")
            self.isMonitoring = true
            self.locationManager?.startUpdatingLocation()
            self.locationManager?.startMonitoringForRegion(self.beaconRegion)
        }
    }
    
    func authStatusDidUpdate(status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.Authorized {
            self.monitorBeacon()
        }
    }
    
    func didEnterRegion(region: CLRegion) {
        NSLog("Did Enter Region: \(region)")
        self.targetActionSet = Core.sharedInstance.currentHome?.actionSets[0] as? HMActionSet
        Core.sharedInstance.currentHome?.executeActionSet(self.targetActionSet!, completionHandler: { (error) -> Void in
            if let error = error {
                NSLog("Failed Execute ActionSet, error:\(error)")
            }
        })
    }
    
    func didExitRegion(region: CLRegion) {
        NSLog("Did Exit Region: \(region)")
    }
    
    class CLLocationDelegator: NSObject, CLLocationManagerDelegate {
        var callback:ProximityManager?
        
        init(callback: ProximityManager) {
            super.init()
            self.callback = callback
        }
        
        func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
            self.callback?.authStatusDidUpdate(status)
        }
        
        func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
            self.callback?.didEnterRegion(region)
        }
        
        func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
            self.callback?.didExitRegion(region)
        }
    }
}