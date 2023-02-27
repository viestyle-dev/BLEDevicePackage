//
//  BLEDevice.swift
//  BLEDevicePackage
//
//  Created by mio kato on 2022/04/11.
//

import CoreBluetooth

#if os(iOS)

/// BLEDevice UUID
private enum DeviceUUID: String {
    // DeviceInfo (Read)
    case deviceInfoService = "180A"
    case manufacturerCharacteristic = "2A29"
    case modelNumberCharacteristic = "2A24"
    case serialNumberCharacteristic = "2A25"
    case firmwareRevCharacteristic = "2A26"
    case hardwareRevCharacteristic = "2A27"
    case softwareRevCharacteristic = "2A28"
    // Battery (Read)
    case batteryService = "180F"
    case batteryCharacteristic = "2A19"
    // EEG
    case eegService = "0B79FFF0-1ED1-2840-A9C3-87C6F6186DB3"
    case modeCharacteristic = "0B79FFA0-1ED1-2840-A9C3-87C6F6186DB3" // Write
    case statusCharacteristic = "0B79FFB0-1ED1-2840-A9C3-87C6F6186DB3" // Notify
    case streamCharacteristic = "0B79FFF6-1ED1-2840-A9C3-87C6F6186DB3" // Notify

    var uuid: CBUUID {
        CBUUID(string: rawValue)
    }
}

/// For Two BLE Example
public enum DeviceType {
    case left
    case right
}

public final class BLEDevice: NSObject {
    public static var shared = BLEDevice()

    private weak var delegate: BLEDelegate?

    private var centralManager: CBCentralManager!
    
    private let queue: DispatchQueue

    // 接続されたペリフェラル
    private var connectedPeripherals = [CBPeripheral]()
    private var leftPeriphralIdentifier: String?
    private var rightPeripheralIdentifier: String?

    private var modeCharacteristic = [String: CBCharacteristic]()
    private var batteryCharacteristic = [String: CBCharacteristic]()
    private var manufacturerNameCharacteristic = [String: CBCharacteristic]()
    private var modelNumberCharacteristic = [String: CBCharacteristic]()
    private var serialNumberCharacteristic = [String: CBCharacteristic]()
    private var hardwareRevisionCharacteristic = [String: CBCharacteristic]()
    private var firmwareRevisionCharacteristic = [String: CBCharacteristic]()
    private var softwareRevisionCharacteristic = [String: CBCharacteristic]()
    
    // 脳波検出開始コード
    private let startBytes: [UInt8] = [
        0x77, 0x01, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0xFD
    ]
    // 脳波検出停止コード
    private let stopBytes: [UInt8] = [
        0x77, 0x01, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0xFE
    ]
    
    override private init() {
        queue = DispatchQueue(label: "BLEDevice.bleQueue")

        super.init()

        centralManager = CBCentralManager(delegate: self, queue: queue)
    }

    // MARK: - Actions
    /// スキャン開始
    public func scanDevice() {
        let services = [DeviceUUID.deviceInfoService.uuid]
        centralManager.scanForPeripherals(withServices: services, options: nil)
    }

    /// スキャン停止
    public func stopScanDevice() {
        centralManager.stopScan()
    }

    /// 接続
    public func connect(_ deviceID: String, deviceType: DeviceType) {
        switch deviceType {
        case .left:
            leftPeriphralIdentifier = deviceID
        case .right:
            rightPeripheralIdentifier = deviceID
        }
        
        guard let leftUUIDString = leftPeriphralIdentifier else {
            return
        }
        
        guard let rightUUIDString = rightPeripheralIdentifier else {
            return
        }
        
        let uuidStrings = [leftUUIDString, rightUUIDString]
        let uuids = uuidStrings.map { UUID(uuidString: $0)! }
        
        // CBPeripheralは強参照で保持する必要がある(保持しないとエラーを送出して、データを取得できない)
        connectedPeripherals = centralManager.retrievePeripherals(withIdentifiers: uuids)
        for peripheral in connectedPeripherals {
            centralManager.connect(
                peripheral,
                options: [CBConnectPeripheralOptionEnableTransportBridgingKey: true]
            )
        }
    }

    /// 接続を解除
    public func disconnectDevice() {
        for peripheral in connectedPeripherals {
            for service in peripheral.services ?? [] as [CBService] {
                for characteristic in service.characteristics ?? [] as [CBCharacteristic] {
                    if characteristic.uuid == DeviceUUID.statusCharacteristic.uuid,
                       characteristic.isNotifying {
                        peripheral.setNotifyValue(false, for: characteristic)
                    }
                    if characteristic.uuid == DeviceUUID.modeCharacteristic.uuid,
                       characteristic.isNotifying {
                        peripheral.setNotifyValue(false, for: characteristic)
                    }
                }
            }
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripherals.removeAll()
        leftPeriphralIdentifier = nil
        rightPeripheralIdentifier = nil
    }

    /// 脳波の検出を開始
    public func start() {
        for peripheral in connectedPeripherals {
            guard let c = modeCharacteristic[peripheral.identifier.uuidString] else {
                continue
            }
            peripheral.writeValue(Data(self.startBytes), for: c, type: .withResponse)
        }
    }

    /// 脳波の検出を停止
    public func stop() {
        for peripheral in connectedPeripherals {
            guard let c = modeCharacteristic[peripheral.identifier.uuidString] else {
                continue
            }
            peripheral.writeValue(Data(stopBytes), for: c, type: .withResponse)
        }
    }
    
    // MARK: - Utils
    public func setDelegate(delegate: BLEDelegate) {
        self.delegate = delegate
    }

    func deviceType(fromUUIDString uuid: String) -> DeviceType? {
        guard let leftPeriphralIdentifier = leftPeriphralIdentifier,
              let rightPeripheralIdentifier = rightPeripheralIdentifier else {
            return nil
        }
        
        if uuid == leftPeriphralIdentifier {
            return .left
        } else if uuid == rightPeripheralIdentifier {
            return .right
        }
        return nil
    }
}

// MARK: - CBCentralManager Delegate
extension BLEDevice: CBCentralManagerDelegate {
    /// ペリフェラルを発見した
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let deviceName = peripheral.name else {
            return
        }

        DispatchQueue.main.sync {
            self.delegate?.didFindDevice(name: deviceName, deviceID: peripheral.identifier.uuidString)
        }
    }
        
    /// ペリフェラルに接続された
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([
            DeviceUUID.eegService.uuid,
            DeviceUUID.batteryService.uuid,
            DeviceUUID.deviceInfoService.uuid
        ])
        
        DispatchQueue.main.sync {
            self.delegate?.didConnect(uuid: peripheral.identifier.uuidString)
        }
    }

    /// ペリフェラルと接続が解除された
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.sync {
            self.delegate?.didDisconnect()
        }

        leftPeriphralIdentifier = nil
        rightPeripheralIdentifier = nil
    }

    /// ペリフェラルとの接続に失敗した
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.sync {
            self.delegate?.centralManager(central, didFailToConnect: peripheral, error: error)
        }
    }

    /// 状態が変化した
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.sync {
            self.delegate?.centralManagerDidUpdateState(central)
            switch central.state {
            case .poweredOn:
                break
            case .poweredOff, .resetting, .unauthorized, .unknown, .unsupported:
                break
            default:
                break
            }
        }
    }
}

// MARK: - Peripheral Delegate

extension BLEDevice: CBPeripheralDelegate {
    /// サービスを発見した
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: %s", error.localizedDescription)
            return
        }

        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            if service.uuid == DeviceUUID.deviceInfoService.uuid {
                peripheral.discoverCharacteristics([
                    DeviceUUID.manufacturerCharacteristic.uuid,
                    DeviceUUID.modelNumberCharacteristic.uuid,
                    DeviceUUID.serialNumberCharacteristic.uuid,
                    DeviceUUID.hardwareRevCharacteristic.uuid,
                    DeviceUUID.firmwareRevCharacteristic.uuid,
                    DeviceUUID.softwareRevCharacteristic.uuid
                ], for: service)
            }
            if service.uuid == DeviceUUID.batteryService.uuid {
                peripheral.discoverCharacteristics([
                    DeviceUUID.batteryCharacteristic.uuid,
                ], for: service)
            }
            if service.uuid == DeviceUUID.eegService.uuid {
                peripheral.discoverCharacteristics([
                    DeviceUUID.modeCharacteristic.uuid,
                    DeviceUUID.statusCharacteristic.uuid,
                    DeviceUUID.streamCharacteristic.uuid,
                ], for: service)
                print("service \(peripheral.identifier.uuidString)")
            }
        }
    }

    /// キャラクタリスティックを発見した
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: %s", error.localizedDescription)
            return
        }

        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics {
            if characteristic.uuid == DeviceUUID.manufacturerCharacteristic.uuid {
                readValue(fromPeripheral: peripheral, by: characteristic, withStoreCharacteristic: &manufacturerNameCharacteristic)
            }
            if characteristic.uuid == DeviceUUID.modelNumberCharacteristic.uuid {
                readValue(fromPeripheral: peripheral, by: characteristic, withStoreCharacteristic: &modelNumberCharacteristic)
            }
            if characteristic.uuid == DeviceUUID.serialNumberCharacteristic.uuid {
                readValue(fromPeripheral: peripheral, by: characteristic, withStoreCharacteristic: &serialNumberCharacteristic)
            }
            if characteristic.uuid == DeviceUUID.hardwareRevCharacteristic.uuid {
                readValue(fromPeripheral: peripheral, by: characteristic, withStoreCharacteristic: &hardwareRevisionCharacteristic)
            }
            if characteristic.uuid == DeviceUUID.firmwareRevCharacteristic.uuid {
                readValue(fromPeripheral: peripheral, by: characteristic, withStoreCharacteristic: &firmwareRevisionCharacteristic)
            }
            if characteristic.uuid == DeviceUUID.softwareRevCharacteristic.uuid {
                readValue(fromPeripheral: peripheral, by: characteristic, withStoreCharacteristic: &softwareRevisionCharacteristic)
            }
            if characteristic.uuid == DeviceUUID.batteryCharacteristic.uuid {
                readValue(fromPeripheral: peripheral, by: characteristic, withStoreCharacteristic: &batteryCharacteristic)
            }
            if characteristic.uuid == DeviceUUID.statusCharacteristic.uuid {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == DeviceUUID.modeCharacteristic.uuid {
                readValue(fromPeripheral: peripheral, by: characteristic, withStoreCharacteristic: &modeCharacteristic)
            }
            if characteristic.uuid == DeviceUUID.streamCharacteristic.uuid {
                peripheral.setNotifyValue(true, for: characteristic)
                DispatchQueue.main.sync {
                    delegate?.didSetNotify()
                }
            }
        }
    }

    /// connectした時の呼ばれる
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }

    /// Notify属性の値更新時に呼ばれる(ここの脳波データをハンドリング)
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        if characteristic.uuid == DeviceUUID.streamCharacteristic.uuid {
            if let data = characteristic.value {
                if let deviceType = deviceType(fromUUIDString: peripheral.identifier.uuidString) {
                    updateEEGSignal(data, uuid: peripheral.identifier.uuidString, deviceType: deviceType)
                }
            }
        }
        if characteristic.uuid == DeviceUUID.batteryCharacteristic.uuid {
            if let data = characteristic.value {
                if let deviceType = deviceType(fromUUIDString: peripheral.identifier.uuidString) {
                    updateBattery(data, deviceType: deviceType)
                }
            }
        }
        if characteristic.uuid == DeviceUUID.manufacturerCharacteristic.uuid {
            guard let name = convertName(by: characteristic.value) else { return }
            DispatchQueue.main.sync { self.delegate?.didReadManufacturerName(uuid: peripheral.identifier.uuidString, name: name) }
        }
        if characteristic.uuid == DeviceUUID.modelNumberCharacteristic.uuid {
            guard let number = convertName(by: characteristic.value) else { return }
            DispatchQueue.main.sync { self.delegate?.didReadModelNumber(uuid: peripheral.identifier.uuidString, number: number) }
        }
        if characteristic.uuid == DeviceUUID.serialNumberCharacteristic.uuid {
            guard let number = convertName(by: characteristic.value) else { return }
            DispatchQueue.main.sync { self.delegate?.didReadSerialNumber(uuid: peripheral.identifier.uuidString, number: number) }
        }
        if characteristic.uuid == DeviceUUID.hardwareRevCharacteristic.uuid {
            guard let rev = convertName(by: characteristic.value) else { return }
            DispatchQueue.main.sync { self.delegate?.didReadHardwareRevision(uuid: peripheral.identifier.uuidString, revision: rev) }
        }
        if characteristic.uuid == DeviceUUID.firmwareRevCharacteristic.uuid {
            guard let rev = convertName(by: characteristic.value) else { return }
            DispatchQueue.main.sync { self.delegate?.didReadFirmwareRevision(uuid: peripheral.identifier.uuidString, revision: rev) }
        }
        if characteristic.uuid == DeviceUUID.softwareRevCharacteristic.uuid {
            guard let rev = convertName(by: characteristic.value) else { return }
            DispatchQueue.main.sync { self.delegate?.didReadSoftwareRevision(uuid: peripheral.identifier.uuidString, revision: rev) }
        }
    }
    
    // MARK: - Utils
    /// BLEデバイスから値を呼んで、キャラクタリスティックを保持
    private func readValue(fromPeripheral peripheral: CBPeripheral,
                           by characteristic: CBCharacteristic,
                           withStoreCharacteristic: inout [String: CBCharacteristic]) {
        for identifier in [leftPeriphralIdentifier, rightPeripheralIdentifier] {
            guard let identifier = identifier else {
                continue
            }
            if peripheral.identifier.uuidString == identifier {
                withStoreCharacteristic[identifier] = characteristic
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    /// バッテリー容量の読み出し
    private func readBattery(deviceType: DeviceType) {
        for peripheral in connectedPeripherals {
            switch deviceType {
            case .left:
                guard let identifier = leftPeriphralIdentifier,
                      let c = batteryCharacteristic[identifier] else {
                    return
                }
                peripheral.readValue(for: c)
            case .right:
                guard let identifier = rightPeripheralIdentifier,
                      let c = batteryCharacteristic[identifier] else {
                    return
                }
                peripheral.readValue(for: c)
            }
        }
    }
  
    /// Data -> String
    private func convertName(by data: Data?) -> String? {
        guard let data = data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 脳波データを送信
    private func updateEEGSignal(_ data: Data, uuid: String, deviceType: DeviceType) {
        let index: UInt8 = data[0]
        let status: UInt8 = data[1]
        let leftData = data[2 ... 41]
        let rightData = data[42 ... data.count - 1]
        let leftValues = leftData.encodedInt16
        let rightValues = rightData.encodedInt16

        // 1秒ごとにステータスを送信
        // 脳波デバイスの装着ステータスを更新 [0 : ok, 1 : left-x, 2 : right-x, 3 : both-x]
        if index == 0 {
            DispatchQueue.main.async {
                switch deviceType {
                case .left:
                    self.delegate?.didUpdateSensorStatusLeft(status: Int32(status))
                case .right:
                    self.delegate?.didUpdateSensorStatusRight(status: Int32(status))
                }
            }
            readBattery(deviceType: deviceType)
        }

        DispatchQueue.main.sync {
            switch deviceType {
            case .left:
                self.delegate?.didUpdateEEGLeft(values: leftValues)
            case .right:
                self.delegate?.didUpdateEEGRight(values: rightValues)
            }
        }
    }


    /// バッテリー容量の読み出しのコールバック
    private func updateBattery(_ data: Data, deviceType: DeviceType) {
        let batteryPercent = data.encodedUInt8[0]
        DispatchQueue.main.sync {
            switch deviceType {
            case .left:
                self.delegate?.didUpdateBatteryLeft(percent: Int32(batteryPercent))
            case .right:
                self.delegate?.didUpdateBatteryRight(percent: Int32(batteryPercent))
            }
        }
    }
}

private extension Data {
    /// Data to [UInt8]
    var encodedUInt8: [UInt8] {
        withUnsafeBytes {
            Array($0.bindMemory(to: UInt8.self)).map(UInt8.init(bigEndian:))
        }
    }

    /// Data to [Int16]
    var encodedInt16: [Int16] {
        withUnsafeBytes {
            Array($0.bindMemory(to: Int16.self)).map(Int16.init(bigEndian:))
        }
    }
}

#endif
