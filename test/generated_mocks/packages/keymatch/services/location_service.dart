import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<Map<String, double>?> getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('Error getting location: $e');
      rethrow;
    }
  }

  static Future<Position> getCurrentPosition() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      rethrow;
    }
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  static Future<String?> getLocationString() async {
    try {
      final position = await getCurrentPosition();
      return '${position.latitude}, ${position.longitude}';
    } catch (e) {
      print('Error getting location string: $e');
      return null;
    }
  }

  static Future<Map<String, double>?> getLocationCoordinates() async {
    try {
      final position = await getCurrentPosition();
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('Error getting location coordinates: $e');
      return null;
    }
  }

  static Future<double> calculateDistance(
    double lat1, double lon1, double lat2, double lon2) async {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }
} 