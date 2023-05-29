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

/// EEG EarPhone status
public enum WearingStatus: Int {
    case well
    case leftLost
    case rightLost
    case bothLost
    
    init(statusNumber: Int) {
        switch statusNumber {
        case 0:
            self = .well
        case 1:
            self = .leftLost
        case 2:
            self = .rightLost
        case 3:
            self = .bothLost
        default:
            self = .bothLost
        }
    }

    public var isLeftSensing: Bool {
        switch self {
        case .well, .rightLost:
            return true
        case .leftLost, .bothLost:
            return false
        }
    }

    public var isRightSensing: Bool {
        switch self {
        case .well, .leftLost:
            return true
        case .rightLost, .bothLost:
            return false
        }
    }
}

public final class BLEDevice: NSObject {
    public static var shared = BLEDevice()

    private weak var delegate: BLEDelegate?

    private var centralManager: CBCentralManager!

    // 接続されたペリフェラル
    private var connectedPeripheral: CBPeripheral?

    private var modeCharacteristic: CBCharacteristic?
    private var batteryCharacteristic: CBCharacteristic?
    private var manufacturerNameCharacteristic: CBCharacteristic?
    private var modelNumberCharacteristic: CBCharacteristic?
    private var serialNumberCharacteristic: CBCharacteristic?
    private var hardwareRevisionCharacteristic: CBCharacteristic?
    private var firmwareRevisionCharacteristic: CBCharacteristic?
    private var softwareRevisionCharacteristic: CBCharacteristic?
    
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

    // PacketIndexes
    private struct PacketInfo {
        static private let eegSinglePacketByteSize: Int = 40
        struct byteRegion {
            static let index = 0
            static let status = 1
            static let leftData = (2)...(2 + eegSinglePacketByteSize - 1)
            static let rightData = (2 + eegSinglePacketByteSize)...(2 + eegSinglePacketByteSize*2 - 1)
        }
    } 

    /// CBCentralManagerのイベントがディスパッチされるシリアルキュー
    let centralManagerDispatchQueue: DispatchQueue
    /// BLEDeviceのイベント(CBCentralManagerのデリゲートとCBPeripheralのデリゲートをハンドリングして実行される)がディスパッチされるシリアルキュー
    let bleDeviceDispatchQueue: DispatchQueue

    override private init() {
        centralManagerDispatchQueue = DispatchQueue(label: "style.vie.BLEDevicePackage.centralManager", qos: .userInitiated)
        bleDeviceDispatchQueue = DispatchQueue(label: "style.vie.BLEDevicePackage.bleDeviceDispatchQueue", qos: .userInitiated)

        super.init()

        centralManager = CBCentralManager(delegate: self, queue: centralManagerDispatchQueue)
    }

    public func setDelegate(delegate: BLEDelegate) {
        self.delegate = delegate
    }

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
    public func connect(_ deviceID: String, enableMusicPlaybackWithClassicBluetooth: Bool = true) {
        guard let lastUUID = UUID(uuidString: deviceID),
              let peripheral = centralManager.retrievePeripherals(withIdentifiers: [lastUUID]).first else {
            return
        }
        // 強参照が必要なのでプロパティとして保持
        connectedPeripheral = peripheral
        centralManager.connect(
            peripheral,
            options: [CBConnectPeripheralOptionEnableTransportBridgingKey: enableMusicPlaybackWithClassicBluetooth])
    }

    /// 接続を解除
    public func disconnectDevice() {
        guard let peripheral = connectedPeripheral else {
            return
        }

        for service in peripheral.services ?? [] as [CBService] {
            for characteristic in service.characteristics ?? [] as [CBCharacteristic] {
                if characteristic.uuid == DeviceUUID.statusCharacteristic.uuid, characteristic.isNotifying {
                    peripheral.setNotifyValue(false, for: characteristic)
                }
                if characteristic.uuid == DeviceUUID.modeCharacteristic.uuid, characteristic.isNotifying {
                    peripheral.setNotifyValue(false, for: characteristic)
                }
            }
        }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    /// 脳波の検出を開始
    public func start() {
        guard let peripheral = connectedPeripheral,
              let modeCharacteristic = modeCharacteristic else {
            return
        }

        peripheral.writeValue(Data(startBytes), for: modeCharacteristic, type: .withResponse)
    }

    /// 脳波の検出を停止
    public func stop() {
        guard let peripheral = connectedPeripheral,
              let modeCharacteristic = modeCharacteristic else {
            return
        }

        peripheral.writeValue(Data(stopBytes), for: modeCharacteristic, type: .withResponse)
    }
}

extension BLEDevice: CBCentralManagerDelegate {
    /// ペリフェラルを発見した
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let deviceName = peripheral.name else {
            return
        }

        bleDeviceDispatchQueue.async {
            self.delegate?.bleDeviceDidFindPeripheral(name: deviceName,
                                                      manufacturerID: peripheral.identifier.uuidString,
                                                      deviceID: peripheral.identifier.uuidString)
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
        connectedPeripheral = peripheral
        bleDeviceDispatchQueue.async {
            self.delegate?.bleDeviceDidConnect()
        }
    }

    /// ペリフェラルと接続が解除された
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        bleDeviceDispatchQueue.async {
            self.delegate?.bleDeviceDidDisconnect()
        }

        connectedPeripheral = nil
    }

    /// ペリフェラルとの接続に失敗した
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        bleDeviceDispatchQueue.async {
            self.delegate?.centralManager(central, didFailToConnect: peripheral, error: error)
        }
    }

    /// 状態が変化した
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bleDeviceDispatchQueue.async {
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
            if characteristic.uuid == DeviceUUID.batteryCharacteristic.uuid {
                connectedPeripheral?.readValue(for: characteristic)
                batteryCharacteristic = characteristic
            }
            if characteristic.uuid == DeviceUUID.manufacturerCharacteristic.uuid {
                connectedPeripheral?.readValue(for: characteristic)
                manufacturerNameCharacteristic = characteristic
            }
            if characteristic.uuid == DeviceUUID.modelNumberCharacteristic.uuid {
                connectedPeripheral?.readValue(for: characteristic)
                modelNumberCharacteristic = characteristic
            }
            if characteristic.uuid == DeviceUUID.serialNumberCharacteristic.uuid {
                connectedPeripheral?.readValue(for: characteristic)
                serialNumberCharacteristic = characteristic
            }
            if characteristic.uuid == DeviceUUID.hardwareRevCharacteristic.uuid {
                connectedPeripheral?.readValue(for: characteristic)
                hardwareRevisionCharacteristic = characteristic
            }
            if characteristic.uuid == DeviceUUID.firmwareRevCharacteristic.uuid {
                connectedPeripheral?.readValue(for: characteristic)
                firmwareRevisionCharacteristic = characteristic
            }
            if characteristic.uuid == DeviceUUID.softwareRevCharacteristic.uuid {
                connectedPeripheral?.readValue(for: characteristic)
                softwareRevisionCharacteristic = characteristic
            }
            if characteristic.uuid == DeviceUUID.statusCharacteristic.uuid {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == DeviceUUID.modeCharacteristic.uuid {
                modeCharacteristic = characteristic
            }
            if characteristic.uuid == DeviceUUID.streamCharacteristic.uuid {
                peripheral.setNotifyValue(true, for: characteristic)
                bleDeviceDispatchQueue.async {
                    self.delegate?.bleDeviceDidSetNotify()
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
        if characteristic.uuid == DeviceUUID.statusCharacteristic.uuid {
            if let data = characteristic.value { handleEEGStatus(data: data) }
        }
        if characteristic.uuid == DeviceUUID.streamCharacteristic.uuid {
            if let data = characteristic.value { handleEEGSignal(data: data) }
        }
        if characteristic.uuid == DeviceUUID.batteryCharacteristic.uuid {
            handleBatteryStatus(characteristic: characteristic)
        }
        if characteristic.uuid == DeviceUUID.manufacturerCharacteristic.uuid {
            guard let name = handleStringData(data: characteristic.value) else { return }
            bleDeviceDispatchQueue.async { self.delegate?.bleDeviceDidReadManufacturerName(name: name) }
        }
        if characteristic.uuid == DeviceUUID.modelNumberCharacteristic.uuid {
            guard let number = handleStringData(data: characteristic.value) else { return }
            bleDeviceDispatchQueue.async { self.delegate?.bleDeviceDidReadModelNumber(number: number) }
        }
        if characteristic.uuid == DeviceUUID.serialNumberCharacteristic.uuid {
            guard let number = handleStringData(data: characteristic.value) else { return }
            bleDeviceDispatchQueue.async { self.delegate?.bleDeviceDidReadSerialNumber(number: number) }
        }
        if characteristic.uuid == DeviceUUID.hardwareRevCharacteristic.uuid {
            guard let rev = handleStringData(data: characteristic.value) else { return }
            bleDeviceDispatchQueue.async { self.delegate?.bleDeviceDidReadHardwareRevision(revision: rev) }
        }
        if characteristic.uuid == DeviceUUID.firmwareRevCharacteristic.uuid {
            guard let rev = handleStringData(data: characteristic.value) else { return }
            bleDeviceDispatchQueue.async { self.delegate?.bleDeviceDidReadFirmwareRevision(revision: rev) }
        }
        if characteristic.uuid == DeviceUUID.softwareRevCharacteristic.uuid {
            guard let rev = handleStringData(data: characteristic.value) else { return }
            bleDeviceDispatchQueue.async { self.delegate?.bleDeviceDidReadSoftwareRevision(revision: rev) }
        }
    }
    
    /// Data -> String
    private func handleStringData(data: Data?) -> String? {
        guard let data = data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 脳波データを送信
    private func handleEEGSignal(data: Data) {
        let index: UInt8 = data[PacketInfo.byteRegion.index]
        let status: UInt8 = data[PacketInfo.byteRegion.status]
        let leftData = data[PacketInfo.byteRegion.leftData]
        let rightData = data[PacketInfo.byteRegion.rightData]
        let leftValues = leftData.encodedInt16
        let rightValues = rightData.encodedInt16

        // 1秒ごとにステータスを送信
        if index == 0 {
            handleSensorStatus(status: Int(status))
            readBattery()
        }

        bleDeviceDispatchQueue.async {
            self.delegate?.bleDeviceDidUpdate(leftSamples: leftValues, rightSamples: rightValues)
        }
    }

    /// バッテリー容量の読み出し
    private func readBattery() {
        guard let peripheral = connectedPeripheral,
              let batteryCharacteristic = batteryCharacteristic else {
            return
        }
        peripheral.readValue(for: batteryCharacteristic)
    }

    /// バッテリー容量の読み出しのコールバック
    private func handleBatteryStatus(characteristic: CBCharacteristic) {
        guard let data = characteristic.value else {
            return
        }
        let batteryPercent = data.encodedUInt8[0]
        bleDeviceDispatchQueue.async {
            self.delegate?.bleDeviceDidUpdate(batteryPercentage: Int(batteryPercent))
        }
    }

    /// 脳波デバイスの装着ステータスを更新 [0 : ok, 1 : left-x, 2 : right-x, 3 : both-x]
    private func handleSensorStatus(status: Int) {
        bleDeviceDispatchQueue.async {
            self.delegate?.bleDeviceDidUpdate(wearingStatus: WearingStatus(statusNumber: status))
        }
    }

    // periphery:ignore:parameters data
    /// EEG取得開始、停止時のハンドリング
    private func handleEEGStatus(data: Data) {
//        print(data.encodedUInt8)
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
