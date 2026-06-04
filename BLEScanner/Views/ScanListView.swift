import SwiftUI

struct ScanListView: View {
    @ObservedObject var bleManager: BLEManager
    @State private var searchText = ""
    @State private var selectedFilter: DeviceFilter = .all
    @Binding var selectedDevice: BLEDevice?
    @Binding var showingDeviceDetail: Bool
    
    private var filteredDevices: [BLEDevice] {
        let filtered = bleManager.devices.filter { device in
            var matchesFilter = true
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .connectable:
                matchesFilter = device.isConnectable
            case .unknown:
                matchesFilter = device.name == "Unknown Device"
            }
            
            var matchesSearch = true
            if !searchText.isEmpty {
                matchesSearch = device.name.lowercased().contains(searchText.lowercased()) ||
                               device.macAddress.lowercased().contains(searchText.lowercased())
            }
            
            return matchesFilter && matchesSearch
        }
        return filtered.sorted { $0.rssi > $1.rssi }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Search Bar
            searchBarView
                .padding(.horizontal)
                .padding(.top, 12)
            
            // Filter Chips
            filterChipsView
                .padding(.horizontal)
                .padding(.top, 12)
            
            // Device List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredDevices) { device in
                        DeviceCard(device: device, bleManager: bleManager) {
                            selectedDevice = device
                            showingDeviceDetail = true
                            bleManager.connect(to: device)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .refreshable {
                if bleManager.isScanning {
                    bleManager.stopScanning()
                }
                bleManager.startScanning()
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
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("BLE Scanner")
                .font(.system(size: 26, weight: .bold, design: .default))
                .foregroundColor(.white)
            
            Spacer()
            
            // Scanning Button
            Button(action: {
                if bleManager.isScanning {
                    bleManager.stopScanning()
                } else {
                    bleManager.startScanning()
                }
            }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(bleManager.isScanning ? Color.white : Color(hex: "#22C55E"))
                        .frame(width: 8, height: 8)
                        .scaleEffect(bleManager.isScanning ? 1.2 : 1.0)
                        .animation(bleManager.isScanning ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: bleManager.isScanning)
                    
                    Text(bleManager.isScanning ? "SCANNING" : "SCAN")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(bleManager.isScanning ? Color(hex: "#22C55E") : .white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(bleManager.isScanning ? Color(hex: "#22C55E") : Color(hex: "#1B2035"))
                )
                .overlay(
                    Capsule()
                        .stroke(bleManager.isScanning ? Color.clear : Color(hex: "#22C55E"), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#64748B"))
            
            TextField("Search device name or MAC address...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: "#64748B"))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1B2035"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Filter Chips
    private var filterChipsView: some View {
        HStack(spacing: 8) {
            ForEach(DeviceFilter.allCases, id: \.self) { filter in
                FilterChip(
                    title: filter == .all ? "All (\(bleManager.devices.count))" : filter.rawValue,
                    isSelected: selectedFilter == filter,
                    action: { selectedFilter = filter }
                )
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "#94A3B8"))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: "#22C55E") : Color(hex: "#1B2035"))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

// MARK: - Device Card
struct DeviceCard: View {
    let device: BLEDevice
    let bleManager: BLEManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    // Device Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: device.deviceTypeColor).opacity(0.15))
                        
                        Image(systemName: device.deviceTypeIcon)
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: device.deviceTypeColor))
                    }
                    .frame(width: 50, height: 50)
                    
                    // Device Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text("MAC: \(device.macAddress)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "#22C55E"))
                        
                        // Show REAL badge for real MAC addresses
                        if device.isRealMacAddress {
                            Text("REAL")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "#22C55E"))
                                )
                        }
                    }
                }
                    
                    Spacer()
                    
                    // RSSI Badge
                    VStack(spacing: 6) {
                        Text("\(device.rssi) dBm")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: device.rssiColor))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: device.rssiColor).opacity(0.15))
                            )
                        
                        if device.isConnectable {
                            Text("CONNECTABLE")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(hex: "#818CF8"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: "#818CF8").opacity(0.15))
                                )
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                
                // ADV Data Preview
                if let manufacturerData = device.advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
                   !manufacturerData.isEmpty {
                    HStack(spacing: 6) {
                        Text("ADV:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "#64748B"))
                        
                        Text(manufacturerData.prefix(10).map { String(format: "%02X", $0) }.joined(separator: " ") + "...")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(Color(hex: "#475569"))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                } else {
                    Spacer().frame(height: 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#1B2035"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct ScanListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockManager = BLEManager()
        ScanListView(
            bleManager: mockManager,
            selectedDevice: .constant(nil),
            showingDeviceDetail: .constant(false)
        )
    }
}
