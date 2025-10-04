import 'package:flutter_test/flutter_test.dart';
import 'package:key_match/services/profile_service.dart';

void main() {
  group('ProfileService.getFullImageUrl', () {
    test('should return empty string for null or empty input', () {
      expect(ProfileService.getFullImageUrl(null), equals(''));
      expect(ProfileService.getFullImageUrl(''), equals(''));
    });

    test('should return Google Cloud Storage URLs as-is', () {
      const gcsUrl = 'https://storage.googleapis.com/key-match/dating-app/image-1752088803130-874541722.jpg';
      expect(ProfileService.getFullImageUrl(gcsUrl), equals(gcsUrl));
    });

    test('should return other HTTPS URLs as-is', () {
      const httpsUrl = 'https://example.com/image.jpg';
      expect(ProfileService.getFullImageUrl(httpsUrl), equals(httpsUrl));
    });

    test('should construct full URL for /uploads/ paths', () {
      const relativePath = '/uploads/image-123.jpg';
      const expectedUrl = 'https://key-match-backend-nsx5nsymuq-uc.a.run.app/uploads/image-123.jpg';
      expect(ProfileService.getFullImageUrl(relativePath), equals(expectedUrl));
    });

    test('should construct full URL for filenames only', () {
      const filename = 'image-123.jpg';
      const expectedUrl = 'https://key-match-backend-nsx5nsymuq-uc.a.run.app/uploads/image-123.jpg';
      expect(ProfileService.getFullImageUrl(filename), equals(expectedUrl));
    });

    test('should return other relative paths as-is', () {
      const relativePath = 'dating-app/image-123.jpg';
      expect(ProfileService.getFullImageUrl(relativePath), equals(relativePath));
    });
  });
} 