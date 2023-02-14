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
    func didReadManufacturerName(name: String)
    func didReadModelNumber(number: String)
    func didReadSerialNumber(number: String)
    func didReadHardwareRevision(revision: String)
    func didReadFirmwareRevision(revision: String)
    func didReadSoftwareRevision(revision: String)
    func eegSampleLefts(uuid: String, lefts: [Int16], rights: [Int16])
    func sensorStatus(_ status: Int32)
    func battery(id: String, percent: Int32)
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
}

public extension BLEDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {}
}
