//
//  BLEDelegate.swift
//  BLEDevicePackage
//
//  Created by mio kato on 2022/04/21.
//

import CoreBluetooth
import Foundation

public protocol BLEDelegate: AnyObject {
    func deviceFound(devName: String, mfgID: String, deviceID: String)
    func didConnect()
    func didDisconnect()
    func didSetNotify()
    func didReadManufacturerName(uuid: String, name: String)
    func didReadModelNumber(uuid: String, number: String)
    func didReadSerialNumber(uuid: String, number: String)
    func didReadHardwareRevision(uuid: String, revision: String)
    func didReadFirmwareRevision(uuid: String, revision: String)
    func didReadSoftwareRevision(uuid: String, revision: String)
    func eegSampleLefts(uuid: String, lefts: [Int16], rights: [Int16])
    func sensorStatus(uuid: String, status: Int32)
    func battery(uuid: String, percent: Int32)
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
}

public extension BLEDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {}
}
