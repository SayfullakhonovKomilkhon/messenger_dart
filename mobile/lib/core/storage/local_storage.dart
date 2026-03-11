import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String getTheme() => _prefs.getString('theme') ?? 'dark';
  static Future<void> setTheme(String theme) => _prefs.setString('theme', theme);

  static bool getFollowSystemTheme() => _prefs.getBool('follow_system_theme') ?? false;
  static Future<void> setFollowSystemTheme(bool value) =>
      _prefs.setBool('follow_system_theme', value);

  static int getAccentIndex() => _prefs.getInt('accent_index') ?? 0;
  static Future<void> setAccentIndex(int index) => _prefs.setInt('accent_index', index);

  static bool getRememberMe() => _prefs.getBool('remember_me') ?? false;
  static Future<void> setRememberMe(bool value) => _prefs.setBool('remember_me', value);

  static String? getSavedUserId() => _prefs.getString('saved_user_id');
  static Future<void> setSavedUserId(String? id) {
    if (id == null) return _prefs.remove('saved_user_id');
    return _prefs.setString('saved_user_id', id);
  }
}
