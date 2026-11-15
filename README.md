# ❄️ ClimaSmart — AC Smart Control & Leakage Protection System

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.8-0284C7?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13.7-0369A1?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/ESP32-Espressif-E7352C?style=for-the-badge&logo=espressif&logoColor=white" alt="ESP32" />
  <img src="https://img.shields.io/badge/Bluetooth-Classic_SPP-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white" alt="Bluetooth" />
  <img src="https://img.shields.io/badge/Platform-Android-10B981?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/License-MIT-F59E0B?style=for-the-badge" alt="License" />
</p>

---

## 📌 Project Overview

**ClimaSmart** is an enterprise-grade IoT climate monitoring and automated protection system designed for residential and commercial split air conditioning units. It combines an **ESP32 microcontroller** with a human-centric, **light-themed Flutter mobile application** over **Bluetooth Classic (RFCOMM / SPP)**.

The system addresses the critical problem of **unnoticed condensate drainage failure and water overflow leakage** from split AC units by implementing a real-time fail-safe hardware interlock:
1. Continuous ambient temperature & humidity telemetry from the AC airflow stream.
2. Analog condensate reservoir & leak sensor monitoring (3-tier state analysis).
3. **Automated Safety Interlock:** Automatic emergency compressor shutdown upon critical leakage detection to prevent building and interior damage.
4. One-touch master compressor relay switching directly from the mobile dashboard.
5. Automated multi-page A4 engineering PDF telemetry report generation.

**Engineering Supervision & Approval:** `Eng. Mahmoud Zayed`  
**System Architecture & Development:** `Hassan Issa`

---

## 🏛️ Comprehensive System Architecture

```mermaid
flowchart TD
    subgraph SENSORS["1. SENSING & ACTUATION LAYER"]
        DHT["DHT22 Sensor\n(Pin GPIO 4)\nTemp & Humidity"]
        LEAK["Water Leak Sensor\n(Pin GPIO 34 Analog)\nCondensate Reservoir"]
        RELAY["5V Optical Relay Module\n(Pin GPIO 2)\nHigh-Power AC Line"]
    end

    subgraph MCU["2. EMBEDDED CONTROLLER (ESP32)"]
        ADC["ADC Converter\nThreshold Analyzer"]
        INTERLOCK["Hardware Fail-Safe\nSafety Interlock Routine"]
        PACKET["Serial ASCII Packetizer\n(115200 Baud / 2s Interval)"]
        SPP_SERVER["Bluetooth Classic Server\n(SPP Profile: ESP32_AC_SMART)"]
    end

    subgraph TRANSPORT["3. WIRELESS SERIAL TRANSPORT"]
        BT_RFCOMM["Bluetooth Classic RFCOMM\nUUID: 00001101-0000-1000-8000-00805F9B34FB\nBidirectional Stream"]
    end

    subgraph APP["4. FLUTTER APPLICATION LAYER"]
        BT_CLIENT["BluetoothService\nAuto-Reconnect & Buffer Guard"]
        STATE["SensorData Provider\nSingle Source of Truth"]
        SAFETY_LOCK["App-Level Safety Interlock\nPower Lockout on Critical Leak"]
    end

    subgraph UI["5. HUMAN-CENTRIC LIGHT UI"]
        DASH["Dashboard\n• Live Dual Gauges\n• Master ON/OFF Switch\n• Real-Time Leak Pill"]
        CLIMATE["Climate Detail\n• Louver Airflow View\n• Relay Diagnostic State"]
        TANK["Leakage Reservoir\n• 3-Tier Tank Visualizer\n• Simulation Hardware Test"]
        ARCHIVE["Archive & PDF\n• Audit Event Timeline\n• A4 Signed PDF Report"]
    end

    %% Connections
    DHT --> ADC
    LEAK --> ADC
    ADC --> INTERLOCK
    INTERLOCK -->|Override Kill Signal| RELAY
    INTERLOCK --> PACKET
    PACKET --> SPP_SERVER
    SPP_SERVER <--> BT_RFCOMM
    BT_RFCOMM <--> BT_CLIENT
    BT_CLIENT --> STATE
    STATE --> SAFETY_LOCK
    SAFETY_LOCK --> UI
    DASH -->|AC:ON / AC:OFF| BT_CLIENT
```

---

## 🛡️ Safety State Machine & Auto-Cutoff Logic

The following state machine governs both the **ESP32 embedded firmware** and the **Flutter mobile application** to guarantee that the AC compressor cannot run when water overflow or leakage is detected.

```mermaid
stateDiagram-v2
    [*] --> Standby: Power On
    Standby --> Normal: BT Connected & Sensor Valid
    
    state Normal {
        [*] --> AC_Idle
        AC_Idle --> AC_Running: User taps 'START AC' (AC:ON)
        AC_Running --> AC_Idle: User taps 'STOP AC' (AC:OFF)
    }

    Normal --> Warning: Water Reservoir > 40% (ADC > 1500)
    
    state Warning {
        note right of Warning: Alert notification banner triggered.\nUser advised to inspect drainage.
        W_Running --> W_Idle: Manual Stop
        W_Idle --> W_Running: Manual Start Permitted
    }

    Warning --> Normal: Reservoir Drained (ADC < 1500)

    Warning --> Critical_Leakage: Water Overflow > 75% (ADC > 2800)
    Normal --> Critical_Leakage: Sudden Water Burst (ADC > 2800)

    state Critical_Leakage {
        [*] --> Auto_Shutdown
        Auto_Shutdown --> Compressor_Killed: Relay forced LOW immediately
        Compressor_Killed --> Lockout_Engaged: Red Alert Banner & UI Lockout
    }

    Critical_Leakage --> Normal: Sensor Cleared & Safe Level Restored
```

---

## 🔄 Bidirectional Communication Protocol & Sequence

```mermaid
sequenceDiagram
    autonumber
    participant ESP as ESP32 Microcontroller
    participant App as Flutter Mobile App
    participant User as System Operator

    Note over ESP,App: Bluetooth Classic RFCOMM Handshake Established
    
    loop Every 2000ms (Active Telemetry Stream)
        ESP->>App: Packet: "T:24.5,H:58.0,W:0\n"
        Note over App: Parse Temperature: 24.5°C<br/>Parse Humidity: 58.0%<br/>Parse Water Level: Normal (0)
        App->>App: Smooth animated gauge update
    end

    opt User Controls AC Power
        User->>App: Taps "START AC" button
        App->>ESP: Sends Command: "AC:ON\n"
        ESP->>ESP: Validate water safety (W < 2)
        ESP->>ESP: Set GPIO 2 HIGH (Relay energized)
        ESP-->>App: Next packet reflects running state
    end

    critical Condensate Reservoir Overflow Detected
        ESP->>ESP: Analog ADC read exceeds 2800
        ESP->>ESP: Hardware Interrupt: Force GPIO 2 LOW (Relay Kill)
        ESP->>App: Packet: "T:25.1,H:62.4,W:2\n"
        App->>App: Sound haptic alert & pop Emergency Leakage Banner
        App->>App: Lock out "START AC" button (Padlock active)
        App->>User: Displays: "EMERGENCY: Water leakage detected! AC stopped."
    end

    opt Emergency Resolution
        User->>ESP: Reservoir emptied & sensor dry
        ESP->>App: Packet: "T:24.0,H:55.0,W:0\n"
        App->>App: Unlock UI controls & dismiss alert banner
    end
```

---

## 🔌 Hardware Schematics & Pin Mapping

```text
       +-------------------------------------------------------+
       |                  ESP32 DEVKIT V1                      |
       |                                                       |
       |  [GPIO 4]  -------------------> DHT22 Data Pin        |
       |  [GPIO 34] <------------------- Water Leak Analog Out |
       |  [GPIO 2]  -------------------> Relay Signal (IN)     |
       |  [3.3V]    -------------------> DHT22 VCC             |
       |  [VIN/5V]  -------------------> Relay VCC             |
       |  [GND]     -------------------> Common System Ground  |
       +-------------------------------------------------------+
                                  |
                                  | High-Voltage AC Side
                                  v
       +-------------------------------------------------------+
       |               5V OPTICAL RELAY MODULE                 |
       |  [NO] (Normally Open) ---> AC Compressor Live Wire    |
       |  [COM] (Common)       ---> 220V Mains Live Source     |
       +-------------------------------------------------------+
```

| Subsystem | Component | ESP32 Pin | Logic Level | Operating Purpose |
| :--- | :--- | :---: | :---: | :--- |
| **Airflow Climate** | DHT22 (AM2302) | `GPIO 4` | 3.3V Digital | Precision ambient temperature (±0.5°C) & relative humidity (±2%) |
| **Leak Detection** | Analog Water Probe | `GPIO 34` | 0 - 3.3V Analog | Multi-level condensate accumulation measurement via ADC1 |
| **Power Control** | 5V Optocoupler Relay | `GPIO 2` | 3.3V / 5V Active HIGH | Cuts live line to the AC compressor contactor coil |
| **Telemetry Bus** | Serial Bluetooth | Internal | 2.4 GHz RFCOMM | High-throughput bi-directional SPP serial stream |

---

## 🎨 User Interface Sitemap & Screen Flow

```mermaid
flowchart LR
    SPLASH["0. Splash Intro\n• Minimalist clean white branding\n• 2.4s silk crossfade\n• Eng. Mahmoud Zayed sign-off"]
    
    NAV["Main Shell (Floating Navigation)"]

    TAB1["1. Dashboard Screen\n• Real-Time Dual Gauges (Temp/Hum)\n• Heat Index & Leak State\n• Master AC Switch (ON/OFF)\n• Emergency Alert Banner"]
    
    TAB2["2. Climate & Relay\n• Cooling Louver Visualizer\n• Relay Pin Status\n• Manual Start/Stop\n• Console Event Log"]
    
    TAB3["3. Water Leakage\n• Acrylic Glass Tank Reservoir\n• 3-Tier Threshold Reference\n• One-Tap Hardware Test Simulator"]
    
    TAB4["4. Telemetry Archive\n• Filterable Event Timeline\n• Search Engine\n• Instant A4 PDF Generator"]

    BT["Bluetooth Link Screen\n• Radar Scanner\n• ESP32 Auto-Tag\n• Auto-Reconnect Guard"]

    SPLASH --> NAV
    NAV --> TAB1
    NAV --> TAB2
    NAV --> TAB3
    NAV --> TAB4
    TAB1 -.->|Tap Connection Chip| BT
```

---

## 📦 Data Packet Specification

Packets are transmitted continuously every **2000 milliseconds** using comma-delimited key-value ASCII strings:

```text
T:24.5,H:58.0,W:0\n
```

| Parameter | Identifier | Type | Range | Meaning |
| :---: | :---: | :---: | :---: | :--- |
| **Temperature** | `T` | `float` | `-40.0` to `80.0` | Room temperature in Celsius (°C) |
| **Humidity** | `H` | `float` | `0.0` to `100.0` | Air relative humidity percentage (%) |
| **Water State** | `W` | `int` | `0`, `1`, `2` | `0` = Normal Safe \| `1` = Warning \| `2` = Critical Leakage |
| **Delimiter** | `\n` | `char` | ASCII `0x0A` | Frame termination byte for buffer synchronization |

---

## 💻 Tech Stack & Dependencies

| Layer | Technology | Version | Purpose |
| :--- | :--- | :---: | :--- |
| **Mobile Framework** | [Flutter](https://flutter.dev) | `3.47.8` | Cross-platform high-performance UI engine |
| **Programming Language** | [Dart](https://dart.dev) | `3.13.7` | Sound null-safe reactive application logic |
| **State Management** | `provider` | `^6.1.2` | Scalable `ChangeNotifier` reactive state binding |
| **Bluetooth Classic** | `flutter_blue_classic` | `^0.1.1` | Native Android RFCOMM/SPP driver (Gradle 8+ compatible) |
| **Document Reporting** | `pdf` & `printing` | `^3.13.1` / `^5.15.1` | Native vector-based multi-page A4 PDF rendering |
| **Permissions** | `permission_handler` | `^11.3.1` | Android 12+ runtime Bluetooth and Location grants |
| **Typography** | `google_fonts` | `^6.2.1` | Clean, modern Plus Jakarta Sans typography |
| **Animations** | `flutter_animate` | `^4.5.0` | 60fps micro-interactions, fades, and warning alerts |
| **Microcontroller Core** | [Arduino ESP32 Core](https://github.com/espressif/arduino-esp32) | `>= 2.0.0` | Native C++ FreeRTOS embedded environment |

---

## 🚀 Installation & Deployment

### 1. Flash the ESP32 Microcontroller
1. Install [Arduino IDE](https://www.arduino.cc/en/software) with the **ESP32 Board Package**.
2. Install the **DHT sensor library** (Adafruit) via Library Manager.
3. Open `firmware/esp32_ac_smart/esp32_ac_smart.ino`.
4. Select your board (`ESP32 Dev Module`) and COM port.
5. Click **Upload**. Open Serial Monitor at **115200 baud** to verify startup.

### 2. Build the Flutter Application
```bash
# 1. Clone the repository
git clone https://github.com/hassanIssa00/AC-Smart-Control.git
cd AC-Smart-Control

# 2. Fetch Flutter package dependencies
flutter pub get

# 3. Connect Android device with USB Debugging enabled
flutter devices

# 4. Run the application
flutter run --release
```

### 3. Generate Minimalist Production APK
```bash
# Produces architecture-split release APKs (~17 MB each)
flutter build apk --release --split-per-abi
```
Built APK location: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## 📑 Automated Engineering PDF Report

The built-in PDF service generates a professional, high-resolution engineering report containing:
- Formal incident audit metadata (device MAC, export timestamp, operator ID).
- Color-coded KPI summary cards (Avg Temperature, Peak Temperature, Leak Incident Count).
- Complete chronologically ordered tabular telemetry history.
- Verification badge: **Supervised and Approved by Eng. Mahmoud Zayed**.

---

## 👨‍💻 Project Authors & Credits

* **System Design & Implementation:** Hassan Issa ([@hassanIssa00](https://github.com/hassanIssa00))
* **Engineering Supervisor:** Eng. Mahmoud Zayed
* **Repository:** [https://github.com/hassanIssa00/AC-Smart-Control](https://github.com/hassanIssa00/AC-Smart-Control)
* **Direct APK Downloads:** [Releases Page](https://github.com/hassanIssa00/AC-Smart-Control/releases/tag/v1.0.0)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for full details.
