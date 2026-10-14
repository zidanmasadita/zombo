import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/balance.dart';
import '../zombo_game.dart';

/// Pedang orbit: muter non-stop mengelilingi player, menghantam zombie.
///
/// - Anchor di gagang (dari manifest preprocessing, per tier) — VERIFY
///   visual di HP; gagang harus nempel di radius orbit, blade keluar.
/// - Hit detection: sudut zombie vs sudut pedang + band radial blade.
/// - Per-zombie hit cooldown agar satu sapuan tidak multi-hit tiap frame.
/// - Sprite + ukuran + anchor ganti otomatis saat [GameState.swordTier] berubah
///   (upgrade di Phase 2).
class SwordComponent extends SpriteComponent with HasGameReference<ZomboGame> {
  SwordComponent({required super.sprite})
      : super(
          size: Vector2(96, 34),
          anchor: const Anchor(0.343, 0.5),
          paint: Paint()..filterQuality = FilterQuality.none,
        );

  /// Visual per tier: (file sprite, lebar tampil, tinggi tampil, anchorX gagang).
  /// anchorX dari manifest preprocessing (estimasi — VERIFY visual di HP).
  static const _tierVisuals = [
    ('sword_tier1.png', 96.0, 34.0, 0.343),
    ('sword_tier2.png', 112.0, 34.0, 0.321),
    ('sword_tier3.png', 128.0, 40.0, 0.316),
  ];

  final _sprites = <int, Sprite>{};
  int _currentTier = 0;
  double _anchorX = 0.343;

  double _angle = 0;

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < _tierVisuals.length; i++) {
      _sprites[i] = await game.loadSprite(_tierVisuals[i].$1);
    }
    _applyTier(0);
  }

  void _applyTier(int tier) {
    _currentTier = tier;
    final visual = _tierVisuals[tier];
    sprite = _sprites[tier];
    size.setValues(visual.$2, visual.$3);
    _anchorX = visual.$4;
    anchor = Anchor(_anchorX, 0.5);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final tierIndex = game.state.swordTier.value;
    if (tierIndex != _currentTier) _applyTier(tierIndex);
    final tier = Balance.swordTiers[tierIndex];
    _angle += tier.spinSpeed * dt;

    final playerPos = game.player.position;
    position = playerPos +
        Vector2(math.cos(_angle), math.sin(_angle)) * tier.orbitRadius;
    angle = _angle;

    // Band radial blade: dari gagang sampai ujung blade.
    final tipDist = tier.orbitRadius + (1 - _anchorX) * size.x;
    for (final zombie in game.zombies) {
      if (game.isGameOver) break;
      if (game.runTime - zombie.lastHitAt < Balance.swordHitCooldown) {
        continue;
      }
      final toZombie = zombie.position - playerPos;
      final dist = toZombie.length;
      if (dist < tier.orbitRadius - zombie.hitRadius ||
          dist > tipDist + zombie.hitRadius) {
        continue;
      }
      final zombieAngle = math.atan2(toZombie.y, toZombie.x);
      var diff = zombieAngle - _angle;
      while (diff > math.pi) {
        diff -= 2 * math.pi;
      }
      while (diff < -math.pi) {
        diff += 2 * math.pi;
      }
      if (diff.abs() < Balance.swordHitAngle) {
        zombie.takeHit(tier.damage, game.runTime, _angle);
      }
    }
  }
}
