import 'dart:async' show unawaited;

import 'package:flame_audio/flame_audio.dart';

/// Semua suara ZOMBO lewat sini (satu pintu, gampang di-mute/throttle).
///
/// SFX: Kenney RPG Audio (CC0, https://kenney.nl/assets/rpg-audio).
/// BGM: disintesis in-house (chiptune loop A-minor, bebas lisensi).
/// File di `assets/audio/` (prefix default FlameAudio).
class AudioService {
  AudioService._();

  static bool _muted = false;

  /// Terakhir tiap file diputar (throttle agar hit massal tidak menumpuk suara).
  static final _lastPlayed = <String, DateTime>{};

  /// Preload semua audio (dipanggil sekali di main sebelum runApp).
  static Future<void> init() async {
    await FlameAudio.audioCache.loadAll([
      'swing.mp3',
      'hit.mp3',
      'coin.mp3',
      'death.mp3',
      'upgrade.mp3',
      'player_hit.mp3',
      'game_over.mp3',
      'bgm.wav',
    ]);
  }

  static void setMuted(bool muted) {
    _muted = muted;
    if (muted) FlameAudio.bgm.stop();
  }

  static bool get isMuted => _muted;

  static void _play(String file, {int minIntervalMs = 0, double volume = 1.0}) {
    if (_muted) return;
    if (minIntervalMs > 0) {
      final now = DateTime.now();
      final last = _lastPlayed[file];
      if (last != null &&
          now.difference(last).inMilliseconds < minIntervalMs) {
        return;
      }
      _lastPlayed[file] = now;
    }
    unawaited(FlameAudio.play(file, volume: volume));
  }

  /// Pedang menyabet (whoosh, dilapis dengan hit saat kena).
  static void playSwing() => _play('swing.mp3', minIntervalMs: 80, volume: 0.5);

  /// Pedang menghantam zombie.
  static void playHit() => _play('hit.mp3', minIntervalMs: 80);

  /// Koin keambil.
  static void playCoin() => _play('coin.mp3', minIntervalMs: 60, volume: 0.7);

  /// Zombie mati.
  static void playDeath() => _play('death.mp3', minIntervalMs: 100);

  /// Upgrade pedang berhasil.
  static void playUpgrade() => _play('upgrade.mp3');

  /// Player kena hit zombie.
  static void playPlayerHit() => _play('player_hit.mp3');

  /// Game over.
  static void playGameOver() => _play('game_over.mp3');

  /// BGM loop (mulai di MAIN pertama — butuh gesture user di web).
  /// Tidak restart jika sudah jalan.
  static void startBgm() {
    if (_muted || FlameAudio.bgm.isPlaying) return;
    unawaited(FlameAudio.bgm.play('bgm.wav', volume: 0.35));
  }

  static void stopBgm() => FlameAudio.bgm.stop();
}
