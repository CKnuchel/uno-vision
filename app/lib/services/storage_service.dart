import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/storage_keys.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> getPlayerName() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.playerName);
  }

  Future<String?> getPlayerUUID() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.playerUUID);
  }

  Future<void> savePlayerName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.playerName, name);
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.themeMode, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.themeMode);
  }
}
