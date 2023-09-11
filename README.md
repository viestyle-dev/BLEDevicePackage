# BLEDevicePackage

## Hot to use
脳波データからの値を受け取りたいクラスでデリゲートをセットして、コールバックを受け取ります。
``` Example.swift

class ViewController {
    BLEDevice.shared.setDelegate(delegate: self)
}

extension ViewController: BLEDeviceDelegate {
    func bleDeviceDidFindPeripheral(name: String, manufacturerID: String, deviceID: String) {
    }
    ...
}

```

デリゲートは以下のようなメソッドがあります。
``` BLEDelegate.swift
// Required
/// スキャンしてペリフェラルが見つかった時に呼ばれます
func bleDeviceDidFindPeripheral(name: String, manufacturerID: String, deviceID: String)
/// VIEデバイスと接続が完了した時に呼ばれます
func bleDeviceDidConnect()
/// VIEデバイスとの接続が切断された時に呼ばれます
func bleDeviceDidDisconnect()
/// VIEデバイスで習得した脳波データを受け取る
func bleDeviceDidUpdate(leftSamples: [Int16], rightSamples: [Int16])
/// VIEデバイスのステータス通知
func bleDeviceDidUpdate(wearingStatus: WearingStatus)
/// VIEデバイスの電池残量通知
func bleDeviceDidUpdate(batteryPercentage: Int)

// Not Required
/// bleDeviceDidConnect()ではVIEデバイスのセットアップが完了していないことがあるので、
/// 全てのセットアップが完了したタイミングで処理したいときはbleDeviceDidSetNotify()をご利用ください。
func bleDeviceDidSetNotify()
func bleDeviceDidReadManufacturerName(name: String)
func bleDeviceDidReadModelNumber(number: String)
func bleDeviceDidReadSerialNumber(number: String)
func bleDeviceDidReadHardwareRevision(revision: String)
func bleDeviceDidReadFirmwareRevision(revision: String)
func bleDeviceDidReadSoftwareRevision(revision: String)
func centralManagerDidUpdateState(_ central: CBCentralManager)
func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
```
