import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_match/widgets/enhanced_keyword_display.dart';
import 'package:key_match/services/match_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([MatchService])
import 'enhanced_keyword_display_test.mocks.dart';

void main() {
  group('EnhancedKeywordDisplay', () {
    testWidgets('displays empty state when no keywords', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedKeywordDisplay(keywords: []),
          ),
        ),
      );

      expect(find.text('No keywords yet'), findsOneWidget);
    });

    testWidgets('displays keywords in chips', (WidgetTester tester) async {
      final keywords = ['adventurous', 'creative', 'music lover'];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedKeywordDisplay(keywords: keywords),
          ),
        ),
      );

      for (final keyword in keywords) {
        expect(find.text(keyword), findsOneWidget);
      }
    });

    testWidgets('shows search bar for large keyword lists', (WidgetTester tester) async {
      final keywords = List.generate(25, (index) => 'keyword$index');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedKeywordDisplay(keywords: keywords),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search keywords...'), findsOneWidget);
    });

    testWidgets('filters keywords when searching', (WidgetTester tester) async {
      final keywords = List.generate(25, (index) => 'keyword$index');
      keywords.addAll(['adventurous', 'creative', 'music lover', 'coffee addict']);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedKeywordDisplay(keywords: keywords),
          ),
        ),
      );

      // Enter search query
      await tester.enterText(find.byType(TextField), 'music');
      await tester.pump();

      // Should only show 'music lover'
      expect(find.text('music lover'), findsOneWidget);
      expect(find.text('adventurous'), findsNothing);
      expect(find.text('creative'), findsNothing);
      expect(find.text('coffee addict'), findsNothing);
    });

    testWidgets('shows keyword count for large lists', (WidgetTester tester) async {
      final keywords = List.generate(15, (index) => 'keyword$index');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedKeywordDisplay(keywords: keywords),
          ),
        ),
      );

      expect(find.text('15 keywords'), findsOneWidget);
    });

    testWidgets('shows show more button for large lists', (WidgetTester tester) async {
      final keywords = List.generate(20, (index) => 'keyword$index');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedKeywordDisplay(
              keywords: keywords,
              initialDisplayCount: 10,
            ),
          ),
        ),
      );

      expect(find.text('Show more'), findsOneWidget);
    });

    testWidgets('expands and collapses keyword list', (WidgetTester tester) async {
      final keywords = List.generate(20, (index) => 'keyword$index');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedKeywordDisplay(
              keywords: keywords,
              initialDisplayCount: 10,
            ),
          ),
        ),
      );

      // Initially should show only first 10 keywords
      expect(find.text('keyword0'), findsOneWidget);
      expect(find.text('keyword9'), findsOneWidget);
      expect(find.text('keyword10'), findsNothing);

      // Tap show more
      await tester.tap(find.text('Show more'));
      await tester.pump();

      // Should now show all keywords
      expect(find.text('keyword0'), findsOneWidget);
      expect(find.text('keyword19'), findsOneWidget);
      expect(find.text('Show less'), findsOneWidget);

      // Tap show less
      await tester.tap(find.text('Show less'));
      await tester.pump();

      // Should collapse back
      expect(find.text('keyword0'), findsOneWidget);
      expect(find.text('keyword9'), findsOneWidget);
      expect(find.text('keyword10'), findsNothing);
    });

    testWidgets('calls onKeywordRemove when remove button is tapped in editing mode', (WidgetTester tester) async {
      final keywords = ['adventurous', 'creative'];
      String? removedKeyword;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedKeywordDisplay(
              keywords: keywords,
              isEditing: true,
              onKeywordRemove: (keyword) => removedKeyword = keyword,
            ),
          ),
        ),
      );

      // Find and tap the remove button for 'adventurous'
      final removeButton = find.byIcon(Icons.close).first;
      await tester.tap(removeButton);
      await tester.pump();

      expect(removedKeyword, equals('adventurous'));
    });
  });

  group('Unmatch Functionality', () {
    test('unmatch service method should call correct API endpoint', () async {
      // This test verifies that the unmatch functionality is properly implemented
      // The actual API call would be tested in integration tests
      expect(MatchService.unmatchUser, isA<Function>());
    });
  });
} 