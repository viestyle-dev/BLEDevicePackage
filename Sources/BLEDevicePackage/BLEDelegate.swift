//
//  BLEDelegate.swift
//  BLEDevicePackage
//
//  Created by mio kato on 2022/04/21.
//

import CoreBluetooth
import Foundation

public protocol BLEDelegate: AnyObject {
    func bleDeviceDidFindPeripheral(name: String, manufacturerID: String, deviceID: String)
    func bleDeviceDidConnect(deviceType: DeviceType)
    func bleDeviceDidDisconnect()
    func bleDeviceDidUpdate(leftSamples: [Int16], rightSamples: [Int16])
    func bleDeviceDidUpdate(wearingStatus: WearingStatus)
    func bleDeviceDidUpdate(leftBattery: Int, rightBattery: Int)
    func bleDeviceDidSetNotify()
    
    func bleDeviceDidReadManufacturerName(deviceType: DeviceType, name: String)
    func bleDeviceDidReadModelNumber(deviceType: DeviceType, number: String)
    func bleDeviceDidReadSerialNumber(deviceType: DeviceType, number: String)
    func bleDeviceDidReadHardwareRevision(deviceType: DeviceType, revision: String)
    func bleDeviceDidReadFirmwareRevision(deviceType: DeviceType, revision: String)
    func bleDeviceDidReadSoftwareRevision(deviceType: DeviceType, revision: String)
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
}

public extension BLEDelegate {
    func bleDeviceDidReadManufacturerName(deviceType: DeviceType, name: String) {}
    func bleDeviceDidReadModelNumber(deviceType: DeviceType, number: String) {}
    func bleDeviceDidReadSerialNumber(deviceType: DeviceType, number: String) {}
    func bleDeviceDidReadHardwareRevision(deviceType: DeviceType, revision: String) {}
    func bleDeviceDidReadFirmwareRevision(deviceType: DeviceType, revision: String) {}
    func bleDeviceDidReadSoftwareRevision(deviceType: DeviceType, revision: String) {}
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {}
}
