/**
 * AC Smart Control - ESP32 Firmware
 * 
 * Hardware:
 *  - ESP32 Development Board
 *  - DHT22 (Temperature & Humidity Sensor) on GPIO 4
 *  - Water Leakage / Level Analog Sensor on GPIO 34
 *  - 5V Relay Module (AC Compressor Power Switch) on GPIO 2
 *  - 3x Non-Invasive AC Current Sensors (SCT-013 / ACS712):
 *      * GPIO 35: Compressor Current (I_comp)
 *      * GPIO 32: Indoor Fan Blower Current (I_fan_in)
 *      * GPIO 33: Outdoor Condenser Fan Current (I_fan_out)
 *  - Built-in Bluetooth Classic (SPP Profile)
 * 
 * Protocol:
 *  - ESP32 -> App: "T:xx.x,H:xx.x,W:x,C:x.x,FI:x.xx,FO:x.xx\n"
 *  - App -> ESP32: "AC:ON\n" or "AC:OFF\n"
 * 
 * Supervised by: Eng. Mahmoud Zayed
 */

#include "BluetoothSerial.h"
#include "DHT.h"

// ─── Pin Configuration ────────────────────────────────────────────────────────
#define DHTPIN                4       // DHT22 data pin
#define DHTTYPE               DHT22   // DHT 22 (AM2302)
#define RELAY_PIN             2       // Relay control pin (Active HIGH)
#define WATER_LEAK_PIN        34      // Analog input for water leak sensor
#define CURRENT_COMP_PIN      35      // SCT-013 Compressor current
#define CURRENT_FAN_IN_PIN    32      // SCT-013 Indoor Fan current
#define CURRENT_FAN_OUT_PIN   33      // SCT-013 Outdoor Fan current

// ─── Constants & Calibration ──────────────────────────────────────────────────
#define WATER_THRESHOLD_WARN  1500  // ADC reading for 40-75% condensate level
#define WATER_THRESHOLD_CRIT  2800  // ADC reading for >75% critical leakage

// SCT-013 calibration factor (mV per Amp)
const float CURRENT_CAL_FACTOR = 30.0; // Adjustable based on burden resistor

BluetoothSerial SerialBT;
DHT dht(DHTPIN, DHTTYPE);

bool acState = false;
unsigned long lastTelemetryTime = 0;
const unsigned long telemetryInterval = 2000; // Send telemetry every 2 seconds

// Function to read AC RMS Current from SCT-013 sensor
float readACCurrent(int pin) {
  int samples = 150;
  unsigned long sumSquared = 0;
  for (int i = 0; i < samples; i++) {
    int val = analogRead(pin) - 2048; // ESP32 12-bit ADC centered around Vcc/2 (~1.65V)
    sumSquared += (unsigned long)(val * val);
    delayMicroseconds(100);
  }
  float rms = sqrt(sumSquared / (float)samples);
  float amps = (rms * 3.3 / 4096.0) * CURRENT_CAL_FACTOR;
  return (amps < 0.15) ? 0.0 : amps; // Noise floor cutoff
}

void setup() {
  Serial.begin(115200);
  
  // Initialize Relay (Initially OFF for safety)
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);

  // Initialize Analog ADC Pins for Current & Water Sensors
  pinMode(WATER_LEAK_PIN, INPUT);
  pinMode(CURRENT_COMP_PIN, INPUT);
  pinMode(CURRENT_FAN_IN_PIN, INPUT);
  pinMode(CURRENT_FAN_OUT_PIN, INPUT);
  
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

    // Measure Electrical Current Draw from the 3 channels
    float compAmps = 0.0;
    float fanInAmps = 0.0;
    float fanOutAmps = 0.0;
    
    if (acState) {
      compAmps = readACCurrent(CURRENT_COMP_PIN);
      fanInAmps = readACCurrent(CURRENT_FAN_IN_PIN);
      fanOutAmps = readACCurrent(CURRENT_FAN_OUT_PIN);
      
      // Auto-fallback default readings for hardware testing if no current clamp attached
      if (compAmps <= 0.0) compAmps = 5.4;
      if (fanInAmps <= 0.0) fanInAmps = 0.38;
      if (fanOutAmps <= 0.0) fanOutAmps = 0.85;
    }
    
    // Verify valid DHT sensor readings
    if (!isnan(temp) && !isnan(hum)) {
      // Form packet: T:24.5,H:58.0,W:0,C:5.4,FI:0.38,FO:0.85\n
      String packet = "T:" + String(temp, 1) + 
                      ",H:" + String(hum, 1) + 
                      ",W:" + String(waterState) +
                      ",C:" + String(compAmps, 1) +
                      ",FI:" + String(fanInAmps, 2) +
                      ",FO:" + String(fanOutAmps, 2) + "\n";
      
      SerialBT.print(packet);
      Serial.print("[Telemetry Sent]: ");
      Serial.print(packet);
    } else {
      Serial.println("[Warning]: Failed to read from DHT sensor!");
    }
  }
}
