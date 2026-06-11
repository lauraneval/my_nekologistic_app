import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'bootstrap/app_bootstrap.dart';
import 'services/background_task_runner.dart';

/// WorkManager calls this function in a separate isolate.
/// Must be a top-level function marked with @pragma.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
    (taskName, inputData) => BackgroundTaskRunner.run(taskName),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();

  // Register background polling task (runs every 15 min when app is closed).
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    kTaskPollingTaskName,
    kTaskPollingTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(const NekoLogisticApp());
}
