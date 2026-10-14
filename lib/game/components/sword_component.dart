import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/balance.dart';
import '../zombo_game.dart';

/// Pedang orbit: muter non-stop mengelilingi player, menghantam zombie.
///
/// - Anchor di gagang (estimasi manifest preprocessing: x 0.343) — VERIFY
///   visual di HP; gagang harus nempel di radius orbit, blade keluar.
/// - Hit detection: sudut zombie vs sudut pedang + band radial blade.
/// - Per-zombie hit cooldown agar satu sapuan tidak multi-hit tiap frame.
class SwordComponent extends SpriteComponent with HasGameReference<ZomboGame> {
  SwordComponent({required super.sprite})
      : super(
          size: Vector2(96, 34),
          anchor: const Anchor(0.343, 0.5),
          paint: Paint()..filterQuality = FilterQuality.none,
        );

  double _angle = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final tier = Balance.swordTiers[game.state.swordTier.value];
    _angle += tier.spinSpeed * dt;

    final playerPos = game.player.position;
    position = playerPos +
        Vector2(math.cos(_angle), math.sin(_angle)) * tier.orbitRadius;
    angle = _angle;

    // Band radial blade: dari gagang sampai ujung blade.
    final tipDist = tier.orbitRadius + (1 - 0.343) * size.x;
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
