import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alert_threshold.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    final token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    _initialized = true;
    debugPrint('Notification service initialized');
  }

  Future<void> sendAlertNotification({
    required String city,
    required int currentAqi,
    required int threshold,
    required String message,
    required String thresholdId,
  }) async {
    final title = 'Peringatan Kualitas Udara - $city';
    final body =
        'AQI $currentAqi telah melampaui batas aman ($threshold). $message';

    const androidDetails = AndroidNotificationDetails(
      'air_quality_alert',
      'Air Quality Alerts',
      channelDescription: 'Notifikasi peringatan kualitas udara',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      thresholdId.hashCode,
      title,
      body,
      details,
      payload: 'city=$city&thresholdId=$thresholdId&aqi=$currentAqi',
    );

    debugPrint('Alert notification sent for $city');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Notification received in foreground:');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');

    if (message.notification != null) {
      _showForegroundNotification(message.notification!);
    }
  }

  Future<void> _showForegroundNotification(
    RemoteNotification notification,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'air_quality_alert',
      'Air Quality Alerts',
      channelDescription: 'Notifikasi peringatan kualitas udara',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('User tapped notification from background/terminated state');
    debugPrint('Message data: ${message.data}');
  }

  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped with payload: ${response.payload}');
  }

  Future<void> subscribeToThresholdTopic(AlertThreshold threshold) async {
    try {
      final topicName = 'alert_${threshold.id}'
          .replaceAll('-', '_')
          .toLowerCase();
      await _firebaseMessaging.subscribeToTopic(topicName);
      debugPrint('Subscribed to topic: $topicName');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromThresholdTopic(String thresholdId) async {
    try {
      final topicName = 'alert_$thresholdId'.replaceAll('-', '_').toLowerCase();
      await _firebaseMessaging.unsubscribeFromTopic(topicName);
      debugPrint('Unsubscribed from topic: $topicName');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }
}
