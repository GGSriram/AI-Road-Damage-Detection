import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    bool hasPermission = await requestPermission();
    if (!hasPermission) return null;
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("Location error: $e");
      return null;
    }
  }

  static Future<double> getDistanceBetween(
    double lat1, double lng1,
    double lat2, double lng2,
  ) async {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}