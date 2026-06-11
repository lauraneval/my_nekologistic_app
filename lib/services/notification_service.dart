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
      channelDescription: 'New delivery package notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(
      1,
      'New Package!',
      count == 1 ? '1 new package is waiting for delivery.' : '$count new packages are waiting for delivery.',
      const NotificationDetails(android: android),
    );
  }
}
