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

**Engineering Project:** `Smart HVAC Condition Monitoring & Control`  
**System Architecture & Development:** `Hassan Issa`

---

## 🏛️ Comprehensive System Architecture

```mermaid
flowchart TD
    subgraph SENSORS["1. SENSING AND ACTUATION LAYER"]
        DHT["DHT22 Sensor<br/>(GPIO 4)<br/>Temp and Humidity"]
        LEAK["Water Leak Sensor<br/>(GPIO 34 Analog)<br/>Condensate Reservoir"]
        RELAY["5V Optical Relay<br/>(GPIO 2)<br/>Compressor Line"]
    end

    subgraph MCU["2. EMBEDDED CONTROLLER (ESP32)"]
        ADC["ADC Converter<br/>Threshold Analyzer"]
        INTERLOCK["Hardware Fail-Safe<br/>Safety Interlock Routine"]
        PACKET["ASCII Packetizer<br/>(115200 Baud / 2s)"]
        SPP_SERVER["Bluetooth Classic Server<br/>(Profile: ESP32_AC_SMART)"]
    end

    subgraph TRANSPORT["3. WIRELESS SERIAL TRANSPORT"]
        BT_RFCOMM["Bluetooth Classic RFCOMM<br/>UUID: 00001101-0000-1000-8000-00805F9B34FB"]
    end

    subgraph APP["4. FLUTTER APPLICATION LAYER"]
        BT_CLIENT["BluetoothService<br/>Auto-Reconnect and Buffer Guard"]
        STATE["SensorData Provider<br/>Single Source of Truth"]
        SAFETY_LOCK["Safety Interlock Lockout<br/>Auto-Cutoff Guard"]
    end

    subgraph UI["5. LIGHT THEME UI"]
        DASH["Dashboard Screen<br/>Live Gauges and Master Switch"]
        CLIMATE["Climate Control<br/>Louver and Relay State"]
        TANK["Water Reservoir<br/>3-Tier Acrylic Tank Visualizer"]
        ARCHIVE["Archive and PDF<br/>Timeline and Signed PDF Report"]
    end

    DHT --> ADC
    LEAK --> ADC
    ADC --> INTERLOCK
    INTERLOCK -->|Safety Cutoff| RELAY
    INTERLOCK --> PACKET
    PACKET --> SPP_SERVER
    SPP_SERVER -->|Wireless Stream| BT_RFCOMM
    BT_RFCOMM -->|Serial Ingest| BT_CLIENT
    BT_CLIENT --> STATE
    STATE --> SAFETY_LOCK
    SAFETY_LOCK --> UI
    DASH -->|AC ON / OFF Command| BT_CLIENT
    BT_CLIENT -->|Send Command| BT_RFCOMM
    BT_RFCOMM -->|Execute Relay| SPP_SERVER
```

---

## 🛡️ Safety State Machine & Auto-Cutoff Logic

The following state machine governs both the **ESP32 embedded firmware** and the **Flutter mobile application** to guarantee that the AC compressor cannot run when water overflow or leakage is detected.

```mermaid
stateDiagram-v2
    [*] --> Standby: System Boot
    Standby --> Normal_Safe: BT Connected and Sensors Online
    
    Normal_Safe --> Warning_Level: Water Reservoir Level Over 40%
    Warning_Level --> Normal_Safe: Reservoir Drained (Below 40%)
    
    Normal_Safe --> Critical_Leakage: Water Level Over 75%
    Warning_Level --> Critical_Leakage: Overflow Detected
    
    Critical_Leakage --> Emergency_Cutoff: Safety Interlock Triggered
    Emergency_Cutoff --> Compressor_Locked: GPIO 2 Forced LOW (Relay Off)
    Compressor_Locked --> Normal_Safe: Tank Emptied and Sensor Dry
    
    state Normal_Safe {
        [*] --> AC_Idle
        AC_Idle --> AC_Running: User taps START AC
        AC_Running --> AC_Idle: User taps STOP AC
    }
```

---

## 🔄 Bidirectional Communication Protocol & Sequence

```mermaid
sequenceDiagram
    autonumber
    actor User as System Operator
    participant App as Flutter Mobile App
    participant ESP as ESP32 Microcontroller
    participant Relay as AC Compressor Relay

    Note over App,ESP: Bluetooth Classic RFCOMM Handshake Established
    
    loop Telemetry Stream Every 2 Seconds
        ESP->>App: Telemetry Packet (T:24.5, H:58.0, W:0)
        App->>App: Update Temperature and Humidity Gauges
    end

    opt Manual AC Power Control
        User->>App: Tap START AC Switch
        App->>ESP: Command: AC_ON
        ESP->>Relay: Energize Relay (GPIO 2 HIGH)
        Relay-->>ESP: Compressor Running
        ESP->>App: Telemetry Packet (Running State)
    end

    rect rgb(254, 242, 242)
        Note over ESP,Relay: CRITICAL LEAKAGE DETECTED (Water Level Critical)
        ESP->>Relay: Immediate Hardware Kill (GPIO 2 LOW)
        Relay-->>ESP: Compressor Cut Off Instantly
        ESP->>App: Alert Packet (W:2 Critical)
        App->>App: Trigger Haptic Alert and Lockout Controls
        App->>User: Display Emergency Leakage Warning Banner
    end

    opt Emergency Resolution
        User->>ESP: Reservoir Emptied and Sensor Cleared
        ESP->>App: Safe Packet (W:0 Normal)
        App->>App: Dismiss Alert Banner and Unlock Controls
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
    SPLASH["0. Splash Screen<br/>Minimalist Light Branding<br/>Smart HVAC Condition Monitoring"]
    NAV["Main Shell<br/>Floating Navigation Bar"]
    TAB1["1. Dashboard<br/>Dual Gauges and Master AC Switch<br/>Emergency Alert Banner"]
    TAB2["2. Climate Screen<br/>Louver Airflow and Relay State"]
    TAB3["3. Water Leakage<br/>3-Tier Reservoir Visualizer and Simulator"]
    TAB4["4. Archive and Reports<br/>Audit Timeline and Signed PDF Export"]
    BT["Bluetooth Screen<br/>Radar Scanner and Auto-Reconnect"]

    SPLASH --> NAV
    NAV --> TAB1
    NAV --> TAB2
    NAV --> TAB3
    NAV --> TAB4
    TAB1 -.->|Tap Status Chip| BT
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
- Verification badge: **Automated Cryptographic Certification & Official Audit Log**.

---

## 👨‍💻 Project Authors & Credits

* **System Design & Implementation:** Hassan Issa ([@hassanIssa00](https://github.com/hassanIssa00))
* **Repository:** [https://github.com/hassanIssa00/AC-Smart-Control](https://github.com/hassanIssa00/AC-Smart-Control)
* **Direct APK Downloads:** [Releases Page](https://github.com/hassanIssa00/AC-Smart-Control/releases/tag/v1.0.0)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for full details.
