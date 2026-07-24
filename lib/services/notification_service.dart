import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (Platform.isWindows) return;
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  Future<void> startTranscriptionForegroundService() async {
    if (Platform.isWindows) return;
    await init();
    
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'transcription_channel',
      'Transcription Tasks',
      channelDescription: 'Ongoing notification for AI transcription',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
    );

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.startForegroundService(
      888,
      'Transcribing Audio',
      'AI transcription is running in the background...',
      notificationDetails: androidNotificationDetails,
      payload: 'transcription',
    );
  }

  Future<void> stopForegroundServiceAndNotifySuccess() async {
    if (Platform.isWindows) return;
    // Stop foreground service
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.stopForegroundService();

    // Show success notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'transcription_completed',
      'Transcription Complete',
      channelDescription: 'Notifications for completed transcriptions',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      889,
      'Transcription Complete!',
      'Your subtitles are ready and saved.',
      platformChannelSpecifics,
    );
  }

  Future<void> stopForegroundServiceAndNotifyError(String errorMsg) async {
    if (Platform.isWindows) return;
    // Stop foreground service
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.stopForegroundService();

    // Show error notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'transcription_error',
      'Transcription Errors',
      channelDescription: 'Notifications for failed transcriptions',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      890,
      'Transcription Failed',
      'Error: $errorMsg',
      platformChannelSpecifics,
    );
  }
}
