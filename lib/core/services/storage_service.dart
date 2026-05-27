import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class StorageService {
  Future<void> init();
  Future<bool> setString(String key, String value);
  String? getString(String key);
  Future<bool> setBool(String key, bool value);
  bool? getBool(String key);
  Future<bool> setInt(String key, int value);
  int? getInt(String key);
  Future<bool> setDouble(String key, double value);
  double? getDouble(String key);
  Future<bool> setStringList(String key, List<String> value);
  List<String>? getStringList(String key);
  Future<bool> remove(String key);
  Future<void> removeMany(List<String> keys);
  Future<bool> clear();
  bool containsKey(String key);
}

class SharedPreferencesService implements StorageService {
  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  @override
  bool? getBool(String key) => _prefs.getBool(key);
  @override
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  @override
  int? getInt(String key) => _prefs.getInt(key);
  @override
  Future<bool> setDouble(String key, double value) => _prefs.setDouble(key, value);
  @override
  double? getDouble(String key) => _prefs.getDouble(key);
  @override
  Future<bool> setStringList(String key, List<String> value) => _prefs.setStringList(key, value);
  @override
  List<String>? getStringList(String key) => _prefs.getStringList(key);
  @override
  Future<bool> remove(String key) => _prefs.remove(key);
  @override
  Future<void> removeMany(List<String> keys) async {
    await Future.wait(keys.map((k) => _prefs.remove(k)));
  }
  @override
  Future<bool> clear() => _prefs.clear();
  @override
  bool containsKey(String key) => _prefs.containsKey(key);
}

class HiveStorageService implements StorageService {
  late Box _box;
  static const String _boxName = 'psicolearn_data';

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<bool> setString(String key, String value) async {
    await _box.put(key, value);
    return true;
  }

  @override
  String? getString(String key) => _box.get(key) as String?;

  @override
  Future<bool> setBool(String key, bool value) async {
    await _box.put(key, value);
    return true;
  }

  @override
  bool? getBool(String key) => _box.get(key) as bool?;

  @override
  Future<bool> setInt(String key, int value) async {
    await _box.put(key, value);
    return true;
  }

  @override
  int? getInt(String key) => _box.get(key) as int?;

  @override
  Future<bool> setDouble(String key, double value) async {
    await _box.put(key, value);
    return true;
  }

  @override
  double? getDouble(String key) {
    final val = _box.get(key);
    if (val is int) return val.toDouble();
    return val as double?;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    await _box.put(key, value);
    return true;
  }

  @override
  List<String>? getStringList(String key) {
    final list = _box.get(key);
    if (list == null) return null;
    return List<String>.from(list);
  }

  @override
  Future<bool> remove(String key) async {
    await _box.delete(key);
    return true;
  }

  @override
  Future<void> removeMany(List<String> keys) async {
    await _box.deleteAll(keys);
  }

  @override
  Future<bool> clear() async {
    await _box.clear();
    return true;
  }

  @override
  bool containsKey(String key) => _box.containsKey(key);
}
