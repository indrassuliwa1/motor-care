import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Singleton pattern agar tidak memakan memori berlebih
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future init() async {
    // Inisialisasi Timezone untuk Scheduled Notification
    tz.initializeTimeZones();

    // Konfigurasi icon notifikasi bawaan Android (ic_launcher)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  // 1. Notifikasi Manual / Langsung
  Future showNotification({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'motor_care_channel',
      'Motor Care Notifications',
      channelDescription: 'Notifikasi langsung untuk info service',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, platformDetails);
  }

  // 2. Notifikasi Terjadwal (Scheduled)
  Future scheduleNotification({
    required int id, 
    required String title, 
    required String body, 
    required DateTime scheduledDate
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'motor_care_scheduled',
      'Motor Care Scheduled',
      channelDescription: 'Pengingat otomatis jadwal service',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Tetap jalan meski aplikasi di-close
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // 3. Batalkan Notifikasi (Bila jadwal di-edit/dihapus)
  Future cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}