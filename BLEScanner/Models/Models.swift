import Foundation
import CoreBluetooth

// MARK: - BLE Device Model
struct BLEDevice: Identifiable, Equatable {
    let id = UUID()
    let peripheral: CBPeripheral
    var name: String
    let macAddress: String
    let macAddressHex: String
    let macAddressUUID: UUID
    let isRealMacAddress: Bool  // Track if this is real or virtual MAC
    var rssi: Int
    var advertisementData: [String: Any]
    var isConnectable: Bool
    var lastSeen: Date
    
    static func == (lhs: BLEDevice, rhs: BLEDevice) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Display label for MAC address type
    var macAddressTypeLabel: String {
        isRealMacAddress ? "REAL MAC" : "VIRTUAL"
    }
    
    var rssiColor: String {
        if rssi > -60 {
            return "#22C55E"  // Green - strong signal
        } else if rssi > -80 {
            return "#FB923C"  // Orange - medium signal
        } else {
            return "#F87171"  // Red - weak signal
        }
    }
    
    var deviceTypeIcon: String {
        let lowerName = name.lowercased()
        if lowerName.contains("nordic") || lowerName.contains("nrf") {
            return "chart.bar.fill"
        } else if lowerName.contains("heart") || lowerName.contains("hr") {
            return "heart.fill"
        } else if lowerName.contains("airpod") {
            return "headphones"
        } else if lowerName.contains("keyboard") {
            return "keyboard"
        } else if lowerName.contains("mouse") {
            return "computermouse"
        } else {
            return "iphone.gen2"
        }
    }
    
    var deviceTypeColor: String {
        let lowerName = name.lowercased()
        if lowerName.contains("nordic") || lowerName.contains("nrf") {
            return "#22C55E"
        } else if lowerName.contains("heart") || lowerName.contains("hr") {
            return "#EF4444"
        } else if lowerName.contains("airpod") {
            return "#A78BFA"
        } else {
            return "#818CF8"
        }
    }
}

// MARK: - GATT Service Model
struct GATTService: Identifiable {
    let id = UUID()
    let uuid: CBUUID
    let name: String
    var characteristics: [GATTCharacteristic]
    
    var uuidString: String {
        if let shortUUID = uuid.uuidString.shortenedUUID {
            return shortUUID
        }
        return uuid.uuidString
    }
}

// MARK: - GATT Characteristic Model
struct GATTCharacteristic: Identifiable {
    let id = UUID()
    let uuid: CBUUID
    let name: String
    let properties: CBCharacteristicProperties
    var value: Data?
    var isNotifying: Bool = false
    var descriptors: [CBDescriptor]?
    
    var uuidString: String {
        if let shortUUID = uuid.uuidString.shortenedUUID {
            return shortUUID
        }
        return uuid.uuidString
    }
    
    var hexValue: String {
        guard let data = value else { return "No data" }
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
    
    var asciiValue: String {
        guard let data = value else { return "" }
        return String(data: data, encoding: .ascii) ?? "Invalid ASCII"
    }
    
    var hasRead: Bool {
        properties.contains(.read)
    }
    
    var hasWrite: Bool {
        properties.contains(.write) || properties.contains(.writeWithoutResponse)
    }
    
    var hasNotify: Bool {
        properties.contains(.notify) || properties.contains(.indicate)
    }
}

// MARK: - Filter Types
enum DeviceFilter: String, CaseIterable {
    case all = "All"
    case connectable = "Connectable"
    case unknown = "Unknown"
}

// MARK: - UUID Extension
extension String {
    var shortenedUUID: String? {
        let uuid = self.uppercased().replacingOccurrences(of: "-", with: "")
        let knownUUIDs: [String: String] = [
            "1800": "0x1800",
            "1801": "0x1801",
            "180A": "0x180A",
            "180F": "0x180F",
            "180D": "0x180D",
            "2A19": "0x2A19",
            "2A29": "0x2A29",
            "2A24": "0x2A24",
            "2A25": "0x2A25",
            "2A26": "0x2A26",
            "2A27": "0x2A27",
            "2A28": "0x2A28",
            "2A23": "0x2A23",
            "2A50": "0x2A50",
        ]
        
        for (key, value) in knownUUIDs {
            if uuid.contains(key) {
                return value
            }
        }
        
        return nil
    }
}

// MARK: - Known Services
struct KnownServices {
    static let serviceNames: [String: String] = [
        "1800": "Generic Access",
        "1801": "Generic Attribute",
        "180A": "Device Information",
        "180F": "Battery Service",
        "180D": "Heart Rate",
        "1809": "Health Thermometer",
        "1812": "Human Interface Device",
        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E": "Nordic UART Service",
    ]
    
    static let characteristicNames: [String: String] = [
        "2A00": "Device Name",
        "2A01": "Appearance",
        "2A04": "Peripheral Preferred Connection Parameters",
        "2A19": "Battery Level",
        "2A29": "Manufacturer Name String",
        "2A24": "Model Number String",
        "2A25": "Serial Number String",
        "2A26": "Firmware Revision String",
        "2A27": "Hardware Revision String",
        "2A28": "Software Revision String",
        "2A23": "System ID",
        "2A50": "PnP ID",
        "2A37": "Heart Rate Measurement",
        "2A38": "Body Sensor Location",
        "6E400002-B5A3-F393-E0A9-E50E24DCCA9E": "RX Characteristic",
        "6E400003-B5A3-F393-E0A9-E50E24DCCA9E": "TX Characteristic",
    ]
    
    static func serviceName(for uuid: CBUUID) -> String {
        let uuidString = uuid.uuidString.uppercased()
        return serviceNames[uuidString] ?? "Unknown Service"
    }
    
    static func characteristicName(for uuid: CBUUID) -> String {
        let uuidString = uuid.uuidString.uppercased()
        return characteristicNames[uuidString] ?? "Unknown Characteristic"
    }
}
