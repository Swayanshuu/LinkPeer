import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:igit_connects/core/models/notification_model.dart';
import 'package:igit_connects/core/repositories/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:igit_connects/main.dart';
import 'package:igit_connects/features/broadcast/models/broadcast_model.dart';
import 'package:igit_connects/features/broadcast/screens/broadcast_details_screen.dart';
import 'package:igit_connects/screens/notifications/notification_screen.dart';

// Top level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Can initialize Firebase if needed, but it's usually already done
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _repository = NotificationRepository();

  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _requestPermissions();

    // Setup Local Notifications for Foreground
    await _setupLocalNotifications();

    // Get FCM Token and save to Supabase
    await saveFCMToken();

    // Listen for Token Refreshes
    _fcm.onTokenRefresh.listen((token) async {
      debugPrint("FCM token refresh received");
      await _updateTokenInSupabase(token);
      debugPrint("FCM token refresh saved");
    });

    // Handle Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle Background messages (setup handler)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle taps when app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification Tapped from background!");
      _handleNotificationTap(jsonEncode(message.data));
    });

    // Handle taps when app is killed (cold start)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("Notification Tapped from cold start!");
      _handleNotificationTap(jsonEncode(initialMessage.data));
    }

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle deep link or routing when user taps on the local notification
        _handleNotificationTap(details.payload);
      },
    );

    // Create high importance channel for Android
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> saveFCMToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint("FCM token generated");
        await _updateTokenInSupabase(token);
      }
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
    }
  }

  Future<void> _updateTokenInSupabase(String token) async {
    try {
      await _repository.updateFCMToken(token);
      debugPrint("FCM token updated in Supabase");
    } catch (e) {
      debugPrint("Error updating token in Supabase: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint("Received Foreground Message: ${message.messageId}");

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(String? payload) async {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload);
      debugPrint("Notification Tapped with payload: $data");

      if (data['type'] == 'broadcast' && data['broadcast_id'] != null) {
        final broadcastId = data['broadcast_id'];

        try {
          final response = await Supabase.instance.client
              .from('broadcasts')
              .select()
              .eq('id', broadcastId)
              .maybeSingle();

          if (response == null) {
            // Broadcast was deleted from the admin panel
            final action = () {
              if (navigatorKey.currentState != null) {
                navigatorKey.currentState!.push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(initialIndex: 1),
                  ),
                );
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (navigatorKey.currentContext != null) {
                    ScaffoldMessenger.of(
                      navigatorKey.currentContext!,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "This broadcast has been deleted or is no longer available.",
                        ),
                      ),
                    );
                  }
                });
              }
            };
            if (isMainScreenReady) {
              action();
            } else {
              pendingDeepLinkAction = action;
            }
            return;
          }

          final action = () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => BroadcastDetailsScreen(
                  broadcast: BroadcastModel.fromJson(response),
                ),
              ),
            );
          };
          if (isMainScreenReady) {
            action();
          } else {
            pendingDeepLinkAction = action;
          }
        } catch (e) {
          debugPrint('Error loading broadcast from notification: $e');
        }
      }
    } catch (e) {
      debugPrint("Error parsing payload: $e");
    }
  }

  /// Get Unread Notifications Count
  Future<int> getUnreadCount() async {
    debugPrint("Fetching unread notification count...");
    final count = await _repository.getUnreadCount();
    debugPrint("Unread count: $count");
    return count;
  }

  /// Get Paginated Notifications
  Future<List<NotificationModel>> getNotifications({
    required int offset,
    required int limit,
  }) async {
    debugPrint("Fetching notifications (offset: $offset, limit: $limit)...");
    return await _repository.getNotifications(offset: offset, limit: limit);
  }

  /// Mark Notification as Read
  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
  }
}
