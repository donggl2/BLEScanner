import SwiftUI
import UIKit

struct DeviceDetailView: View {
    @ObservedObject var bleManager: BLEManager
    @Binding var selectedDevice: BLEDevice?
    @Binding var showingDeviceDetail: Bool
    @Binding var showingGattDetail: Bool
    @Binding var selectedService: GATTService?
    @State private var showingCopiedToast = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with navigation
                headerView
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Hero section with device info
                heroView
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // MAC Address Card (Core Feature)
                macAddressCard
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // RSSI Card
                rssiCard
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                // Action Buttons
                actionButtons
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // GATT Services Section
                gattServicesSection
                    .padding(.horizontal)
                    .padding(.top, 24)
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
                    ToastView(message: "MAC Address copied to clipboard")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        )
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                showingDeviceDetail = false
                selectedDevice = nil
                bleManager.disconnect()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Scan")
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
            
            Text("Device Details")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                // More options
            }) {
                Image(systemName: "ellipsis")
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
    
    // MARK: - Hero Section
    private var heroView: some View {
        HStack(spacing: 16) {
            // Large Device Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: selectedDevice?.deviceTypeColor ?? "#818CF8").opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: selectedDevice?.deviceTypeIcon ?? "iphone.gen2")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: selectedDevice?.deviceTypeColor ?? "#818CF8"))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedDevice?.name ?? "Unknown Device")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(bleManager.connectedDevice != nil ? Color(hex: "#22C55E") : Color(hex: "#F87171"))
                        .frame(width: 8, height: 8)
                    
                    Text(bleManager.connectedDevice != nil ? "Connected" : "Disconnected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(bleManager.connectedDevice != nil ? Color(hex: "#22C55E") : Color(hex: "#F87171"))
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - MAC Address Card (Core Feature - Prominent Display)
    private var macAddressCard: some View {
        Button(action: {
            copyMacAddress()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("MAC ADDRESS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#22C55E"))
                    
                    Spacer()
                    
                    // Show REAL badge for real MAC addresses
                    if let isReal = selectedDevice?.isRealMacAddress, isReal {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: "#22C55E"))
                                .frame(width: 6, height: 6)
                            Text("REAL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "#22C55E"))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#22C55E").opacity(0.15))
                        )
                    } else {
                        Text("VIRTUAL")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "#94A3B8"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#94A3B8").opacity(0.15))
                            )
                    }
                }
                
                Text(selectedDevice?.macAddress ?? "--:--:--:--:--:--")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("tap to copy")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "#64748B"))
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#1B2035"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#22C55E").opacity(0.5), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - RSSI Card
    private var rssiCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIGNAL")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "#94A3B8"))
            
            HStack {
                Text("\(selectedDevice?.rssi ?? 0) dBm")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: selectedDevice?.rssiColor ?? "#22C55E"))
                
                Spacer()
                
                // Signal strength indicator
                HStack(spacing: 3) {
                    ForEach(0..<4) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(signalBarColor(for: index))
                            .frame(width: 6, height: CGFloat(8 + index * 6))
                    }
                }
            }
            
            // Signal strength progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#1B2035"))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: selectedDevice?.rssiColor ?? "#22C55E"))
                        .frame(width: signalWidth(for: geometry.size.width), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
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
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Disconnect Button
            Button(action: {
                bleManager.disconnect()
                showingDeviceDetail = false
                selectedDevice = nil
            }) {
                Text("Disconnect")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#94A3B8"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#1B2035"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            
            // Bond Device Button
            Button(action: {
                // Bond action
            }) {
                Text("Bond Device")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#22C55E"))
                    )
            }
        }
    }
    
    // MARK: - GATT Services Section
    private var gattServicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GATT Services")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !bleManager.discoveredServices.isEmpty {
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
            }
            
            if bleManager.isConnecting {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#22C55E")))
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if bleManager.discoveredServices.isEmpty {
                Text("No services discovered")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#64748B"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                VStack(spacing: 10) {
                    ForEach(bleManager.discoveredServices) { service in
                        ServiceCard(service: service) {
                            selectedService = service
                            showingGattDetail = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func copyMacAddress() {
        guard let mac = selectedDevice?.macAddress else { return }
        UIPasteboard.general.string = mac
        
        withAnimation {
            showingCopiedToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingCopiedToast = false
            }
        }
    }
    
    private func signalBarColor(for index: Int) -> Color {
        guard let rssi = selectedDevice?.rssi else { return Color(hex: "#1B2035") }
        
        let maxBars: Int
        if rssi > -60 {
            maxBars = 4
        } else if rssi > -70 {
            maxBars = 3
        } else if rssi > -80 {
            maxBars = 2
        } else {
            maxBars = 1
        }
        
        return index < maxBars ? Color(hex: selectedDevice?.rssiColor ?? "#22C55E") : Color(hex: "#1B2035")
    }
    
    private func signalWidth(for totalWidth: CGFloat) -> CGFloat {
        guard let rssi = selectedDevice?.rssi else { return 0 }
        let percentage = (Double(rssi) + 100.0) / 70.0 // Normalize from -100 to -30 range
        let clamped = max(0, min(1, percentage))
        return totalWidth * CGFloat(clamped)
    }
}

// MARK: - Service Card
struct ServiceCard: View {
    let service: GATTService
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("UUID: \(service.uuidString)")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(hex: "#64748B"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#64748B"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#1B2035"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color(hex: "#22C55E"))
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.top, 50)
    }
}

// MARK: - Preview
struct DeviceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceDetailView(
            bleManager: BLEManager(),
            selectedDevice: .constant(nil),
            showingDeviceDetail: .constant(true),
            showingGattDetail: .constant(false),
            selectedService: .constant(nil)
        )
    }
}
