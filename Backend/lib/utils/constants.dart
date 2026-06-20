class AppConstants {
  // Bluetooth
  static const String esp32DeviceName = 'ESP32_RoadMonitor';
  static const Duration bluetoothScanTimeout = Duration(seconds: 10);
  
  // Detection thresholds
  static const double defaultConfidenceThreshold = 0.6;
  static const double lowSeverityDepth = 5.0;
  static const double mediumSeverityDepth = 8.0;
  
  // Pothole depth thresholds (cm)
  static const double minPotholeDepth = 3.0;
  static const double maxNormalDistance = 25.0;
  static const double potholeDetectionThreshold = 35.0;
  
  // Database
  static const String databaseName = 'road_damage.db';
  static const int databaseVersion = 1;
  
  // App info
  static const String appName = 'SmartRoad AI';
  static const String appVersion = '1.0.0';
  
  // Colors
  static const Color lowSeverityColor = Color(0xFF4CAF50);
  static const Color mediumSeverityColor = Color(0xFFFF9800);
  static const Color highSeverityColor = Color(0xFFF44336);
  
  // Messages
  static const String gpsWaitingMessage = 'Waiting for GPS fix...';
  static const String bluetoothWaitingMessage = 'Waiting for ESP32...';
  static const String potholeDetectedMessage = '⚠️ Pothole Detected!';
  static const String aiConfirmingMessage = 'AI confirming...';
}