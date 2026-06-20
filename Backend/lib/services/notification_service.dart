import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Android initialization
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
  }

  static Future<void> showPotholeAlert({
    required double latitude,
    required double longitude,
    required double depth,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'road_damage_channel',
      'Road Damage Alerts',
      channelDescription: 'Notifications for detected potholes',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      DateTime.now().millisecond,
      '⚠️ Pothole Detected!',
      'Depth: ${depth.toStringAsFixed(1)} cm at location',
      details,
    );
  }

  static Future<void> showConfirmationAlert({
    required double confidence,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'confirmation_channel',
      'Detection Confirmation',
      channelDescription: 'AI confirmation notifications',
      importance: Importance.defaultPriority,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    
    await _notifications.show(
      DateTime.now().millisecond + 1,
      '✅ Pothole Confirmed!',
      'AI Confidence: ${(confidence * 100).toInt()}%',
      details,
    );
  }
}