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
    func didConnect(uuid: String)
    func didDisconnect()
    func didSetNotify()
    func didReadManufacturerName(uuid: String, name: String)
    func didReadModelNumber(uuid: String, number: String)
    func didReadSerialNumber(uuid: String, number: String)
    func didReadHardwareRevision(uuid: String, revision: String)
    func didReadFirmwareRevision(uuid: String, revision: String)
    func didReadSoftwareRevision(uuid: String, revision: String)
    func didUpdateEEGLeft(values: [Int16])
    func didUpdateEEGRight(values: [Int16])
    func didUpdateSensorStatusLeft(status: Int32)
    func didUpdateSensorStatusRight(status: Int32)
    func didUpdateBatteryLeft(percent: Int32)
    func didUpdateBatteryRight(percent: Int32)
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
}

public extension BLEDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {}
}
