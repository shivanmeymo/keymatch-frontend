import 'package:flutter_test/flutter_test.dart';
import 'package:key_match/services/location_service.dart';

void main() {
  group('LocationService Tests', () {
    group('calculateDistance', () {
      test('should calculate distance between two points', () async {
        const double lat1 = 40.7128;
        const double lon1 = -74.0060;
        const double lat2 = 34.0522;
        const double lon2 = -118.2437;
        
        final distance = await LocationService.calculateDistance(lat1, lon1, lat2, lon2);
        
        expect(distance, isA<double>());
        expect(distance, greaterThan(0));
        // Distance between NYC and LA should be roughly 3900+ km
        expect(distance, greaterThan(3900));
        expect(distance, lessThan(4100));
      });

      test('should return 0 for same coordinates', () async {
        const double lat = 40.7128;
        const double lon = -74.0060;
        
        final distance = await LocationService.calculateDistance(lat, lon, lat, lon);
        
        expect(distance, equals(0));
      });

      test('should handle negative coordinates', () async {
        const double lat1 = -33.8688;
        const double lon1 = 151.2093;
        const double lat2 = 40.7128;
        const double lon2 = -74.0060;
        
        final distance = await LocationService.calculateDistance(lat1, lon1, lat2, lon2);
        
        expect(distance, isA<double>());
        expect(distance, greaterThan(0));
      });
    });

    // Skip GPS-dependent tests for now
    test('should get current position successfully', () async {}, skip: 'Requires GPS mocking');
    test('should return null when location services are disabled', () async {}, skip: 'Requires GPS mocking');
    test('should return permission status', () async {}, skip: 'Requires GPS mocking');
    test('should request permission', () async {}, skip: 'Requires GPS mocking');
    test('should return formatted location string', () async {}, skip: 'Requires GPS mocking');
    test('should return null when position is null', () async {}, skip: 'Requires GPS mocking');
    test('should return coordinates map', () async {}, skip: 'Requires GPS mocking');
    test('should return null when position is null for coordinates', () async {}, skip: 'Requires GPS mocking');
  });
} 