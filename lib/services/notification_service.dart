import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../constants/api_config.dart';

// Top-level function for background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Background message received: ${message.notification?.title}');
  // Process background message
  await NotificationService._handleRemoteMessage(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static IO.Socket? _socket;
  static bool _isInitialized = false;
  static FirebaseMessaging? _firebaseMessaging;

  // Use the centralized API configuration
  static String get _socketUrl => ApiConfig.webSocketUrl;

  // Initialize local notifications and Firebase
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Firebase
      await _initializeFirebase();
      
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

      // Create Android notification channel
      if (!kIsWeb && Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'keymatch_notifications',
          'KeyMatch Notifications',
          description: 'Notifications for matches and messages',
          importance: Importance.high,
          playSound: true,
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Request permissions on iOS and Android 13+
      if (!kIsWeb) {
        try {
          // iOS permissions
          if (Platform.isIOS) {
            final status = await _localNotifications.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
            print('📱 iOS notification permissions: $status');
          }
          
          // Android 13+ (API 33+) permissions
          if (Platform.isAndroid) {
            final status = await Permission.notification.request();
            print('📱 Android notification permission: $status');
            
            if (!status.isGranted) {
              print('⚠️  Notification permission not granted');
            }
          }
        } catch (e) {
          print('📱 Permission request failed: $e');
        }
      }

      _isInitialized = true;
      print('✅ Local notifications initialized successfully');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  // Initialize Firebase Cloud Messaging
  static Future<void> _initializeFirebase() async {
    try {
      if (!kIsWeb) {
        _firebaseMessaging = FirebaseMessaging.instance;

        // Request permissions
        NotificationSettings settings = await _firebaseMessaging!.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        print('📱 FCM permission status: ${settings.authorizationStatus}');

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          // Get FCM token
          String? token = await _firebaseMessaging!.getToken();
          if (token != null) {
            print('🔑 FCM Token: $token');
            await _registerFCMToken(token);
          }

          // Listen for token refresh
          _firebaseMessaging!.onTokenRefresh.listen((newToken) {
            print('🔄 FCM Token refreshed: $newToken');
            _registerFCMToken(newToken);
          });

          // Handle foreground messages
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            print('🔔 Foreground message received: ${message.notification?.title}');
            _handleRemoteMessage(message);
          });

          // Handle background messages
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

          // Handle when user taps notification
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            print('👆 Notification tapped: ${message.data}');
            _handleNotificationNavigation(message.data);
          });

          print('✅ Firebase Cloud Messaging initialized');
        }
      }
    } catch (e) {
      print('❌ Error initializing Firebase: $e');
    }
  }

  // Register FCM token with backend
  static Future<void> _registerFCMToken(String token) async {
    try {
      final authToken = await AuthService.getToken();
      if (authToken == null) {
        print('⚠️  No auth token, cannot register FCM token');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/auth/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token registered with backend');
      } else {
        print('❌ Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error registering FCM token: $e');
    }
  }

  // Re-register FCM token after login (public method)
  static Future<void> registerFCMTokenAfterLogin() async {
    try {
      print('🔄 Attempting to register FCM token...');
      
      if (kIsWeb) {
        print('⚠️  Web platform - FCM not supported');
        return;
      }
      
      if (_firebaseMessaging == null) {
        print('❌ Firebase Messaging not initialized!');
        print('   Trying to initialize Firebase now...');
        await _initializeFirebase();
      }
      
      if (_firebaseMessaging != null) {
        print('✅ Firebase Messaging is initialized, requesting token...');
        String? token = await _firebaseMessaging!.getToken();
        
        if (token != null) {
          print('🔑 FCM Token obtained: ${token.substring(0, 20)}...');
          await _registerFCMToken(token);
          print('✅ FCM token registration request sent to backend');
        } else {
          print('❌ getToken() returned null!');
          print('   Possible causes:');
          print('   - Google Play Services not installed/updated');
          print('   - Device not connected to internet');
          print('   - Firebase project configuration issue');
        }
      } else {
        print('❌ Firebase Messaging is still null after init attempt');
      }
    } catch (e) {
      print('❌ Error re-registering FCM token: $e');
      print('   Stack trace: ${e.toString()}');
    }
  }

  // Handle remote FCM messages
  static Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'KeyMatch',
        body: notification.body ?? '',
        payload: json.encode(data),
      );
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

      // Don't show WebSocket notification - FCM will handle it
      // WebSocket is only for real-time updates when app is open
      print('📨 Message received via WebSocket from $senderName: $content');
      print('   (Notification handled by FCM, not showing duplicate)');
    }
  }

  // Handle new match notification from WebSocket
  static void _handleNewMatchNotification(dynamic data) {
    print('💕 Processing new match notification: $data');
    if (data is Map<String, dynamic>) {
      final matchedUserName = data['matchedUserName'] ?? 'Someone';
      final isCurrentUser = data['isCurrentUser'] ?? false;
      
      print('💕 Match notification - isCurrentUser: $isCurrentUser, matchedUserName: $matchedUserName');
      
      // Don't show WebSocket notification - FCM will handle it
      // WebSocket is only for real-time updates when app is open
      if (!isCurrentUser) {
        print('💕 Match received via WebSocket with $matchedUserName');
        print('   (Notification handled by FCM, not showing duplicate)');
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