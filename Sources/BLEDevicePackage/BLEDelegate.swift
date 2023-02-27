//
//  BLEDelegate.swift
//  BLEDevicePackage
//
//  Created by mio kato on 2022/04/21.
//

import CoreBluetooth
import Foundation

public protocol BLEDelegate: AnyObject {
    func didFindDevice(name: String, deviceID: String)
    func didConnect(deviceType: DeviceType)
    func didDisconnect()
    func didUpdateEEGLeft(values: [Int16])
    func didUpdateEEGRight(values: [Int16])
    func didUpdateSensorStatusLeft(status: Int32)
    func didUpdateSensorStatusRight(status: Int32)
    func didUpdateBatteryLeft(percent: Int32)
    func didUpdateBatteryRight(percent: Int32)
    
    func didReadManufacturerName(deviceType: DeviceType, name: String)
    func didReadModelNumber(deviceType: DeviceType, number: String)
    func didReadSerialNumber(deviceType: DeviceType, number: String)
    func didReadHardwareRevision(deviceType: DeviceType, revision: String)
    func didReadFirmwareRevision(deviceType: DeviceType, revision: String)
    func didReadSoftwareRevision(deviceType: DeviceType, revision: String)
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
}

public extension BLEDelegate {
    func didReadManufacturerName(deviceType: DeviceType, name: String) {}
    func didReadModelNumber(deviceType: DeviceType, number: String) {}
    func didReadSerialNumber(deviceType: DeviceType, number: String) {}
    func didReadHardwareRevision(deviceType: DeviceType, revision: String) {}
    func didReadFirmwareRevision(deviceType: DeviceType, revision: String) {}
    func didReadSoftwareRevision(deviceType: DeviceType, revision: String) {}
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {}
}
