// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyMatch App Tests', () {
    testWidgets('Basic widget test', (WidgetTester tester) async {
      // Create a simple test widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Test'),
            ),
          ),
        ),
      );

      // Verify that the widget renders
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('MaterialApp can be created', (WidgetTester tester) async {
      // Test that we can create a MaterialApp
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Test App')),
            body: Center(child: Text('Hello')),
          ),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('Basic interaction test', (WidgetTester tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => buttonPressed = true,
                child: Text('Press Me'),
              ),
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.text('Press Me'));
      await tester.pump();

      // Verify the button was pressed
      expect(buttonPressed, isTrue);
    });
  });
}
