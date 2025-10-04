import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Create a simple test widget that mimics the profile tab structure
class TestProfileWidget extends StatefulWidget {
  const TestProfileWidget({Key? key}) : super(key: key);

  @override
  _TestProfileWidgetState createState() => _TestProfileWidgetState();
}

class _TestProfileWidgetState extends State<TestProfileWidget> {
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header (only shown when not editing)
                  if (!_isEditing)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 60,
                              child: Icon(Icons.person, size: 60),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'John Doe',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'john.doe@example.com',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Profile Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            const TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Tell us about yourself...',
                              ),
                            )
                          else
                            const Text('No bio yet'),
                          
                          const SizedBox(height: 16),
                          
                          const Text(
                            'Gender',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'M', child: Text('Male')),
                                DropdownMenuItem(value: 'F', child: Text('Female')),
                              ],
                              onChanged: (value) {},
                            )
                          else
                            const Text('Not specified'),
                          
                          if (_isEditing) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                    });
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

void main() {
  group('Profile Widget Tests', () {
    testWidgets('should display profile widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TestProfileWidget(),
        ),
      );

      expect(find.byType(TestProfileWidget), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('should show profile header when not editing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TestProfileWidget(),
        ),
      );

      // Should show profile header elements
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('should hide profile header when editing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TestProfileWidget(),
        ),
      );

      // Tap edit profile button
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      // Profile header should be hidden
      expect(find.text('John Doe'), findsNothing);
      expect(find.text('john.doe@example.com'), findsNothing);
      expect(find.text('Edit Profile'), findsNothing);
    });

    testWidgets('should show form fields when editing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TestProfileWidget(),
        ),
      );

      // Tap edit profile button
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      // Should show form fields
      expect(find.text('Bio'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should show save and cancel buttons when editing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TestProfileWidget(),
        ),
      );

      // Tap edit profile button
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      // Should show save and cancel buttons
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should return to view mode when cancel is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TestProfileWidget(),
        ),
      );

      // Enter edit mode
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      // Verify we're in edit mode
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Press cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should return to view mode
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });
  });
} 