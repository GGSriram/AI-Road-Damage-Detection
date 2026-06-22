#include <BluetoothSerial.h>
#include <TinyGPS++.h>
#include <HardwareSerial.h>

// ============= PIN DEFINITIONS =============
#define TRIG_PIN 12
#define ECHO_PIN 14
#define LED_PIN 2

// ============= DETECTION PARAMETERS =============
#define NORMAL_DISTANCE 20.0f        // Normal road distance (cm)
#define POTHOLE_THRESHOLD 30.0f      // Distance indicating pothole (cm)
#define DEBOUNCE_MS 2000             // Prevent duplicate alerts (ms)
#define READINGS_BUFFER 3            // Smoothing buffer size

// ============= OBJECTS =============
BluetoothSerial SerialBT;
TinyGPSPlus gps;
HardwareSerial GPS_Serial(2);

// ============= VARIABLES =============
unsigned long lastTriggerTime = 0;
float currentDistance = 0;
float distanceBuffer[READINGS_BUFFER];
int bufferIndex = 0;

// ============= SETUP =============
void setup() {
  Serial.begin(115200);
  SerialBT.begin("ESP32_RoadMonitor");

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);

  GPS_Serial.begin(9600, SERIAL_8N1, 16, 17);

  // Initialize distance buffer
  for (int i = 0; i < READINGS_BUFFER; i++) {
    distanceBuffer[i] = NORMAL_DISTANCE;
  }

  Serial.println("=== ROAD DAMAGE DETECTION SYSTEM ===");
  Serial.println("ESP32 Ready");
  Serial.println("Waiting for GPS...");
}

// ============= MAIN LOOP =============
void loop() {
  // 1. Read GPS Data
  while (GPS_Serial.available() > 0) {
    char c = GPS_Serial.read();
    gps.encode(c);
  }

  // 2. Read Ultrasonic with Smoothing
  float rawDistance = getUltrasonicDistance();
  
  // Apply moving average filter
  distanceBuffer[bufferIndex] = rawDistance;
  bufferIndex = (bufferIndex + 1) % READINGS_BUFFER;
  
  float smoothedDistance = 0;
  for (int i = 0; i < READINGS_BUFFER; i++) {
    smoothedDistance += distanceBuffer[i];
  }
  smoothedDistance /= READINGS_BUFFER;
  currentDistance = smoothedDistance;

  // 3. Pothole Detection with GPS Check
  if (currentDistance > POTHOLE_THRESHOLD && gps.location.isValid()) {
    unsigned long now = millis();
    
    if (now - lastTriggerTime > DEBOUNCE_MS) {
      lastTriggerTime = now;

      // Prepare data: latitude,longitude,depth
      String dataToSend = String(gps.location.lat(), 6) + "," +
                          String(gps.location.lng(), 6) + "," +
                          String(currentDistance, 1);

      if (SerialBT.hasClient()) {
        SerialBT.println(dataToSend);
        Serial.println("=== POTHOLE DETECTED ===");
        Serial.println(dataToSend);
        Serial.print("Depth: ");
        Serial.print(currentDistance);
        Serial.println(" cm");

        // Blink LED 5 times (alert pattern)
        blinkLED(5);
      } else {
        Serial.println("No Bluetooth client connected");
      }
    }
  }

  // 4. Display Status Every Second
  static unsigned long lastDisplay = 0;
  if (millis() - lastDisplay > 1000) {
    lastDisplay = millis();
    displayStatus();
  }

  delay(50);
}

// ============= ULTRASONIC DISTANCE MEASUREMENT =============
float getUltrasonicDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  float distance = duration * 0.0343 / 2;

  // Filter invalid readings
  if (distance < 2 || distance > 400) {
    return NORMAL_DISTANCE;
  }
  
  return distance;
}

// ============= LED CONTROL =============
void blinkLED(int times) {
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(100);
    digitalWrite(LED_PIN, LOW);
    delay(100);
  }
}

// ============= DISPLAY STATUS =============
void displayStatus() {
  Serial.print("Distance: ");
  Serial.print(currentDistance);
  Serial.print(" cm | GPS: ");
  
  if (gps.location.isValid()) {
    Serial.print(gps.location.lat(), 6);
    Serial.print(", ");
    Serial.print(gps.location.lng(), 6);
    Serial.print(" | Sat: ");
    Serial.print(gps.satellites.value());
  } else {
    Serial.print("Waiting for fix...");
  }
  
  Serial.print(" | BT: ");
  Serial.print(SerialBT.hasClient() ? "Connected" : "Waiting");
  
  // GPS status LED (blink if no fix, solid if fix)
  if (gps.location.isValid()) {
    digitalWrite(LED_PIN, HIGH);
  } else {
    // Slow blink when waiting for GPS
    static unsigned long lastBlink = 0;
    if (millis() - lastBlink > 1000) {
      lastBlink = millis();
      digitalWrite(LED_PIN, !digitalRead(LED_PIN));
    }
  }
  
  Serial.println();
}
