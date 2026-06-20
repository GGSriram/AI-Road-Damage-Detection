import 'package:intl/intl.dart';

class Helpers {
  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm:ss').format(date);
  }
  
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yy HH:mm').format(date);
  }
  
  // Format coordinates
  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }
  
  // Get severity from depth
  static String getSeverityFromDepth(double depth) {
    if (depth > 8) {
      return 'HIGH';
    } else if (depth > 5) {
      return 'MEDIUM';
    } else {
      return 'LOW';
    }
  }
  
  // Get severity color
  static String getSeverityColor(String severity) {
    switch (severity) {
      case 'LOW':
        return '#4CAF50';
      case 'MEDIUM':
        return '#FF9800';
      case 'HIGH':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }
  
  // Get severity icon
  static String getSeverityIcon(String severity) {
    switch (severity) {
      case 'LOW':
        return '⚠️';
      case 'MEDIUM':
        return '⚠️⚠️';
      case 'HIGH':
        return '⚠️⚠️⚠️';
      default:
        return '❓';
    }
  }
  
  // Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
  
  // Format depth for display
  static String formatDepth(double depth) {
    return '${depth.toStringAsFixed(1)} cm';
  }
  
  // Format confidence for display
  static String formatConfidence(double confidence) {
    return '${(confidence * 100).toInt()}%';
  }
  
  // Get Google Maps URL
  static String getGoogleMapsUrl(double lat, double lng) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }
}