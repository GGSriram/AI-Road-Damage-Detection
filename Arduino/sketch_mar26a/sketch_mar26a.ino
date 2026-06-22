#include <BluetoothSerial.h>
#include <TinyGPS++.h>
#include <HardwareSerial.h>

#define TRIG_PIN 12
#define ECHO_PIN 14
#define LED_PIN 2

#define NORMAL_DISTANCE 20.0f
#define POTHOLE_THRESHOLD 35.0f
#define DEBOUNCE_MS 2000

BluetoothSerial SerialBT;
TinyGPSPlus gps;
HardwareSerial GPS_Serial(2);

float currentDistance = 0;
unsigned long lastTriggerTime = 0;

void setup() {
  Serial.begin(115200);
  SerialBT.begin("ESP32_RoadMonitor");
  
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  
  GPS_Serial.begin(9600, SERIAL_8N1, 16, 17);
  
  Serial.println("=== ROAD DAMAGE DETECTION SYSTEM ===");
  Serial.println("ESP32 Ready");
  Serial.println("Waiting for GPS...");
}

void loop() {
  // Read GPS
  while (GPS_Serial.available() > 0) {
    char c = GPS_Serial.read();
    gps.encode(c);
  }
  
  // Read Ultrasonic
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  currentDistance = duration * 0.0343 / 2;
  
  if (currentDistance < 2 || currentDistance > 400) {
    currentDistance = NORMAL_DISTANCE;
  }
  
  // Pothole Detection
  if (currentDistance > POTHOLE_THRESHOLD && gps.location.isValid()) {
    unsigned long now = millis();
    
    if (now - lastTriggerTime > DEBOUNCE_MS) {
      lastTriggerTime = now;
      
      String alertData = String(gps.location.lat(), 6) + "," +
                         String(gps.location.lng(), 6) + "," +
                         String(currentDistance);
      
      if (SerialBT.hasClient()) {
        SerialBT.println(alertData);
        Serial.println("=== POTHOLE DETECTED ===");
        Serial.println(alertData);
        
        // Blink LED
        for(int i = 0; i < 5; i++) {
          digitalWrite(LED_PIN, HIGH);
          delay(100);
          digitalWrite(LED_PIN, LOW);
          delay(100);
        }
      }
    }
  }
  
  // GPS Status LED
  if (gps.location.isValid()) {
    digitalWrite(LED_PIN, HIGH);
  } else {
    digitalWrite(LED_PIN, LOW);
  }
  
  // Display Status
  static unsigned long lastDisplay = 0;
  if (millis() - lastDisplay > 1000) {
    lastDisplay = millis();
    
    Serial.print("Distance: ");
    Serial.print(currentDistance);
    Serial.print(" cm | GPS: ");
    
    if (gps.location.isValid()) {
      Serial.print(gps.location.lat(), 6);
      Serial.print(", ");
      Serial.print(gps.location.lng(), 6);
    } else {
      Serial.print("Waiting for fix...");
    }
    
    Serial.print(" | BT: ");
    Serial.println(SerialBT.hasClient() ? "Connected" : "Waiting");
  }
  
  delay(50);
}
