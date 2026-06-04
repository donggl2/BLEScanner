import SwiftUI
import UIKit
import CoreBluetooth

struct GATTDetailView: View {
    @ObservedObject var bleManager: BLEManager
    @Binding var showingGattDetail: Bool
    @Binding var selectedService: GATTService?
    @State private var showingCopiedToast = false
    @State private var copiedText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with navigation
                headerView
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Floating device info bar (Always visible MAC)
                floatingDeviceBar
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // Characteristics List
                characteristicsSection
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0A0F1E"),
                    Color(hex: "#040810")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .overlay(
            // Copied Toast
            Group {
                if showingCopiedToast {
                    ToastView(message: copiedText)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        )
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                showingGattDetail = false
                selectedService = nil
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Details")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#1B2035"))
                )
            }
            
            Spacer()
            
            Text(selectedService?.name ?? "Service")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                // Refresh service
                if let service = selectedService,
                   let cbService = findCBService(uuid: service.uuid) {
                    bleManager.connectedPeripheral?.discoverCharacteristics(nil, for: cbService)
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#1B2035"))
                    )
            }
        }
    }
    
    // MARK: - Floating Device Bar
    private var floatingDeviceBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(bleManager.connectedDevice?.name ?? "Device")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("MAC: \(bleManager.connectedDevice?.macAddress ?? "--:--:--:--:--:--")")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#22C55E"))
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "#22C55E"))
                    .frame(width: 6, height: 6)
                
                Text("Connected")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#22C55E"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(hex: "#22C55E").opacity(0.15))
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#22C55E").opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#22C55E").opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Characteristics Section
    private var characteristicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(selectedService?.characteristics ?? []) { characteristic in
                CharacteristicCard(
                    characteristic: characteristic,
                    bleManager: bleManager,
                    serviceUUID: selectedService?.uuid,
                    onCopy: { text in
                        copiedText = text
                        withAnimation { showingCopiedToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showingCopiedToast = false }
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func findCBService(uuid: CBUUID) -> CBService? {
        guard let services = bleManager.connectedPeripheral?.services else { return nil }
        return services.first { $0.uuid == uuid }
    }
}

// MARK: - Characteristic Card
struct CharacteristicCard: View {
    let characteristic: GATTCharacteristic
    let bleManager: BLEManager
    let serviceUUID: CBUUID?
    let onCopy: (String) -> Void
    @State private var localWriteValue = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Name and Badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(characteristic.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(characteristic.uuidString)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(hex: "#64748B"))
                }
                
                Spacer()
                
                // Property Badge
                propertyBadge
            }
            
            // WRITE Characteristic - Input Field
            if characteristic.hasWrite {
                writeInputSection
            }
            
            // NOTIFY Characteristic - Toggle and Data Display
            if characteristic.hasNotify {
                notifySection
            }
            
            // READ Characteristic - Value Display
            if characteristic.hasRead && !characteristic.hasNotify {
                readSection
            }
            
            // Data Display (if value exists)
            if let value = characteristic.value, !value.isEmpty {
                dataDisplaySection(data: value)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#1B2035"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Property Badge
    private var propertyBadge: some View {
        let (text, color, bgColor): (String, String, String)
        
        if characteristic.hasWrite {
            text = "WRITE"
            color = "#818CF8"
            bgColor = "#818CF8"
        } else if characteristic.hasNotify {
            text = "NOTIFY"
            color = "#22C55E"
            bgColor = "#22C55E"
        } else if characteristic.hasRead {
            text = "READ"
            color = "#FB923C"
            bgColor = "#FB923C"
        } else {
            text = "OTHER"
            color = "#94A3B8"
            bgColor = "#94A3B8"
        }
        
        return Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Color(hex: color))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: bgColor).opacity(0.15))
            )
    }
    
    // MARK: - Write Input Section
    private var writeInputSection: some View {
        HStack(spacing: 10) {
            // Input Field
            HStack {
                TextField("Hex or ASCII...", text: $localWriteValue)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#0A0F1E"))
            )
            
            // Send Button
            Button(action: {
                sendWrite()
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#22C55E"))
                    )
            }
        }
    }
    
    // MARK: - Notify Section
    private var notifySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Subscribe to notifications")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#94A3B8"))
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { characteristic.isNotifying },
                    set: { newValue in
                        toggleNotify(enabled: newValue)
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#22C55E")))
                .labelsHidden()
            }
            
            if characteristic.isNotifying {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last value:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#64748B"))
                    
                    if let value = characteristic.value, !value.isEmpty {
                        dataDisplaySection(data: value)
                    } else {
                        Text("Waiting for notifications...")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Color(hex: "#475569"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "#0A0F1E"))
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Read Section
    private var readSection: some View {
        HStack {
            Spacer()
            
            Button(action: {
                performRead()
            }) {
                Text("Read Value")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#FB923C"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#FB923C").opacity(0.15))
                    )
            }
        }
    }
    
    // MARK: - Data Display Section
    private func dataDisplaySection(data: Data) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // HEX Value
            HStack {
                Text(data.map { String(format: "%02X", $0) }.joined(separator: " "))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#22C55E"))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = data.map { String(format: "%02X", $0) }.joined(separator: " ")
                    onCopy("HEX value copied")
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#64748B"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#0A0F1E"))
            )
            
            // ASCII Value
            if let ascii = String(data: data, encoding: .ascii), !ascii.isEmpty {
                HStack {
                    Text("ASCII: \(ascii)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "#94A3B8"))
                    
                    Spacer()
                    
                    Button(action: {
                        UIPasteboard.general.string = ascii
                        onCopy("ASCII value copied")
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#64748B"))
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func sendWrite() {
        guard !localWriteValue.isEmpty,
              let cbCharacteristic = findCBCharacteristic() else { return }
        
        var data: Data?
        
        // Try parsing as hex first (space separated or continuous)
        let hexString = localWriteValue.replacingOccurrences(of: " ", with: "")
        if hexString.count % 2 == 0 {
            var bytes = [UInt8]()
            var index = hexString.startIndex
            while index < hexString.endIndex {
                let nextIndex = hexString.index(index, offsetBy: 2)
                if let byte = UInt8(hexString[index..<nextIndex], radix: 16) {
                    bytes.append(byte)
                }
                index = nextIndex
            }
            if bytes.count == hexString.count / 2 {
                data = Data(bytes)
            }
        }
        
        // If hex parsing failed, treat as ASCII
        if data == nil {
            data = localWriteValue.data(using: .ascii)
        }
        
        guard let writeData = data else { return }
        
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) 
            ? .withResponse 
            : .withoutResponse
        
        bleManager.writeCharacteristic(cbCharacteristic, data: writeData, type: writeType)
        localWriteValue = ""
    }
    
    private func toggleNotify(enabled: Bool) {
        guard let cbCharacteristic = findCBCharacteristic() else { return }
        bleManager.setNotify(enabled, for: cbCharacteristic)
    }
    
    private func performRead() {
        guard let cbCharacteristic = findCBCharacteristic() else { return }
        bleManager.readCharacteristic(cbCharacteristic)
    }
    
    private func findCBCharacteristic() -> CBCharacteristic? {
        guard let serviceUUID = serviceUUID,
              let services = bleManager.connectedPeripheral?.services,
              let service = services.first(where: { $0.uuid == serviceUUID }),
              let characteristics = service.characteristics else { return nil }
        
        return characteristics.first { $0.uuid == characteristic.uuid }
    }
}

// MARK: - Battery Level Card (Special)
struct BatteryLevelCard: View {
    let level: Int
    let characteristic: GATTCharacteristic
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Battery Level")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("UUID: \(characteristic.uuidString)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(hex: "#64748B"))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(level)%")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#22C55E"))
                
                Text("READ")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#FB923C"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#FB923C").opacity(0.15))
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#1B2035"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct GATTDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GATTDetailView(
            bleManager: BLEManager(),
            showingGattDetail: .constant(true),
            selectedService: .constant(nil)
        )
    }
}
