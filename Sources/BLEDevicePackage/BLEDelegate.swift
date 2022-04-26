//
//  BLEDelegate.swift
//  CoreBluetoothStudy
//
//  Created by mio kato on 2022/04/21.
//

import Foundation
import CoreBluetooth

@objc protocol BLEDelegate {
    func deviceFound(devName: String, mfgID: String, deviceID: String)
    func didConnect()
    func didDisconnect()
    func eegSampleLeft(left: Int, right: Int)
    func sensorStatus(status: Int)
    func battery(percent: Int)
    @objc optional func centralManagerDidUpdateState(_ central: CBCentralManager)
    @objc optional func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral)
    @objc optional func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
}
