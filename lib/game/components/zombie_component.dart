import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/balance.dart';
import '../zombo_game.dart';

/// Satu zombie: kejar player, kena hit -> flash putih + knockback,
/// mati -> ditangani [ZomboGame] (drop koin, kills++).
class ZombieComponent extends SpriteComponent with HasGameReference<ZomboGame> {
  ZombieComponent({required this.type, required super.position})
      : hp = Balance.zombieStats[type]!.hp,
        super(
          size: _sizeFor(type),
          anchor: Anchor.center,
          paint: Paint()..filterQuality = FilterQuality.none,
        );

  final ZombieType type;

  int hp;
  double lastHitAt = -10;
  double _flashTimer = 0;
  double _bobTime = 0;
  Vector2 _knockback = Vector2.zero();

  ZombieStats get stats => Balance.zombieStats[type]!;
  int get maxHp => stats.hp;

  /// Radius hit (tengah zombie ke tepi).
  double get hitRadius => switch (type) {
        ZombieType.normal => 30,
        ZombieType.fast => 26,
        ZombieType.tank => 45,
      };

  static Vector2 _sizeFor(ZombieType type) => switch (type) {
        ZombieType.normal => Vector2(64, 82),
        ZombieType.fast => Vector2(56, 84),
        ZombieType.tank => Vector2(96, 87),
      };

  static String _spriteFor(ZombieType type) => switch (type) {
        ZombieType.normal => 'zombie_normal.png',
        ZombieType.fast => 'zombie_fast.png',
        ZombieType.tank => 'zombie_tank.png',
      };

  static const _flashFilter =
      ColorFilter.mode(Colors.white, BlendMode.srcATop);
  static final _barBg = Paint()..color = Colors.black54;
  static final _barFill = Paint()..color = Colors.lightGreen;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(_spriteFor(type));
  }

  /// Kena pedang: HP kurang, flash, knockback menjauh dari player.
  void takeHit(int damage, double now, double swordAngle) {
    hp -= damage;
    lastHitAt = now;
    _flashTimer = 0.12;
    paint.colorFilter = _flashFilter;
    var away = position - game.player.position;
    if (away.length < 1) {
      away = Vector2(math.cos(swordAngle), math.sin(swordAngle));
    } else {
      away.normalize();
    }
    _knockback += away * 90;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;

    // Kejar player.
    final toPlayer = game.player.position - position;
    final dist = toPlayer.length;
    if (dist > 1) {
      position += toPlayer.normalized() * stats.speed * dt;
    }

    // Knockback (decay cepat).
    position += _knockback * dt;
    _knockback *= math.exp(-8 * dt);

    // Bobbing (animasi jalan palsu — sprite single-frame).
    _bobTime += dt;

    // Flash putih selesai -> kembalikan warna normal.
    if (_flashTimer > 0) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) paint.colorFilter = null;
    }

    // Sentuh player -> damage (player punya i-frames).
    if (dist < hitRadius + Balance.playerHitRadius) {
      game.damagePlayer(stats.touchDamage);
    }
  }

  @override
  void render(Canvas canvas) {
    // Bobbing: geser sprite +/-2px (HP bar tidak ikut goyang).
    canvas.save();
    canvas.translate(0, math.sin(_bobTime * 8) * 2);
    super.render(canvas);
    canvas.restore();

    // HP bar mini di atas zombie (hanya saat HP berkurang).
    if (hp < maxHp) {
      const barH = 6.0;
      const barY = -12.0;
      canvas.drawRect(
        Rect.fromLTWH(0, barY, size.x, barH),
        _barBg,
      );
      final frac = (hp / maxHp).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(0, barY, size.x * frac, barH),
        _barFill,
      );
    }
  }
}
