import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @State private var selectedTab = 0
    @State private var selectedDevice: BLEDevice?
    @State private var selectedService: GATTService?
    @State private var showingDeviceDetail = false
    @State private var showingGattDetail = false
    @State private var showingLogView = false
    
    var body: some View {
        ZStack {
            // Main Content
            mainContent
            
            // Bottom Tab Bar (Floating)
            VStack {
                Spacer()
                floatingTabBar
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $showingDeviceDetail) {
            DeviceDetailView(
                bleManager: bleManager,
                selectedDevice: $selectedDevice,
                showingDeviceDetail: $showingDeviceDetail,
                showingGattDetail: $showingGattDetail,
                selectedService: $selectedService
            )
        }
        .sheet(isPresented: $showingGattDetail) {
            GATTDetailView(
                bleManager: bleManager,
                showingGattDetail: $showingGattDetail,
                selectedService: $selectedService
            )
        }
        .alert("Error", isPresented: $bleManager.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(bleManager.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        Group {
            switch selectedTab {
            case 0:
                ScanListView(
                    bleManager: bleManager,
                    selectedDevice: $selectedDevice,
                    showingDeviceDetail: $showingDeviceDetail
                )
            case 1:
                ConnectView(bleManager: bleManager)
            case 2:
                LogView()
            default:
                ScanListView(
                    bleManager: bleManager,
                    selectedDevice: $selectedDevice,
                    showingDeviceDetail: $showingDeviceDetail
                )
            }
        }
    }
    
    // MARK: - Floating Tab Bar
    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                TabBarButton(
                    index: index,
                    isSelected: selectedTab == index,
                    title: tabTitle(for: index),
                    icon: tabIcon(for: index)
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(hex: "#1B2035"))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
    
    // MARK: - Tab Configuration
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "SCAN"
        case 1: return "CONNECT"
        case 2: return "LOG"
        default: return ""
        }
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "magnifyingglass"
        case 1: return "link"
        case 2: return "doc.text"
        default: return ""
        }
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let index: Int
    let isSelected: Bool
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                
                if isSelected {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .foregroundColor(isSelected ? Color(hex: "#22C55E") : Color(hex: "#94A3B8"))
            .padding(.horizontal, isSelected ? 18 : 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "#22C55E").opacity(0.15) : Color.clear)
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Connect View
struct ConnectView: View {
    @ObservedObject var bleManager: BLEManager
    @State private var showingDisconnectAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Connected Device")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if let device = bleManager.connectedDevice {
                // Connected Device Card
                ScrollView {
                    VStack(spacing: 16) {
                        // Device Info Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(hex: device.deviceTypeColor).opacity(0.15))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: device.deviceTypeIcon)
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: device.deviceTypeColor))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(hex: "#22C55E"))
                                            .frame(width: 8, height: 8)
                                            .scaleEffect(1.2)
                                            .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: true)
                                        
                                        Text("Connected")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "#22C55E"))
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            // MAC Address
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MAC ADDRESS")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color(hex: "#22C55E"))
                                
                                Text(device.macAddress)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            
                            // Signal
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("SIGNAL")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color(hex: "#94A3B8"))
                                    
                                    Text("\(device.rssi) dBm")
                                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Color(hex: device.rssiColor))
                                }
                                
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "#1B2035"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Services Quick Access
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("GATT Services")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(bleManager.discoveredServices.count) services")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "#22C55E"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(hex: "#22C55E").opacity(0.15))
                                    )
                            }
                            
                            if bleManager.discoveredServices.isEmpty {
                                Text("No services discovered yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#64748B"))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(bleManager.discoveredServices.prefix(3)) { service in
                                        HStack {
                                            Text(service.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Text(service.uuidString)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(Color(hex: "#64748B"))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(hex: "#0A0F1E"))
                                        )
                                    }
                                    
                                    if bleManager.discoveredServices.count > 3 {
                                        Text("+ \(bleManager.discoveredServices.count - 3) more services")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color(hex: "#64748B"))
                                            .padding(.top, 4)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "#1B2035"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Disconnect Button
                        Button(action: {
                            showingDisconnectAlert = true
                        }) {
                            Text("Disconnect")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "#F87171"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "#F87171").opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#F87171").opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .alert("Disconnect Device?", isPresented: $showingDisconnectAlert) {
                            Button("Cancel", role: .cancel) {}
                            Button("Disconnect", role: .destructive) {
                                bleManager.disconnect()
                            }
                        } message: {
                            Text("This will disconnect from \(device.name)")
                        }
                    }
                    .padding(.bottom, 100)
                }
            } else {
                // No device connected
                VStack(spacing: 20) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#1B2035"))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "link.slash")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "#64748B"))
                    }
                    
                    VStack(spacing: 8) {
                        Text("No Device Connected")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Scan for BLE devices and tap to connect")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#64748B"))
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
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
}

// MARK: - Log View
struct LogView: View {
    @State private var logs: [LogEntry] = [
        LogEntry(timestamp: Date(), message: "App started", type: .info),
        LogEntry(timestamp: Date().addingTimeInterval(-60), message: "Bluetooth powered on", type: .success),
        LogEntry(timestamp: Date().addingTimeInterval(-120), message: "Scanning started", type: .info),
        LogEntry(timestamp: Date().addingTimeInterval(-180), message: "Found 5 devices", type: .success),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Activity Log")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    logs.removeAll()
                }) {
                    Text("Clear")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#94A3B8"))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Log List
            if logs.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "#64748B"))
                    
                    Text("No logs yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#64748B"))
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(logs) { log in
                            LogEntryRow(entry: log)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
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
}

// MARK: - Log Entry
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: LogType
    
    enum LogType {
        case info
        case success
        case warning
        case error
    }
}

// MARK: - Log Entry Row
struct LogEntryRow: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status Indicator
            Circle()
                .fill(colorForType(entry.type))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(formatTimestamp(entry.timestamp))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: "#64748B"))
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#1B2035"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func colorForType(_ type: LogEntry.LogType) -> Color {
        switch type {
        case .info:
            return Color(hex: "#818CF8")
        case .success:
            return Color(hex: "#22C55E")
        case .warning:
            return Color(hex: "#FB923C")
        case .error:
            return Color(hex: "#F87171")
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
