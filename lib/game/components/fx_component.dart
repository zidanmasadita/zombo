import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Partikel burst sekali pakai: meledak dari [position], jatuh + fade,
/// lalu auto-hapus (ParticleSystemComponent menghapus diri saat selesai).
class BurstComponent extends ParticleSystemComponent {
  BurstComponent({
    required super.position,
    required List<Color> colors,
    int count = 8,
    double speed = 140,
    double life = 0.4,
    double size = 3,
  }) : super(
          particle: _burstParticle(colors, count, speed, life, size),
        );

  static Particle _burstParticle(
    List<Color> colors,
    int count,
    double speed,
    double life,
    double size,
  ) {
    final rand = math.Random();
    return Particle.generate(
      count: count,
      generator: (_) {
        final angle = rand.nextDouble() * math.pi * 2;
        final vel = Vector2(math.cos(angle), math.sin(angle)) *
            speed *
            (0.4 + rand.nextDouble() * 0.9);
        final color = colors[rand.nextInt(colors.length)];
        final radius = size * (0.6 + rand.nextDouble() * 0.9);
        final myLife = life * (0.7 + rand.nextDouble() * 0.6);
        return ComputedParticle(
          lifespan: myLife,
          renderer: (canvas, particle) {
            final elapsed = particle.progress * myLife;
            final pos =
                vel * elapsed + Vector2(0, 140) * elapsed * elapsed;
            final alpha = (1 - particle.progress).clamp(0.0, 1.0);
            canvas.drawCircle(
              Offset(pos.x, pos.y),
              radius * (1 - particle.progress * 0.5),
              Paint()..color = color.withValues(alpha: alpha),
            );
          },
        );
      },
    );
  }
}

/// Angka damage melayang (pool, di-reuse — tidak bikin objek baru tiap hit).
/// Dipakai via [spawn]: muncul di posisi, naik + fade 0.6 dtk, lalu kosong.
class DamageNumberComponent extends TextComponent {
  DamageNumberComponent() : super(anchor: Anchor.center);

  static const _totalLife = 0.6;
  double _life = 0;

  bool get isActive => _life > 0;

  void spawn(Vector2 pos, int damage) {
    position = pos.clone();
    text = '$damage';
    _life = _totalLife;
    textRenderer = _style(1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_life <= 0) return;
    _life -= dt;
    if (_life <= 0) {
      text = '';
      return;
    }
    position.y -= 46 * dt;
    textRenderer = _style((_life / _totalLife).clamp(0.0, 1.0));
  }

  static TextPaint _style(double alpha) => TextPaint(
        style: TextStyle(
          color: Colors.white.withValues(alpha: alpha),
          fontSize: 15,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1, 1)),
          ],
        ),
      );
}
