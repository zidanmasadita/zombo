import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/balance.dart';
import '../zombo_game.dart';

/// Karakter utama (MC).
///
/// - Gerak mengikuti joystick floating (deadzone 0.15, muncul di titik sentuh).
/// - Animasi jalan dari 4 frame `mc_walk_0..3` saat bergerak.
/// - `mc_front` saat diam, `mc_back` saat bergerak ke atas.
/// - Posisi di-clamp ke batas dunia (±Balance.worldBound).
class PlayerComponent extends SpriteAnimationComponent
    with HasGameReference<ZomboGame> {
  PlayerComponent()
      : super(
          size: Vector2(64, 136),
          anchor: Anchor.center,
          // Nearest-neighbour: pixel-art tetap tajam, tidak blur.
          paint: Paint()..filterQuality = FilterQuality.none,
        );

  late final SpriteAnimation _walkAnimation;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _backAnimation;

  _PlayerVisual _visual = _PlayerVisual.idle;

  /// Sisa detik kebal (i-frames) setelah kena hit.
  double _invulnTimer = 0;

  static const _flashFilter =
      ColorFilter.mode(Colors.white, BlendMode.srcATop);

  /// Kena hit zombie: HP kurang (diabaikan selama i-frames), mulai kedip.
  void takeDamage(int damage) {
    if (_invulnTimer > 0) return;
    _invulnTimer = Balance.playerInvulnerableSeconds;
    game.state.hp.value = math.max(0, game.state.hp.value - damage);
  }

  /// Reset ke awal run: origin dunia, HP visual bersih, idle.
  void reset() {
    position = Vector2.zero();
    _invulnTimer = 0;
    paint.colorFilter = null;
    _setVisual(_PlayerVisual.idle);
  }

  @override
  Future<void> onLoad() async {
    // 4 frame jalan, stepTime ~0.12 (dari brief Phase 0).
    _walkAnimation = SpriteAnimation.spriteList(
      [
        for (var i = 0; i < 4; i++)
          await game.loadSprite('mc_walk_$i.png'),
      ],
      stepTime: 0.12,
    );
    _idleAnimation = SpriteAnimation.spriteList(
      [await game.loadSprite('mc_front.png')],
      stepTime: 1,
    );
    _backAnimation = SpriteAnimation.spriteList(
      [await game.loadSprite('mc_back.png')],
      stepTime: 1,
    );
    animation = _idleAnimation;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Kedip selama i-frames (tanda player sedang kebal).
    if (_invulnTimer > 0) {
      _invulnTimer -= dt;
      final flashOn = (_invulnTimer * 12).floor() % 2 == 0;
      paint.colorFilter = flashOn ? _flashFilter : null;
    } else if (paint.colorFilter != null) {
      paint.colorFilter = null;
    }

    final delta = game.joystick.delta;
    final moving = delta.length > Balance.joystickDeadzone;

    if (moving) {
      final direction = delta.normalized();
      position += direction * Balance.playerSpeed * dt;

      // Clamp pengaman ke batas dunia (bukan lagi viewport — scrolling world),
      // dengan margin setengah ukuran sprite.
      final half = size / 2;
      const b = Balance.worldBound;
      position.x = position.x.clamp(-b + half.x, b - half.x);
      position.y = position.y.clamp(-b + half.y, b - half.y);

      // Gerak ke atas (layar) -> tampilkan punggung.
      final next = direction.y < -0.3
          ? _PlayerVisual.back
          : _PlayerVisual.walk;
      _setVisual(next);
    } else {
      _setVisual(_PlayerVisual.idle);
    }
  }

  void _setVisual(_PlayerVisual next) {
    if (next == _visual) return;
    _visual = next;
    animation = switch (next) {
      _PlayerVisual.walk => _walkAnimation,
      _PlayerVisual.back => _backAnimation,
      _PlayerVisual.idle => _idleAnimation,
    };
  }
}

enum _PlayerVisual { idle, walk, back }
