import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/balance.dart';
import '../core/game_state.dart';
import 'components/background_component.dart';
import 'components/coin_component.dart';
import 'components/player_component.dart';
import 'components/spawner_component.dart';
import 'components/sword_component.dart';
import 'components/zombie_component.dart';

/// Game utama ZOMBO (Phase 1).
///
/// - Background arena fixed (cover, tanpa scroll).
/// - [player] gerak via [joystick]; [SwordComponent] orbit + hit.
/// - [SpawnerComponent] spawn zombie; koin magnet + pickup.
/// - Game over -> engine pause + dialog HUD; [restart] reset bersih.
class ZomboGame extends FlameGame {
  ZomboGame({required this.state});

  /// State terpusat (dibaca HUD overlay).
  final GameState state;

  /// Joystick virtual kiri bawah (Flame bawaan).
  late final JoystickComponent joystick;

  /// Player (dipakai pedang/zombie/koin sebagai target).
  late final PlayerComponent player;

  /// Zombie yang hidup saat ini.
  final zombies = <ZombieComponent>[];

  /// Koin yang jatuh saat ini.
  final coins = <CoinComponent>[];

  late final BackgroundComponent _background;
  late final SwordComponent _sword;
  late final SpawnerComponent _spawner;

  final _random = math.Random();

  /// Detik sejak run dimulai (jam game, berhenti saat game over).
  double runTime = 0;

  bool get isGameOver => state.isGameOver.value;

  /// Interval spawn saat ini (1.2 dtk -> 0.25 dtk di menit ke-5).
  double get spawnInterval {
    final t = (runTime / (Balance.spawnRampMinutes * 60)).clamp(0.0, 1.0);
    return math.max(
      Balance.spawnIntervalMin,
      Balance.spawnIntervalStart -
          (Balance.spawnIntervalStart - Balance.spawnIntervalMin) * t,
    );
  }

  @override
  Future<void> onLoad() async {
    // Background arena.
    final mapSprite = await loadSprite('map_arena.jpg');
    _background = BackgroundComponent(sprite: mapSprite);
    add(_background);

    // Player di tengah arena.
    player = PlayerComponent()..position = size / 2;
    add(player);

    // Pedang orbit (tier 1 di Phase 1).
    final swordSprite = await loadSprite('sword_tier1.png');
    _sword = SwordComponent(sprite: swordSprite);
    add(_sword);

    // Spawner zombie.
    _spawner = SpawnerComponent();
    add(_spawner);

    // Joystick kiri bawah (paling atas agar mudah disentuh).
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 28,
        paint: Paint()..color = Colors.white.withValues(alpha: 0.85),
      ),
      background: CircleComponent(
        radius: 60,
        paint: Paint()..color = Colors.black.withValues(alpha: 0.35),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 48),
    );
    add(joystick);

    _fitBackground();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;
    runTime += dt;
    state.elapsedSeconds.value = runTime.floor();
    // Bersihkan zombie yang HP-nya habis (damage terjadi di SwordComponent).
    for (final zombie in List.of(zombies)) {
      if (zombie.hp <= 0) _killZombie(zombie);
    }
  }

  /// Zombie mati: drop koin, kills++, hapus.
  void _killZombie(ZombieComponent zombie) {
    zombies.remove(zombie);
    zombie.removeFromParent();
    state.kills.value++;
    final coinCount = Balance.zombieStats[zombie.type]!.coins;
    for (var i = 0; i < coinCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final velocity = Vector2(math.cos(angle), math.sin(angle)) *
          Balance.coinScatterSpeed;
      final coin = CoinComponent(
        position: zombie.position.clone(),
        velocity: velocity,
      );
      coins.add(coin);
      add(coin);
    }
  }

  /// Player kena hit zombie (i-frames ditangani PlayerComponent).
  void damagePlayer(int damage) {
    if (isGameOver) return;
    player.takeDamage(damage);
    if (state.hp.value <= 0) _gameOver();
  }

  void _gameOver() {
    state.isGameOver.value = true;
    pauseEngine();
  }

  /// Restart bersih: hapus semua entitas, reset state, lanjut lagi.
  void restart() {
    for (final zombie in List.of(zombies)) {
      zombie.removeFromParent();
    }
    zombies.clear();
    for (final coin in List.of(coins)) {
      coin.removeFromParent();
    }
    coins.clear();
    runTime = 0;
    state.reset();
    player.reset();
    _spawner.resetTimer();
    resumeEngine();
  }

  /// Spawn satu zombie di tepi arena (dipanggil SpawnerComponent).
  void spawnZombie() {
    if (zombies.length >= Balance.maxAliveZombies) return;
    final zombie = ZombieComponent(
      type: _pickType(),
      position: _edgePosition(),
    );
    zombies.add(zombie);
    add(zombie);
  }

  /// Tipe zombie: Normal selalu ada; Cepat muncul >30 dtk, Tank >90 dtk.
  ZombieType _pickType() {
    final t = runTime;
    final fastWeight = t > 30 ? math.min(0.35, (t - 30) / 300) : 0.0;
    final tankWeight = t > 90 ? math.min(0.2, (t - 90) / 300) : 0.0;
    final roll = _random.nextDouble();
    if (roll < tankWeight) return ZombieType.tank;
    if (roll < tankWeight + fastWeight) return ZombieType.fast;
    return ZombieType.normal;
  }

  Vector2 _edgePosition() {
    const inset = 12.0;
    final w = size.x;
    final h = size.y;
    switch (_random.nextInt(4)) {
      case 0:
        return Vector2(_random.nextDouble() * w, inset);
      case 1:
        return Vector2(_random.nextDouble() * w, h - inset);
      case 2:
        return Vector2(inset, _random.nextDouble() * h);
      default:
        return Vector2(w - inset, _random.nextDouble() * h);
    }
  }

  /// Koin keambil player.
  void collectCoin(CoinComponent coin) {
    coins.remove(coin);
    coin.removeFromParent();
    state.coins.value++;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _fitBackground();
  }

  void _fitBackground() {
    final spriteSize = Vector2(1024, 1024);
    _background.fitTo(size, spriteSize);
  }
}
