# BLE Scanner iOS App

A professional iOS BLE Scanner app that displays Bluetooth device MAC addresses, inspired by nRF Connect.

## Features

### Core Features
- **Scan BLE Devices**: Real-time scanning with RSSI signal strength
- **MAC Address Display**: Core differentiator - prominently shows device MAC addresses in green
- **Device Filtering**: Filter by All, Connectable, or Unknown devices
- **Search**: Search by device name or MAC address
- **Connect & Bond**: Connect to devices and view GATT services

### Screens
1. **Scan List (Screen 1)**: Device list with search, filters, and RSSI indicators
2. **Device Detail (Screen 2)**: Hero section with MAC address card (tap to copy), signal strength, and GATT services
3. **GATT Detail (Screen 3)**: Characteristic read/write/notify operations with floating device info bar

### Design System
- **Background**: Deep ocean blue gradient (`#0A0F1E` ¡ú `#040810`)
- **Cards**: Dark blue (`#1B2035`) with subtle white stroke (0.06 opacity)
- **Accent Green**: `#22C55E` for Scanning, MAC Address, Connected state, strong signal
- **Accent Purple**: `#818CF8` for Connectable badges, WRITE operations
- **Accent Orange**: `#FB923C` for READ operations, medium signal
- **Accent Red**: `#F87171` for weak signal, disconnected state

## Technical Details

### Requirements
- iOS 15.0+
- Xcode 15.0+
- Swift 5.0
- CoreBluetooth framework

### ?? No Mac? Use GitHub Actions!
**?? Mac ???????** ?? [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md)

???
1. ????? GitHub
2. ?? Actions ? Run workflow
3. 5????? IPA ??
4. ? AltStore ??? iPhone

??????? Mac?

### Architecture
- **Language**: Swift + SwiftUI
- **BLE Framework**: CoreBluetooth
- **Architecture Pattern**: MVVM with ObservableObject
- **Concurrency**: Combine framework for debounced updates

### Project Structure
```
BLEScanner/
©À©¤©¤ BLEScanner/
©¦   ©À©¤©¤ BLEScannerApp.swift       # App entry point
©¦   ©À©¤©¤ ContentView.swift         # Main container with tab navigation
©¦   ©À©¤©¤ Info.plist               # App configuration (BLE permission)
©¦   ©À©¤©¤ Models/
©¦   ©¦   ©¸©¤©¤ Models.swift         # Data models (BLEDevice, GATTService, etc.)
©¦   ©À©¤©¤ Managers/
©¦   ©¦   ©¸©¤©¤ BLEManager.swift      # CoreBluetooth manager (scanning, connecting)
©¦   ©À©¤©¤ Views/
©¦   ©¦   ©À©¤©¤ ScanListView.swift   # Screen 1: Scan list UI
©¦   ©¦   ©À©¤©¤ DeviceDetailView.swift  # Screen 2: Device detail with MAC
©¦   ©¦   ©¸©¤©¤ GATTDetailView.swift    # Screen 3: GATT characteristic operations
©¦   ©À©¤©¤ Assets.xcassets/         # App icons and colors
©¦   ©¸©¤©¤ Preview Content/         # SwiftUI previews
©¸©¤©¤ BLEScanner.xcodeproj/        # Xcode project
```

### MAC Address Modes (Dual Mode Support)

This app supports **two modes** selectable at compile time:

#### Mode 1: Real MAC Address (Sideloaded Only)
For apps that **will NOT be submitted to App Store**:

```
Build Settings ? Swift Compiler - Custom Flags ? Other Swift Flags
Add: -DENABLE_REAL_MAC_ADDRESS
```

**Features:**
- Uses **private APIs** to read actual BLE MAC addresses
- Displays "REAL" badge next to MAC address
- Works on non-jailbroken devices (sideloaded via Xcode/AltStore/Enterprise)

**?? WARNING**: Will cause App Store rejection if submitted!

#### Mode 2: Virtual MAC Address (App Store Compatible)
For apps that **may be submitted to App Store**:

```
Simply remove -DENABLE_REAL_MAC_ADDRESS flag
```

**Features:**
- Generates consistent virtual MAC from peripheral UUID
- Uses vendor prefixes (Nordic, TI, Apple, Espressif) for realistic appearance
- Displays "VIRTUAL" badge next to MAC address
- 100% App Store compliant

#### Fallback Strategy
Both modes support fallback:
1. Real mode: Try private API ? Fall back to virtual MAC
2. Virtual mode: Try Manufacturer Data ? Fall back to UUID-based MAC

#### Known Device Vendor Prefixes
- Nordic Semiconductor: `D4:CA:6E`
- Texas Instruments: `A8:03:2A`
- Apple: `4C:57:CA`
- Espressif: `AC:23:3F`, `F4:CF:A2`

### Installation (No App Store)
This app is designed for sideloading:

1. **Free Development (7-day re-sign)**:
   - Use personal Apple ID in Xcode
   - Build to device via Xcode
   - Re-sign every 7 days

2. **Enterprise Distribution**:
   - Use Enterprise certificate for internal distribution

3. **AltStore/SideStore**:
   - Alternative sideloading methods

### Permissions
The app requires Bluetooth permission:
- `NSBluetoothAlwaysUsageDescription`: "BLE Scanner needs Bluetooth permission to scan for nearby BLE devices"

## Usage

### Scanning
1. Launch app and grant Bluetooth permission
2. Tap green "SCAN" button to start scanning
3. Devices appear with MAC address, name, and RSSI
4. Tap any device card to connect

### Device Detail
1. View device MAC address prominently displayed
2. Tap MAC card to copy to clipboard
3. View signal strength with visual indicator
4. Disconnect or Bond device
5. Tap GATT services to view characteristics

### GATT Operations
1. Read characteristic values
2. Write data (HEX or ASCII)
3. Subscribe to notifications
4. View HEX and ASCII representations of received data

## Development

### Building
```bash
cd BLEScanner
# Open in Xcode
open BLEScanner.xcodeproj
# Or build from command line
xcodebuild -project BLEScanner.xcodeproj -scheme BLEScanner -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Running on Device
1. Connect iPhone via USB
2. Select device in Xcode target
3. Build and run (Cmd+R)
4. Trust developer certificate in Settings ¡ú General ¡ú VPN & Device Management

## License
MIT License - For educational and development purposes.

## Credits
Design inspired by nRF Connect with custom MAC address emphasis.
