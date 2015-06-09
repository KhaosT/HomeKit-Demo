//
//  HomeKitDefines.swift
//
//  Created by Khaos Tian on 7/22/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

import Foundation
import HomeKit

@available(watchOSApplicationExtension 20000, *)
let HomeKitUUIDs = [
    HMServiceTypeLightbulb:"Light Bulb",
    HMServiceTypeSwitch:"Switch",
    HMServiceTypeThermostat:"Thermostat",
    HMServiceTypeGarageDoorOpener:"Garage Door Opener",
    HMServiceTypeAccessoryInformation:"Accessory Info",
    HMServiceTypeFan:"Fan",
    HMServiceTypeOutlet:"Outlet",
    HMServiceTypeLockMechanism:"Lock Mechanism",
    HMServiceTypeLockManagement:"Lock Management",
    HMCharacteristicTypePowerState:"Power State",
    HMCharacteristicTypeHue:"Hue",
    HMCharacteristicTypeSaturation:"Saturation",
    HMCharacteristicTypeBrightness:"Brightness",
    HMCharacteristicTypeTemperatureUnits:"Temperature Units",
    HMCharacteristicTypeCurrentTemperature:"Current Temperature",
    HMCharacteristicTypeTargetTemperature:"Target Temperature",
    HMCharacteristicTypeCurrentHeatingCooling:"Current Heating Cooling",
    HMCharacteristicTypeTargetHeatingCooling:"Target Heating Cooling",
    HMCharacteristicTypeCoolingThreshold:"Cooling Threshold",
    HMCharacteristicTypeHeatingThreshold:"Heating Threshold",
    HMCharacteristicTypeCurrentRelativeHumidity:"Current Relative Humidity",
    HMCharacteristicTypeTargetRelativeHumidity:"Target Relative Humidity",
    HMCharacteristicTypeCurrentDoorState:"Current Door State",
    HMCharacteristicTypeTargetDoorState:"Target Door State",
    HMCharacteristicTypeObstructionDetected:"Obstruction Detected",
    HMCharacteristicTypeName:"Name",
    HMCharacteristicTypeManufacturer:"Manufacturer",
    HMCharacteristicTypeModel:"Model",
    HMCharacteristicTypeSerialNumber:"Serial Number",
    HMCharacteristicTypeIdentify:"Identify",
    HMCharacteristicTypeRotationDirection:"Rotation Direction",
    HMCharacteristicTypeRotationSpeed:"Rotation Speed",
    HMCharacteristicTypeOutletInUse:"Outlet In Use",
    HMCharacteristicTypeVersion:"Version",
    HMCharacteristicTypeLogs:"Logs",
    HMCharacteristicTypeAudioFeedback:"Audio Feedback",
    HMCharacteristicTypeAdminOnlyAccess:"Admin Only Access",
    HMCharacteristicTypeMotionDetected:"Motion Detected",
    HMCharacteristicTypeCurrentLockMechanismState:"Current Lock Mechanism State",
    HMCharacteristicTypeTargetLockMechanismState:"Target Lock Mechanism State",
    HMCharacteristicTypeLockMechanismLastKnownAction:"Lock Mechanism Last Known Action",
    HMCharacteristicTypeLockManagementControlPoint:"Lock Management Control Point",
    HMCharacteristicTypeLockManagementAutoSecureTimeout:"Lock Management Auto Secure Timeout"
]