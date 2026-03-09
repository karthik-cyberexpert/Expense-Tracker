import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import '../screens/add_transaction_screen.dart';
import '../models/notification_record.dart';
import 'database_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize Local Notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload == '/add_transaction') {
          _handleMessageClick({'route': '/add_transaction'});
        }
      },
    );

    // Create a high importance channel for Android
    const androidNotificationChannel = AndroidNotificationChannel(
      'expense_tracker_channel',
      'Expense Tracker Notifications',
      description: 'Transaction and system updates',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);

    // Request permission (mostly for iOS/Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize without blocking for token
    _messaging.getToken().then((token) {
      debugPrint("************************************************");
      debugPrint("FCM TOKEN: $token");
      debugPrint("************************************************");
    }).catchError((e) {
      debugPrint("Error getting FCM token: $e");
    });
    
    // Handle background messages separately
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle other listeners...
    _setupMessageListeners();
  }

  static void _setupMessageListeners() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.notification?.title}");
      // For now, we rely on the native side for the UPI monitor, 
      // but this handles remote push notifications.
    });

    // Handle clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageClick(message.data);
    });

    // Handle initial message if app was closed
    _messaging.getInitialMessage().then((initialMessage) {
      if (initialMessage != null) {
        _handleMessageClick(initialMessage.data);
      }
    });
  }

  static void _handleMessageClick(Map<String, dynamic> data) {
    if (data['route'] == '/add_transaction') {
      final source = data['source'] ?? 'External';
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => AddTransactionScreen(initialTitle: '$source Payment'),
        ),
      );
    }
  }

  static Future<void> showTransactionNotification({
    required String title,
    required double amount,
    required bool isIncome,
  }) async {
    final type = isIncome ? "Income" : "Expense";
    final currencySymbol = "₹";
    
    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: 'Transaction Recorded!',
      body: '$type of $currencySymbol${amount.toStringAsFixed(2)} for "$title"',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'expense_tracker_channel',
          'Expense Tracker Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
      payload: '/home',
    );

    // Save to database
    final record = NotificationRecord()
      ..title = 'Transaction Recorded!'
      ..body = '$type of $currencySymbol${amount.toStringAsFixed(2)} for "$title"'
      ..timestamp = DateTime.now()
      ..amount = amount
      ..isIncome = isIncome;
    await DatabaseService().addNotificationRecord(record);
  }

  static Future<void> showHeartTouchingNotification() async {
    final messages = [
      "We missed you! Your budget is waiting for its hero. ❤️",
      "Tracking expenses is a step towards your dreams. Come back! ✨",
      "A small entry today, a big saving tomorrow. We're here for you. 🏠",
      "Remember your financial goals? Let's reach them together! 🚀",
      "Your money worked hard today, did you record its journey? 💸",
    ];
    final randomMessage = messages[DateTime.now().millisecond % messages.length];

    await _localNotifications.show(
      id: 999,
      title: "It's been a while...",
      body: randomMessage,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'expense_tracker_channel',
          'Expense Tracker Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: '/home',
    );

    // Save to database
    final record = NotificationRecord()
      ..title = "It's been a while..."
      ..body = randomMessage
      ..timestamp = DateTime.now()
      ..isRead = false;
    await DatabaseService().addNotificationRecord(record);
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` first.
  debugPrint("Handling a background message: ${message.messageId}");
}
