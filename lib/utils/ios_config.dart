import 'package:flutter/foundation.dart';
import 'shared_preferences_util.dart';
class IOSConfig {
  static const String _iosKeyPrefix = 'ios_';
  static Future<bool> saveIOSSetting(String key, dynamic value) async {
    final prefixedKey = _iosKeyPrefix + key;
    if (value is String) {
      return await SharedPreferencesUtil.saveString(prefixedKey, value);
    } else if (value is bool) {
      return await SharedPreferencesUtil.saveBool(prefixedKey, value);
    } else if (value is int) {
      return await SharedPreferencesUtil.saveInt(prefixedKey, value);
    } else if (value is double) {
      return await SharedPreferencesUtil.saveDouble(prefixedKey, value);
    }
    return false;
  }
  static Future<dynamic> getIOSSetting(String key, {dynamic defaultValue}) async {
    final prefixedKey = _iosKeyPrefix + key;
    if (defaultValue is String) {
      return await SharedPreferencesUtil.getString(prefixedKey) ?? defaultValue;
    } else if (defaultValue is bool) {
      return await SharedPreferencesUtil.getBool(prefixedKey) ?? defaultValue;
    } else if (defaultValue is int) {
      return await SharedPreferencesUtil.getInt(prefixedKey) ?? defaultValue;
    } else if (defaultValue is double) {
      return await SharedPreferencesUtil.getDouble(prefixedKey) ?? defaultValue;
    }
    return defaultValue;
  }
  static Future<bool> removeIOSSetting(String key) async {
    final prefixedKey = _iosKeyPrefix + key;
    return await SharedPreferencesUtil.remove(prefixedKey);
  }
  static Future<bool> hasIOSSetting(String key) async {
    final prefixedKey = _iosKeyPrefix + key;
    return await SharedPreferencesUtil.containsKey(prefixedKey);
  }
} 
