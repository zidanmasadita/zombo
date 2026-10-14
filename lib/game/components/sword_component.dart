import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/balance.dart';
import '../zombo_game.dart';

/// Pedang orbit MESIN POTONG RUMPUT: muter super kencang (~4-5 putaran/detik)
/// sampai blade jadi blur, dan hit-nya CINCIN — zombie apa pun yang masuk
/// band radial blade kena hit (bukan cuma pas pedang lewat, karena pada
/// kecepatan ini cek sudut per-frame tidak lagi andal / tunneling).
///
/// - Anchor di gagang (dari manifest preprocessing, per tier) — VERIFY
///   visual di HP; gagang harus nempel di radius orbit, blade keluar.
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

  /// Geometri cincin blur untuk [BladeRingComponent]: (radius tengah, tebal).
  /// Cincin mengikuti jalur blade: dari gagang sampai ujung blade.
  static (double, double) ringGeometry(int tier) {
    final visual = _tierVisuals[tier];
    final bladeLen = (1 - visual.$4) * visual.$2;
    final orbit = Balance.swordTiers[tier].orbitRadius;
    return (orbit + bladeLen / 2, bladeLen);
  }

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

    // Hit CINCIN (mesin potong rumput): zombie dalam band radial blade kena,
    // tanpa cek sudut — pada 25+ rad/s, pedang melompati sudut besar tiap
    // frame sehingga cek sudut tidak andal (tunneling).
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
      zombie.takeHit(tier.damage, game.runTime, _angle);
      game.onSwordHit(zombie.position, tier.damage);
    }
  }
}

/// Cincin blur jalur blade (efek mesin potong rumput): lingkaran tembus pandang
/// yang mengikuti player, radius + tebal dari [SwordComponent.ringGeometry].
/// Satu drawCircle per frame — murah, tidak alokasi.
class BladeRingComponent extends PositionComponent
    with HasGameReference<ZomboGame> {
  BladeRingComponent() : super(anchor: Anchor.center);

  final _paint = Paint()
    ..color = Colors.white.withValues(alpha: 0.10)
    ..style = PaintingStyle.stroke;

  @override
  void update(double dt) {
    super.update(dt);
    position.setFrom(game.player.position);
  }

  @override
  void render(Canvas canvas) {
    final (midRadius, strokeWidth) =
        SwordComponent.ringGeometry(game.state.swordTier.value);
    _paint.strokeWidth = strokeWidth;
    canvas.drawCircle(Offset.zero, midRadius, _paint);
  }
}
