import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static IO.Socket? _socket;
  static bool _isInitialized = false;

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

      _isInitialized = true;
      print('Local notifications initialized successfully');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Initialize WebSocket connection for real-time notifications
  static Future<void> initializeWebSocket() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      _socket = IO.io('https://key-match-dating-app-a069d14fdf4a.herokuapp.com', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token}
      });

      _socket!.onConnect((_) {
        print('WebSocket connected for notifications');
      });

      _socket!.onDisconnect((_) {
        print('WebSocket disconnected');
      });

      _socket!.on('new_message', (data) {
        print('Received new message notification: $data');
        _handleNewMessageNotification(data);
      });

      _socket!.on('new_match', (data) {
        print('Received new match notification: $data');
        _handleNewMatchNotification(data);
      });

      _socket!.connect();
    } catch (e) {
      print('Error initializing WebSocket: $e');
    }
  }

  // Handle new message notification from WebSocket
  static void _handleNewMessageNotification(dynamic data) {
    if (data is Map<String, dynamic>) {
      final senderName = data['sender']?['firstName'] ?? 'Someone';
      final content = data['content'] ?? 'New message';
      final matchId = data['matchId']?.toString() ?? '';

      showNewMessageNotification(
        senderName: senderName,
        messageContent: content,
        matchId: matchId,
      );
    }
  }

  // Handle new match notification from WebSocket
  static void _handleNewMatchNotification(dynamic data) {
    if (data is Map<String, dynamic>) {
      final matchedUserName = data['matchedUserName'] ?? 'Someone';
      final isCurrentUser = data['isCurrentUser'] ?? false;
      
      // Only show notification if it's not the current user who initiated the match
      if (!isCurrentUser) {
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
      }
    }
  }

  // Handle local notification taps
  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  // Handle navigation based on notification data
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // This will be implemented in the main app to navigate to the appropriate screen
    // For now, we'll just print the data
    print('Navigate to: $data');
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'key_match_messages',
      'Key Match Messages',
      channelDescription: 'Notifications for new messages in Key Match',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
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
  }

  // Show custom notification for new message
  static Future<void> showNewMessageNotification({
    required String senderName,
    required String messageContent,
    required String matchId,
  }) async {
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

  // Disconnect WebSocket
  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
} 