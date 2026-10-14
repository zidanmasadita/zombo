import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/game_state.dart';
import 'components/background_component.dart';
import 'components/player_component.dart';

/// Game utama ZOMBO (Phase 0).
///
/// - Background arena fixed (cover, tanpa scroll).
/// - [PlayerComponent] di tengah, gerak via [joystick].
/// - Phase 1+: pedang, zombie, koin ditambahkan di sini.
class ZomboGame extends FlameGame {
  ZomboGame({required this.state});

  /// State terpusat (dibaca HUD overlay).
  final GameState state;

  /// Joystick virtual kiri bawah (Flame bawaan).
  late final JoystickComponent joystick;

  late final BackgroundComponent _background;
  late final PlayerComponent _player;

  @override
  Future<void> onLoad() async {
    // Background arena.
    final mapSprite = await loadSprite('map_arena.jpg');
    _background = BackgroundComponent(sprite: mapSprite);
    add(_background);

    // Player di tengah arena.
    _player = PlayerComponent()..position = size / 2;
    add(_player);

    // Joystick kiri bawah.
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
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _fitBackground();
  }

  void _fitBackground() {
    final spriteSize = Vector2(1024, 1024);
    _background.fitTo(size, spriteSize);
  }
}
