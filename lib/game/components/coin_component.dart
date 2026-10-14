import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/balance.dart';
import '../zombo_game.dart';

/// Koin: sprite animasi muter (4 frame `coin_spin_0..3`), magnet ke player,
/// keambil saat bersentuhan.
class CoinComponent extends SpriteAnimationComponent
    with HasGameReference<ZomboGame> {
  CoinComponent({required super.position, required Vector2 velocity})
      : _velocity = velocity,
        super(
          size: Vector2(22, 22),
          anchor: Anchor.center,
          paint: Paint()..filterQuality = FilterQuality.none,
        );

  Vector2 _velocity;

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.spriteList(
      [
        for (var i = 0; i < 4; i++)
          await game.loadSprite('coin_spin_$i.png'),
      ],
      stepTime: 0.12,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;

    final toPlayer = game.player.position - position;
    final dist = toPlayer.length;
    if (dist < Balance.coinMagnetRadius && dist > 1) {
      // Magnet: percepat ke arah player (efek kesedot, makin dekat makin kencang).
      _velocity += toPlayer.normalized() * Balance.coinMagnetPull * dt;
      if (_velocity.length > Balance.coinMagnetMaxSpeed) {
        _velocity = _velocity.normalized() * Balance.coinMagnetMaxSpeed;
      }
    } else {
      // Gesekan: kecepatan awal (scatter) cepat habis.
      _velocity *= math.exp(-6 * dt);
    }
    position += _velocity * dt;

    if ((game.player.position - position).length <
        Balance.coinPickupRadius) {
      game.collectCoin(this);
    }
  }
}
