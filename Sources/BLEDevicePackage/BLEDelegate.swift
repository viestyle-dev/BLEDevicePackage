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
    func bleDeviceDidConnect()
    func bleDeviceDidDisconnect()
    func bleDeviceDidUpdateData(leftValues: [Int16], rightValues: [Int16])
    func bleDeviceDidUpdateSensor(status: Int)
    func bleDeviceDidUpdateBattery(percent: Int)
    
    func bleDeviceDidSetNotify()
    func bleDeviceDidReadManufacturerName(name: String)
    func bleDeviceDidReadModelNumber(number: String)
    func bleDeviceDidReadSerialNumber(number: String)
    func bleDeviceDidReadHardwareRevision(revision: String)
    func bleDeviceDidReadFirmwareRevision(revision: String)
    func bleDeviceDidReadSoftwareRevision(revision: String)
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
}

public extension BLEDelegate {
    func bleDeviceDidSetNotify() {}
    func bleDeviceDidReadManufacturerName(name: String) {}
    func bleDeviceDidReadModelNumber(number: String) {}
    func bleDeviceDidReadSerialNumber(number: String) {}
    func bleDeviceDidReadHardwareRevision(revision: String) {}
    func bleDeviceDidReadFirmwareRevision(revision: String) {}
    func bleDeviceDidReadSoftwareRevision(revision: String) {}
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {}
}
