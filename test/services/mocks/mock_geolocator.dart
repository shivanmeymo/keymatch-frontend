import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';

@GenerateMocks([GeolocatorPlatform])
void main() {} 

// Simple mock class for testing
class MockGeolocator {
  static Position? _mockPosition;
  static LocationPermission _mockPermission = LocationPermission.whileInUse;

  static void setMockPosition(Position? position) {
    _mockPosition = position;
  }

  static void setPermission(LocationPermission permission) {
    _mockPermission = permission;
  }

  static Position? get mockPosition => _mockPosition;
  static LocationPermission get mockPermission => _mockPermission;
} 