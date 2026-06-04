import Foundation
import CoreBluetooth
import Combine

// MARK: - MAC Address Mode Configuration
// Enable real MAC via Build Settings > Swift Compiler - Custom Flags:
// Other Swift Flags: -DENABLE_REAL_MAC_ADDRESS
// WARNING: Not App Store safe. Remove flag for App Store builds.

#if ENABLE_REAL_MAC_ADDRESS
import ObjectiveC

// MARK: - Private API Extensions for Real MAC Address
extension CBPeripheral {
    /// Get real MAC address using private API
    /// This works on non-jailbroken devices for sideloaded apps
    var realMacAddress: String? {
        // Method 1: Try to access the internal 'address' property
        if responds(to: NSSelectorFromString("address")),
           let address = value(forKey: "address") as? String,
           !address.isEmpty,
           address != "00:00:00:00:00:00" {
            return address.uppercased()
        }
        
        // Method 2: Try to access via identifierString (some iOS versions)
        if responds(to: NSSelectorFromString("identifierString")),
           let idString = value(forKey: "identifierString") as? String,
           idString.contains(":") {
            return idString.uppercased()
        }
        
        // Method 3: Access via underlying Bluetooth device info
        if responds(to: NSSelectorFromString("btDevice")),
           let btDevice = value(forKey: "btDevice"),
           let device = btDevice as? NSObject {
            
            // Try to get address from btDevice
            if device.responds(to: NSSelectorFromString("address")),
               let addr = device.value(forKey: "address") as? String {
                return addr.uppercased()
            }
        }
        
        return nil
    }
    
    /// Alternative: Try to get MAC from internal CoreBluetooth structures
    var internalMacAddress: String? {
        // Access the underlying CBPeripheral internal state
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            if let propertyName = child.label {
                // Look for address-related properties
                if propertyName.lowercased().contains("address"),
                   let value = child.value as? String,
                   value.contains(":") {
                    return value.uppercased()
                }
                
                // Look for btDevice
                if propertyName == "_peripheral" || propertyName == "btDevice" {
                    let childMirror = Mirror(reflecting: child.value)
                    for grandChild in childMirror.children {
                        if let grandChildLabel = grandChild.label,
                           grandChildLabel.lowercased().contains("address"),
                           let addr = grandChild.value as? String {
                            return addr.uppercased()
                        }
                    }
                }
            }
        }
        
        return nil
    }
}
#endif

class BLEManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var devices: [BLEDevice] = []
    @Published var isScanning = false
    @Published var connectedDevice: BLEDevice?
    @Published var discoveredServices: [GATTService] = []
    @Published var isConnecting = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Private Properties
    private var centralManager: CBCentralManager!
    /// Connected peripheral (internal for GATT views)
    var connectedPeripheral: CBPeripheral?
    private var discoveredCharacteristics: [CBUUID: [GATTCharacteristic]] = [:]
    private let deviceSubject = PassthroughSubject<BLEDevice, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - MAC Address Tracking
    private var macAddressMap: [UUID: String] = [:]
    
    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Setup device update debounce
        deviceSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.sortDevices()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth is not powered on"
            showError = true
            return
        }
        
        isScanning = true
        devices.removeAll()
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }
    
    func connect(to device: BLEDevice) {
        guard !isConnecting else { return }
        
        isConnecting = true
        if let connected = connectedPeripheral {
            centralManager.cancelPeripheralConnection(connected)
        }
        
        connectedPeripheral = device.peripheral
        connectedPeripheral?.delegate = self
        centralManager.connect(device.peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        resetConnectionState()
    }
    
    func readCharacteristic(_ characteristic: CBCharacteristic) {
        connectedPeripheral?.readValue(for: characteristic)
    }
    
    func writeCharacteristic(_ characteristic: CBCharacteristic, data: Data, type: CBCharacteristicWriteType = .withResponse) {
        connectedPeripheral?.writeValue(data, for: characteristic, type: type)
    }
    
    func setNotify(_ enabled: Bool, for characteristic: CBCharacteristic) {
        connectedPeripheral?.setNotifyValue(enabled, for: characteristic)
    }
    
    // MARK: - MAC Address Methods
    
    /// Returns whether real MAC address mode is enabled
    var isRealMacAddressEnabled: Bool {
        #if ENABLE_REAL_MAC_ADDRESS
        return true
        #else
        return false
        #endif
    }
    
    /// Extract or generate MAC address from peripheral
    /// Note: iOS CoreBluetooth does not expose real MAC addresses directly
    /// This implementation uses multiple fallback strategies
    func getMacAddress(for peripheral: CBPeripheral, advertisementData: [String: Any]) -> (macAddress: String, hex: String, uuid: UUID, isReal: Bool) {
        let peripheralUUID = peripheral.identifier
        
        // Check if we already have a MAC address for this peripheral
        if let cachedMac = macAddressMap[peripheralUUID] {
            return (cachedMac, cachedMac.replacingOccurrences(of: ":", with: ""), peripheralUUID, false)
        }
        
        // ============================================
        // MODE 1: REAL MAC ADDRESS (Sideloaded apps only)
        // Enabled when -DENABLE_REAL_MAC_ADDRESS is set
        // ============================================
        #if ENABLE_REAL_MAC_ADDRESS
        // Strategy 1A: Try to get real MAC from private API
        if let realMac = peripheral.realMacAddress {
            macAddressMap[peripheralUUID] = realMac
            print("[MAC] Got REAL MAC from private API: \(realMac)")
            return (realMac, realMac.replacingOccurrences(of: ":", with: ""), peripheralUUID, true)
        }
        
        // Strategy 1B: Try alternative internal method
        if let internalMac = peripheral.internalMacAddress {
            macAddressMap[peripheralUUID] = internalMac
            print("[MAC] Got REAL MAC from internal property: \(internalMac)")
            return (internalMac, internalMac.replacingOccurrences(of: ":", with: ""), peripheralUUID, true)
        }
        #endif
        
        // ============================================
        // MODE 2: VIRTUAL MAC ADDRESS (App Store compatible)
        // Fallback methods for both modes
        // ============================================
        
        // Strategy 2A: Try to extract from Manufacturer Data (if device advertises real MAC)
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
           manufacturerData.count >= 6 {
            let macBytes = Array(manufacturerData.prefix(6))
            let mac = macBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
            macAddressMap[peripheralUUID] = mac
            print("[MAC] Got MAC from Manufacturer Data: \(mac)")
            return (mac, mac.replacingOccurrences(of: ":", with: ""), peripheralUUID, false)
        }
        
        // Strategy 2B: Generate a consistent virtual MAC from peripheral UUID
        // This creates a stable identifier that looks like a MAC address
        let uuidString = peripheralUUID.uuidString.replacingOccurrences(of: "-", with: "")
        let startIndex = uuidString.startIndex
        let mac = String(format: "%@:%@:%@:%@:%@:%@",
            String(uuidString[startIndex..<uuidString.index(startIndex, offsetBy: 2)]),
            String(uuidString[uuidString.index(startIndex, offsetBy: 2)..<uuidString.index(startIndex, offsetBy: 4)]),
            String(uuidString[uuidString.index(startIndex, offsetBy: 4)..<uuidString.index(startIndex, offsetBy: 6)]),
            String(uuidString[uuidString.index(startIndex, offsetBy: 6)..<uuidString.index(startIndex, offsetBy: 8)]),
            String(uuidString[uuidString.index(startIndex, offsetBy: 8)..<uuidString.index(startIndex, offsetBy: 10)]),
            String(uuidString[uuidString.index(startIndex, offsetBy: 10)..<uuidString.index(startIndex, offsetBy: 12)])
        ).uppercased()
        
        // Override with some recognizable vendor prefixes for demo
        let vendorPrefixes = [
            "D4:CA:6E",  // Nordic Semiconductor
            "A8:03:2A",  // Texas Instruments
            "4C:57:CA",  // Apple
            "AC:23:3F",  // Espressif
            "F4:CF:A2",  // Espressif
        ]
        
        let randomPrefix = vendorPrefixes[abs(peripheralUUID.hashValue) % vendorPrefixes.count]
        let finalMac = randomPrefix + mac.suffix(9)
        
        macAddressMap[peripheralUUID] = finalMac
        
        #if ENABLE_REAL_MAC_ADDRESS
        print("[MAC] Failed to get real MAC, using virtual: \(finalMac)")
        #else
        print("[MAC] Using virtual MAC (App Store mode): \(finalMac)")
        #endif
        
        return (finalMac, finalMac.replacingOccurrences(of: ":", with: ""), peripheralUUID, false)
    }
    
    // MARK: - Private Methods
    
    private func resetConnectionState() {
        connectedPeripheral = nil
        connectedDevice = nil
        discoveredServices.removeAll()
        discoveredCharacteristics.removeAll()
        isConnecting = false
    }
    
    private func sortDevices() {
        devices.sort { $0.rssi > $1.rssi }
    }
    
    private func updateOrAddDevice(_ device: BLEDevice) {
        if let index = devices.firstIndex(where: { $0.peripheral.identifier == device.peripheral.identifier }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
        deviceSubject.send(device)
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if isScanning {
                startScanning()
            }
        case .poweredOff:
            errorMessage = "Bluetooth is powered off"
            showError = true
            stopScanning()
        case .unauthorized:
            errorMessage = "Bluetooth permission denied"
            showError = true
        case .unsupported:
            errorMessage = "Bluetooth is not supported on this device"
            showError = true
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, 
                        didDiscover peripheral: CBPeripheral, 
                        advertisementData: [String : Any], 
                        rssi RSSI: NSNumber) {
        let macInfo = getMacAddress(for: peripheral, advertisementData: advertisementData)
        let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool ?? false
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String 
            ?? peripheral.name 
            ?? "Unknown Device"
        
        let device = BLEDevice(
            peripheral: peripheral,
            name: name,
            macAddress: macInfo.macAddress,
            macAddressHex: macInfo.hex,
            macAddressUUID: macInfo.uuid,
            isRealMacAddress: macInfo.isReal,
            rssi: RSSI.intValue,
            advertisementData: advertisementData,
            isConnectable: isConnectable,
            lastSeen: Date()
        )
        
        DispatchQueue.main.async {
            self.updateOrAddDevice(device)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnecting = false
            if let device = self.devices.first(where: { $0.peripheral.identifier == peripheral.identifier }) {
                self.connectedDevice = device
            }
            peripheral.discoverServices(nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnecting = false
            self.errorMessage = error?.localizedDescription ?? "Failed to connect"
            self.showError = true
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.resetConnectionState()
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
            return
        }
        
        guard let services = peripheral.services else { return }
        
        var gattServices: [GATTService] = []
        for service in services {
            let gattService = GATTService(
                uuid: service.uuid,
                name: KnownServices.serviceName(for: service.uuid),
                characteristics: []
            )
            gattServices.append(gattService)
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        DispatchQueue.main.async {
            self.discoveredServices = gattServices
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        let gattCharacteristics = characteristics.map { cbCharacteristic in
            GATTCharacteristic(
                uuid: cbCharacteristic.uuid,
                name: KnownServices.characteristicName(for: cbCharacteristic.uuid),
                properties: cbCharacteristic.properties,
                value: cbCharacteristic.value,
                isNotifying: cbCharacteristic.isNotifying,
                descriptors: cbCharacteristic.descriptors
            )
        }
        
        DispatchQueue.main.async {
            if let index = self.discoveredServices.firstIndex(where: { $0.uuid == service.uuid }) {
                self.discoveredServices[index].characteristics = gattCharacteristics
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
            return
        }
        
        DispatchQueue.main.async {
            self.updateCharacteristicValue(characteristic, value: characteristic.value)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
            return
        }
        
        DispatchQueue.main.async {
            self.updateCharacteristicNotifyState(characteristic, isNotifying: characteristic.isNotifying)
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateCharacteristicValue(_ characteristic: CBCharacteristic, value: Data?) {
        for (serviceIndex, service) in discoveredServices.enumerated() {
            if let charIndex = service.characteristics.firstIndex(where: { $0.uuid == characteristic.uuid }) {
                discoveredServices[serviceIndex].characteristics[charIndex].value = value
            }
        }
    }
    
    private func updateCharacteristicNotifyState(_ characteristic: CBCharacteristic, isNotifying: Bool) {
        for (serviceIndex, service) in discoveredServices.enumerated() {
            if let charIndex = service.characteristics.firstIndex(where: { $0.uuid == characteristic.uuid }) {
                discoveredServices[serviceIndex].characteristics[charIndex].isNotifying = isNotifying
            }
        }
    }
}
