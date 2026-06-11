import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/mobile/domain/mobile_models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Timer? _pollingTimer;
  static const _pollingInterval = Duration(seconds: 60);

  MobileTaskBoardResponse? _board;
  MobileTaskItem? _currentTask;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  String? _error;
  List<MobileTaskItem> _newTasks = [];

  MobileTaskBoardResponse? get board => _board;
  MobileTaskItem? get currentTask => _currentTask;
  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  String? get error => _error;
  List<MobileTaskItem> get newTasks => _newTasks;

  List<MobileTaskItem> get activeTasks => _board?.activeTasks ?? [];
  List<MobileTaskItem> get queueTasks => _board?.queueTasks ?? [];

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final board = await _api.getTasks();
      final knownIds = await _loadKnownIds();
      final allNew = [
        ...board.activeTasks,
        ...board.queueTasks,
      ].where((t) => !knownIds.contains(t.id)).toList();

      _board = board;
      _newTasks = allNew;

      if (allNew.isNotEmpty) {
        await _saveKnownIds(board);
        await NotificationService.showNewTaskNotification(allNew.length);
      } else if (knownIds.isEmpty) {
        await _saveKnownIds(board);
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearNewTasks() {
    _newTasks = [];
    notifyListeners();
  }

  Future<bool> acceptTask(String id) async {
    try {
      await _api.acceptTask(id);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<MobileTaskItem?> loadTaskDetail(String id) async {
    _isDetailLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentTask = await _api.getTaskDetail(id);
      return _currentTask;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Starts auto-polling every 60 seconds. Safe to call multiple times.
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => loadTasks());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Set<String>> _loadKnownIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('known_task_ids') ?? [];
    return list.toSet();
  }

  Future<void> _saveKnownIds(MobileTaskBoardResponse board) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = [
      ...board.activeTasks.map((t) => t.id),
      ...board.queueTasks.map((t) => t.id),
    ];
    await prefs.setStringList('known_task_ids', ids);
  }
}
