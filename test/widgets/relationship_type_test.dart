import 'package:flutter_test/flutter_test.dart';

// Test the relationship type text conversion function
void main() {
  group('Relationship Type Text Conversion', () {
    test('should convert C to Casual', () {
      expect(_getRelationshipTypeText('C'), equals('Casual'));
    });

    test('should convert S to Serious', () {
      expect(_getRelationshipTypeText('S'), equals('Serious'));
    });

    test('should convert F to Friendship', () {
      expect(_getRelationshipTypeText('F'), equals('Friendship'));
    });

    test('should convert B to Business', () {
      expect(_getRelationshipTypeText('B'), equals('Business'));
    });

    test('should handle null values', () {
      expect(_getRelationshipTypeText(null), equals('Not specified'));
    });

    test('should handle unknown values', () {
      expect(_getRelationshipTypeText('X'), equals('Not specified'));
    });
  });

  group('Multiple Relationship Types Text Conversion', () {
    test('should convert array of types to comma-separated text', () {
      expect(_getRelationshipTypesText(['C', 'S']), equals('Casual, Serious'));
    });

    test('should convert single string to text', () {
      expect(_getRelationshipTypesText('C'), equals('Casual'));
    });

    test('should handle empty array', () {
      expect(_getRelationshipTypesText([]), equals('Not specified'));
    });

    test('should handle null values', () {
      expect(_getRelationshipTypesText(null), equals('Not specified'));
    });
  });
}

// Helper function to test relationship type conversion
String _getRelationshipTypeText(String? type) {
  switch (type) {
    case 'C':
      return 'Casual';
    case 'S':
      return 'Serious';
    case 'F':
      return 'Friendship';
    case 'B':
      return 'Business';
    default:
      return 'Not specified';
  }
}

// Helper function to test multiple relationship types conversion
String _getRelationshipTypesText(dynamic types) {
  if (types == null) return 'Not specified';
  
  List<String> typeList;
  if (types is List) {
    typeList = types.cast<String>();
  } else if (types is String) {
    // Handle legacy single value format
    typeList = [types];
  } else {
    return 'Not specified';
  }
  
  if (typeList.isEmpty) return 'Not specified';
  
  return typeList.map((type) => _getRelationshipTypeText(type)).join(', ');
} 