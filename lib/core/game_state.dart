import 'package:flutter/foundation.dart';

/// State game terpusat. Satu-satunya sumber kebenaran untuk HUD overlay.
/// Phase 0: field + notifier saja (nilai dummy). Mutator dipakai Phase 1/2.
class GameState {
  /// HP player saat ini.
  final ValueNotifier<int> hp = ValueNotifier(100);

  /// Koin yang dikumpulkan dalam run ini.
  final ValueNotifier<int> coins = ValueNotifier(0);

  /// Jumlah zombie yang berhasil dibunuh dalam run ini.
  final ValueNotifier<int> kills = ValueNotifier(0);

  /// Detik sejak run dimulai.
  final ValueNotifier<int> elapsedSeconds = ValueNotifier(0);

  /// Tier pedang aktif (0 = tier 1 Besi, 1 = tier 2 Api, 2 = tier 3 Petir).
  final ValueNotifier<int> swordTier = ValueNotifier(0);

  /// True saat game dijeda.
  final ValueNotifier<bool> isPaused = ValueNotifier(false);

  /// True saat player mati (game over).
  final ValueNotifier<bool> isGameOver = ValueNotifier(false);

  /// Kembalikan semua nilai ke awal run baru.
  void reset() {
    hp.value = 100;
    coins.value = 0;
    kills.value = 0;
    elapsedSeconds.value = 0;
    swordTier.value = 0;
    isPaused.value = false;
    isGameOver.value = false;
  }

  void dispose() {
    hp.dispose();
    coins.dispose();
    kills.dispose();
    elapsedSeconds.dispose();
    swordTier.dispose();
    isPaused.dispose();
    isGameOver.dispose();
  }
}
