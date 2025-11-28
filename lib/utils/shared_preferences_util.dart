import 'package:shared_preferences/shared_preferences.dart';
class SharedPreferencesUtil {
  static SharedPreferences? _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  static Future<bool> saveString(String key, String value) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(key, value);
  }
  static Future<String?> getString(String key) async {
    if (_prefs == null) await init();
    return _prefs!.getString(key);
  }
  static Future<bool> setString(String key, String value) async {
    return await saveString(key, value);
  }
  static String? getStringSync(String key) {
    if (_prefs == null) return null;
    return _prefs!.getString(key);
  }
  static Future<bool> saveBool(String key, bool value) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(key, value);
  }
  static Future<bool?> getBool(String key) async {
    if (_prefs == null) await init();
    return _prefs!.getBool(key);
  }
  static Future<bool> saveInt(String key, int value) async {
    if (_prefs == null) await init();
    return await _prefs!.setInt(key, value);
  }
  static Future<int?> getInt(String key) async {
    if (_prefs == null) await init();
    return _prefs!.getInt(key);
  }
  static Future<bool> saveDouble(String key, double value) async {
    if (_prefs == null) await init();
    return await _prefs!.setDouble(key, value);
  }
  static Future<double?> getDouble(String key) async {
    if (_prefs == null) await init();
    return _prefs!.getDouble(key);
  }
  static Future<bool> remove(String key) async {
    if (_prefs == null) await init();
    return await _prefs!.remove(key);
  }
  static Future<bool> clear() async {
    if (_prefs == null) await init();
    return await _prefs!.clear();
  }
  static Future<bool> containsKey(String key) async {
    if (_prefs == null) await init();
    return _prefs!.containsKey(key);
  }
} 
