import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  AppStorage._(this._preferences);

  final SharedPreferences _preferences;

  static Future<AppStorage> create() async {
    return AppStorage._(await SharedPreferences.getInstance());
  }

  bool? getBool(String key) => _preferences.getBool(key);
  int? getInt(String key) => _preferences.getInt(key);
  String? getString(String key) => _preferences.getString(key);
  List<String>? getStringList(String key) => _preferences.getStringList(key);

  Future<bool> setBool(String key, bool value) =>
      _preferences.setBool(key, value);
  Future<bool> setInt(String key, int value) => _preferences.setInt(key, value);
  Future<bool> setString(String key, String value) =>
      _preferences.setString(key, value);
  Future<bool> setStringList(String key, List<String> value) =>
      _preferences.setStringList(key, value);
  Future<bool> remove(String key) => _preferences.remove(key);
  Future<bool> clear() => _preferences.clear();
}
