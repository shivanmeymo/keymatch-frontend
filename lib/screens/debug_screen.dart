import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/notification_service.dart';
import '../constants/colors.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isLoading = false;
  String _debugInfo = '';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _addLog('🔍 Starting diagnostics...');

    // Test 1: Network connectivity (only on non-web platforms)
    if (!kIsWeb) {
      _addLog('Testing network connectivity...');
      try {
        // Use a simple HTTP request instead of dart:io
        final response = await http.get(Uri.parse('https://google.com'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          _addLog('✅ Network connectivity: OK');
        } else {
          _addLog('⚠️ Network connectivity: Partial (Status: ${response.statusCode})');
        }
      } catch (e) {
        _addLog('❌ Network connectivity: FAILED - $e');
      }
    } else {
      _addLog('Network connectivity: Skipped (web platform)');
    }

    // Test 2: Backend server connectivity
    _addLog('Testing backend server connectivity...');
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/auth/me'),
      ).timeout(const Duration(seconds: 5));
      
      _addLog('✅ Backend server: Responding (Status: ${response.statusCode})');
    } catch (e) {
      _addLog('❌ Backend server: FAILED - $e');
    }

    // Test 3: Session status
    _addLog('Checking session status...');
    try {
      final sessionStats = await SessionManager.getSessionStats();
      _addLog('Session stats: $sessionStats');
    } catch (e) {
      _addLog('❌ Session check failed: $e');
    }

    // Test 4: Authentication status
    _addLog('Checking authentication status...');
    try {
      final isAuthenticated = await AuthService.isAuthenticated();
      _addLog('Authentication status: ${isAuthenticated ? "Authenticated" : "Not authenticated"}');
      
      if (isAuthenticated) {
        final user = await AuthService.getCurrentUser();
        _addLog('User data: ${user != null ? "Available" : "Not available"}');
      }
    } catch (e) {
      _addLog('❌ Authentication check failed: $e');
    }

    // Test 5: API configuration
    _addLog('API Configuration:');
    _addLog('Base URL: ${ApiConfig.baseUrl}');
    _addLog('API Base URL: ${ApiConfig.apiBaseUrl}');
    _addLog('WebSocket URL: ${ApiConfig.webSocketUrl}');
    _addLog('Platform: ${kIsWeb ? "Web" : "Mobile"}');

    // Test 6: Notification system
    _addLog('Testing notification system...');
    try {
      final isConnected = NotificationService.isConnected;
      _addLog('WebSocket connected: ${isConnected ? "Yes" : "No"}');
      
      // Test notification
      await NotificationService.showTestNotification();
      _addLog('✅ Test notification sent');
    } catch (e) {
      _addLog('❌ Notification test failed: $e');
    }

    setState(() {
      _isLoading = false;
      _debugInfo = _logs.join('\n');
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Debug Diagnostics'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagnostic Results:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        _debugInfo.isEmpty ? 'Running diagnostics...' : _debugInfo,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Troubleshooting Tips:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• If network connectivity fails, check your internet connection\n'
                      '• If backend server fails, the server might be down\n'
                      '• If authentication fails, try logging out and back in\n'
                      '• If session is invalid, clear app data and restart\n'
                      '• If notifications fail, check device notification permissions',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await NotificationService.showTestNotification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test notification sent!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Notification test failed: $e')),
                          );
                        }
                      },
                      child: const Text('Send Test Notification'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await NotificationService.showNewMessageNotification(
                            senderName: 'Test User',
                            messageContent: 'This is a test message notification',
                            matchId: 'test-match-123',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test message notification sent!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Message notification test failed: $e')),
                          );
                        }
                      },
                      child: const Text('Send Test Message Notification'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await NotificationService.showNewMatchNotification(
                            matchedUserName: 'Test Match',
                            matchId: 'test-match-456',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test match notification sent!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Match notification test failed: $e')),
                          );
                        }
                      },
                      child: const Text('Send Test Match Notification'),
                    ),
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