import 'package:shared_preferences/shared_preferences.dart';

/// Settings antar sesi (shared_preferences): mute + getar.
/// Default: suara nyala, getar nyala.
class SettingsStorage {
  SettingsStorage._();

  static const _keyMuted = 'zombo_muted';
  static const _keyVibration = 'zombo_vibration';

  static Future<({bool muted, bool vibration})> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      muted: prefs.getBool(_keyMuted) ?? false,
      vibration: prefs.getBool(_keyVibration) ?? true,
    );
  }

  static Future<void> save({
    required bool muted,
    required bool vibration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMuted, muted);
    await prefs.setBool(_keyVibration, vibration);
  }
}
