import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_env.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/mobile/domain/mobile_models.dart';
import 'notification_service.dart';

/// Unique name used for WorkManager task registration AND as the task identifier
/// passed to the callback dispatcher.
const String kTaskPollingTaskName = 'check_new_tasks';

/// Runs inside a WorkManager isolate. Must NOT depend on Provider/BuildContext.
class BackgroundTaskRunner {
  static Future<bool> run(String taskName) async {
    if (taskName != kTaskPollingTaskName) return true;

    try {
      WidgetsFlutterBinding.ensureInitialized();
      await NotificationService.initialize();

      final storage = SecureStorageService();
      final token = await storage.readAccessToken();
      if (token == null || token.isEmpty) return true;

      final response = await Dio().get(
        '${AppEnv.apiBaseUrl}/mobile/tasks',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      // Normalise the response the same way MobileCourierApiClient does.
      final raw = response.data;
      final Map<String, dynamic> json = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw)
          : {};

      final board = MobileTaskBoardResponse.fromJson(json);
      final allTasks = [...board.activeTasks, ...board.queueTasks];

      final prefs = await SharedPreferences.getInstance();
      final knownIds = (prefs.getStringList('known_task_ids') ?? []).toSet();

      final newTasks = allTasks.where((t) => !knownIds.contains(t.id)).toList();

      if (newTasks.isNotEmpty) {
        await prefs.setStringList(
          'known_task_ids',
          allTasks.map((t) => t.id).toList(),
        );
        await NotificationService.showNewTaskNotification(newTasks.length);
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
