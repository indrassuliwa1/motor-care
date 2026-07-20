import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Pattern Singleton agar hanya ada satu instance service
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Inisialisasi ikon untuk Android (pastikan ada logo app bernama @mipmap/ic_launcher di folder res)
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Inisialisasi untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _isInitialized = true;
  }

  // FUNGSI INI YANG SEBELUMNYA TIDAK TERBACA
  Future<void> showInstantNotification({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'motocare_alert_channel', 
      'Peringatan Servis',
      channelDescription: 'Notifikasi untuk peringatan komponen yang terlambat diservis',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF305B85), 
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }

  Future<void> scheduleNotification({required int id, required String title, required String body, required DateTime scheduledDate}) async {
    // Logika penjadwalan
  }
}