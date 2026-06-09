import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/mobile/domain/mobile_models.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required ApiService apiService}) : _api = apiService {
    _initPrefs();
  }

  final ApiService _api;

  MobileProfileResponse? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _pushNotif = true;
  bool _darkMode = false;
  String _appVersion = '';
  String _buildNumber = '';

  MobileProfileResponse? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get pushNotif => _pushNotif;
  bool get darkMode => _darkMode;
  String get appVersion => _appVersion;
  String get buildNumber => _buildNumber;

  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotif = prefs.getBool('push_notif') ?? true;
    _darkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getProfile(),
        PackageInfo.fromPlatform(),
        SharedPreferences.getInstance(),
      ]);
      _profile = results[0] as MobileProfileResponse;
      final info = results[1] as PackageInfo;
      final prefs = results[2] as SharedPreferences;
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
      _pushNotif = prefs.getBool('push_notif') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({String? name, String? phone, String? email}) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _api.updateProfile(name: name, phone: phone, email: email);
      await loadProfile();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setPushNotif(bool value) async {
    _pushNotif = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notif', value);
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }
}
