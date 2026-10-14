import 'package:shared_preferences/shared_preferences.dart';

import 'game_state.dart';

/// Best score antar sesi (shared_preferences).
/// Best time & best kills disimpan terpisah (rekor masing-masing).
class BestScoreStorage {
  BestScoreStorage._();

  static const _keyBestTime = 'zombo_best_time';
  static const _keyBestKills = 'zombo_best_kills';

  /// Muat best score ke [state] (dipanggil sekali di main sebelum runApp).
  static Future<void> loadInto(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    state.bestTime.value = prefs.getInt(_keyBestTime) ?? 0;
    state.bestKills.value = prefs.getInt(_keyBestKills) ?? 0;
  }

  /// Simpan best score dari [state] (fire-and-forget dari game saat game over).
  static Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBestTime, state.bestTime.value);
    await prefs.setInt(_keyBestKills, state.bestKills.value);
  }
}
