import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';
import '../constants/api_config.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static IO.Socket? _socket;
  static bool _isInitialized = false;

  // Use the centralized API configuration
  static String get _socketUrl => ApiConfig.webSocketUrl;

  // Initialize local notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions on iOS
      if (!kIsWeb) {
        try {
          final status = await _localNotifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          print('📱 iOS notification permissions: $status');
        } catch (e) {
          print('📱 iOS permission request failed: $e');
        }
      }

      _isInitialized = true;
      print('✅ Local notifications initialized successfully');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  // Initialize WebSocket connection for real-time notifications
  static Future<void> initializeWebSocket() async {
    try {
      print('🔌 Initializing WebSocket connection...');
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No auth token available for WebSocket');
        return;
      }

      print('🔌 Connecting to WebSocket at: $_socketUrl');
      print('🔌 Auth token: ${token.substring(0, 20)}...');
      
      _socket = IO.io(_socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token},
        'timeout': 10000,
        'forceNew': true,
      });

      _socket!.onConnect((_) {
        print('✅ WebSocket connected for notifications');
      });

      _socket!.onDisconnect((_) {
        print('❌ WebSocket disconnected');
      });

      _socket!.onConnectError((error) {
        print('❌ WebSocket connection error: $error');
      });

      _socket!.onError((error) {
        print('❌ WebSocket error: $error');
      });

      _socket!.on('new_message', (data) {
        print('📨 Received new message notification: $data');
        _handleNewMessageNotification(data);
      });

      _socket!.on('new_match', (data) {
        print('💕 Received new match notification: $data');
        _handleNewMatchNotification(data);
      });

      // Listen for any other events for debugging
      _socket!.onAny((event, data) {
        print('🔍 WebSocket event: $event with data: $data');
      });

      _socket!.connect();
      print('🔌 WebSocket connection initiated');
    } catch (e) {
      print('❌ Error initializing WebSocket: $e');
    }
  }

  // Handle new message notification from WebSocket
  static void _handleNewMessageNotification(dynamic data) {
    print('📨 Processing new message notification: $data');
    if (data is Map<String, dynamic>) {
      final senderName = data['sender']?['firstName'] ?? 'Someone';
      final content = data['content'] ?? 'New message';
      final matchId = data['matchId']?.toString() ?? '';

      print('📨 Showing notification for message from $senderName: $content');
      showNewMessageNotification(
        senderName: senderName,
        messageContent: content,
        matchId: matchId,
      );
    }
  }

  // Handle new match notification from WebSocket
  static void _handleNewMatchNotification(dynamic data) {
    print('💕 Processing new match notification: $data');
    if (data is Map<String, dynamic>) {
      final matchedUserName = data['matchedUserName'] ?? 'Someone';
      final isCurrentUser = data['isCurrentUser'] ?? false;
      
      print('💕 Match notification - isCurrentUser: $isCurrentUser, matchedUserName: $matchedUserName');
      
      // Only show notification if it's not the current user who initiated the match
      if (!isCurrentUser) {
        print('💕 Showing match notification for: $matchedUserName');
        _showLocalNotification(
          title: 'New Match! 🎉',
          body: 'You matched with $matchedUserName! Start a conversation now.',
          payload: json.encode({
            'type': 'new_match',
            'matchId': data['matchId']?.toString(),
            'matchedUserId': data['matchedUserId']?.toString(),
            'matchedUserName': matchedUserName,
          }),
        );
      } else {
        print('💕 Skipping match notification - current user initiated the match');
      }
    }
  }

  // Handle local notification taps
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  // Handle navigation based on notification data
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // This will be implemented in the main app to navigate to the appropriate screen
    // For now, we'll just print the data
    print('🧭 Navigate to: $data');
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      print('🔔 Showing local notification: $title - $body');
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'key_match_messages',
        'Key Match Messages',
        channelDescription: 'Notifications for new messages in Key Match',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      
      print('✅ Local notification shown successfully');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // Show custom notification for new message
  static Future<void> showNewMessageNotification({
    required String senderName,
    required String messageContent,
    required String matchId,
  }) async {
    print('📨 Showing message notification from $senderName: $messageContent');
    await _showLocalNotification(
      title: 'New message from $senderName',
      body: messageContent,
      payload: json.encode({
        'type': 'new_message',
        'matchId': matchId,
        'senderName': senderName,
      }),
    );
  }

  // Show custom notification for new match
  static Future<void> showNewMatchNotification({
    required String matchedUserName,
    required String matchId,
  }) async {
    print('💕 Showing match notification for: $matchedUserName');
    await _showLocalNotification(
      title: 'New Match! 🎉',
      body: 'You matched with $matchedUserName! Start a conversation now.',
      payload: json.encode({
        'type': 'new_match',
        'matchId': matchId,
        'matchedUserName': matchedUserName,
      }),
    );
  }

  // Test notification function
  static Future<void> showTestNotification() async {
    print('🧪 Showing test notification');
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification to verify the system is working!',
      payload: json.encode({
        'type': 'test',
        'message': 'Test notification'
      }),
    );
  }

  // Disconnect WebSocket
  static void disconnect() {
    print('🔌 Disconnecting WebSocket');
    _socket?.disconnect();
    _socket?.dispose();
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
    print('🗑️ All notifications cleared');
  }

  // Get connection status
  static bool get isConnected => _socket?.connected ?? false;
} 