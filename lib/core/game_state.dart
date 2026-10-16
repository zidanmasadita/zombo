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

  /// Waktu survive terbaik (detik) antar sesi. TIDAK di-reset per run.
  final ValueNotifier<int> bestTime = ValueNotifier(0);

  /// Kills terbanyak antar sesi. TIDAK di-reset per run.
  final ValueNotifier<int> bestKills = ValueNotifier(0);

  /// True jika run yang baru berakhir memecahkan rekor (time atau kills).
  final ValueNotifier<bool> isNewRecord = ValueNotifier(false);

  /// True saat game dijeda.
  final ValueNotifier<bool> isPaused = ValueNotifier(false);

  /// True saat player mati (game over).
  final ValueNotifier<bool> isGameOver = ValueNotifier(false);

  /// True saat di menu utama (bukan dalam run).
  final ValueNotifier<bool> isMenu = ValueNotifier(false);

  /// True saat suara di-mute (settings, tersimpan antar sesi).
  final ValueNotifier<bool> isMuted = ValueNotifier(false);

  /// True saat getar nyala (settings, tersimpan antar sesi).
  final ValueNotifier<bool> isVibration = ValueNotifier(true);

  /// Fraksi HP boss (0.0 - 1.0); -1 = tidak ada boss aktif.
  final ValueNotifier<double> bossHpFrac = ValueNotifier(-1);

  /// True saat banner peringatan "BOSS DATANG!" tampil.
  final ValueNotifier<bool> bossWarningVisible = ValueNotifier(false);

  /// Kembalikan semua nilai ke awal run baru.
  void reset() {
    hp.value = 100;
    coins.value = 0;
    kills.value = 0;
    elapsedSeconds.value = 0;
    swordTier.value = 0;
    isPaused.value = false;
    isGameOver.value = false;
    isNewRecord.value = false;
    bossHpFrac.value = -1;
    bossWarningVisible.value = false;
    // bestTime / bestKills / isMenu / isMuted / isVibration TIDAK di-reset.
    // isMenu diatur eksplisit oleh startRun()/toMenu().
  }

  void dispose() {
    hp.dispose();
    coins.dispose();
    kills.dispose();
    elapsedSeconds.dispose();
    swordTier.dispose();
    bestTime.dispose();
    bestKills.dispose();
    isNewRecord.dispose();
    isPaused.dispose();
    isGameOver.dispose();
    isMenu.dispose();
    isMuted.dispose();
    isVibration.dispose();
    bossHpFrac.dispose();
    bossWarningVisible.dispose();
  }
}
