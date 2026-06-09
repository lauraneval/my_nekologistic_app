import 'package:flutter/foundation.dart';

import '../features/mobile/domain/mobile_models.dart';
import '../services/api_service.dart';

enum HistoryTab { today, yesterday, last7Days }

class HistoryProvider extends ChangeNotifier {
  HistoryProvider({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  MobileHistoryResponse? _history;
  MobileProfileResponse? _profile;
  HistoryTab _activeTab = HistoryTab.today;
  bool _isLoading = false;
  String? _error;

  MobileHistoryResponse? get history => _history;
  MobileProfileResponse? get profile => _profile;
  HistoryTab get activeTab => _activeTab;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<MobileTaskItem> get currentItems {
    if (_history == null) return [];
    return switch (_activeTab) {
      HistoryTab.today => _history!.today,
      HistoryTab.yesterday => _history!.yesterday,
      HistoryTab.last7Days => _history!.last7Days,
    };
  }

  int get displayCount {
    if (_history == null) return 0;
    return switch (_activeTab) {
      HistoryTab.today => _history!.today.length,
      HistoryTab.yesterday => _history!.yesterday.length,
      HistoryTab.last7Days => _history!.last7Days.length,
    };
  }

  void setTab(HistoryTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([_api.getHistory(), _api.getProfile()]);
      _history = results[0] as MobileHistoryResponse;
      _profile = results[1] as MobileProfileResponse;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
