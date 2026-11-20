/**
 * AC Smart Control - ESP32 Firmware
 * 
 * Hardware:
 *  - ESP32 Development Board
 *  - DHT22 (Temperature & Humidity Sensor) on GPIO 4
 *  - Water Leakage / Level Analog Sensor on GPIO 34
 *  - 5V Relay Module (AC Compressor Power Switch) on GPIO 2
 *  - Built-in Bluetooth Classic (SPP Profile)
 * 
 * Protocol:
 *  - ESP32 -> App: "T:xx.x,H:xx.x,W:x\n"
 *  - App -> ESP32: "AC:ON\n" or "AC:OFF\n"
 */

#include "BluetoothSerial.h"
#include "DHT.h"

// ─── Pin Configuration ────────────────────────────────────────────────────────
#define DHTPIN                4       // DHT22 data pin
#define DHTTYPE               DHT22   // DHT 22 (AM2302)
#define RELAY_PIN             2       // Relay control pin (Active HIGH)
#define WATER_LEAK_PIN        34      // Analog input for water leak sensor

// ─── Constants & Calibration ──────────────────────────────────────────────────
#define WATER_THRESHOLD_WARN  1500  // ADC reading for 40-75% condensate level
#define WATER_THRESHOLD_CRIT  2800  // ADC reading for >75% critical leakage

BluetoothSerial SerialBT;
DHT dht(DHTPIN, DHTTYPE);

bool acState = false;
unsigned long lastTelemetryTime = 0;
const unsigned long telemetryInterval = 2000; // Send telemetry every 2 seconds

void setup() {
  Serial.begin(115200);
  
  // Initialize Relay (Initially OFF for safety)
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);

  // Initialize Analog ADC Pin for Water Sensor
  pinMode(WATER_LEAK_PIN, INPUT);
  
  // Initialize DHT sensor
  dht.begin();
  
  // Initialize Bluetooth Classic SPP with recognizable name
  SerialBT.begin("ESP32_AC_SMART");
  Serial.println("=========================================");
  Serial.println("  AC Smart Control & Diagnostics ESP32   ");
  Serial.println("  Bluetooth: ESP32_AC_SMART              ");
  Serial.println("=========================================");
}

void loop() {
  // 1. Process Incoming Commands from Mobile App
  if (SerialBT.available()) {
    String command = SerialBT.readStringUntil('\n');
    command.trim();
    command.toUpperCase();
    
    Serial.print("[BT Command Received]: ");
    Serial.println(command);
    
    if (command == "AC:ON") {
      // Safety check: only allow turning ON if water level is not critical
      int currentLeak = analogRead(WATER_LEAK_PIN);
      if (currentLeak < WATER_THRESHOLD_CRIT) {
        acState = true;
        digitalWrite(RELAY_PIN, HIGH);
        Serial.println("-> AC Turned ON (Relay Energized)");
      } else {
        Serial.println("-> Command REJECTED: Critical water leakage detected!");
      }
    } else if (command == "AC:OFF") {
      acState = false;
      digitalWrite(RELAY_PIN, LOW);
      Serial.println("-> AC Turned OFF (Relay De-energized)");
    }
  }

  // 2. Periodic Telemetry Transmission
  unsigned long now = millis();
  if (now - lastTelemetryTime >= telemetryInterval) {
    lastTelemetryTime = now;
    
    float temp = dht.readTemperature();
    float hum = dht.readHumidity();
    int waterRaw = analogRead(WATER_LEAK_PIN);
    
    // Determine water state (0=Normal, 1=Warning, 2=Critical Leakage)
    int waterState = 0;
    if (waterRaw >= WATER_THRESHOLD_CRIT) {
      waterState = 2;
      // Hardware Interlock: Force kill AC if leakage is critical
      if (acState) {
        acState = false;
        digitalWrite(RELAY_PIN, LOW);
        Serial.println("!! EMERGENCY HARDWARE SHUTDOWN: Critical leakage !!");
      }
    } else if (waterRaw >= WATER_THRESHOLD_WARN) {
      waterState = 1;
    }

    // Verify valid DHT sensor readings
    if (!isnan(temp) && !isnan(hum)) {
      // Form packet: T:24.5,H:58.0,W:0\n
      String packet = "T:" + String(temp, 1) + 
                      ",H:" + String(hum, 1) + 
                      ",W:" + String(waterState) + "\n";
      
      SerialBT.print(packet);
      Serial.print("[Telemetry Sent]: ");
      Serial.print(packet);
    } else {
      Serial.println("[Warning]: Failed to read from DHT sensor!");
    }
  }
}
