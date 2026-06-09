import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<void> showNewTaskNotification(int count) async {
    const android = AndroidNotificationDetails(
      'neko_tasks',
      'Task Notifications',
      channelDescription: 'Notifikasi paket pengiriman baru',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(
      1,
      'Paket Baru Masuk!',
      count == 1 ? 'Ada 1 paket baru menunggu pengantaran.' : 'Ada $count paket baru menunggu pengantaran.',
      const NotificationDetails(android: android),
    );
  }
}
