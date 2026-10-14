import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Partikel burst sekali pakai: meledak dari [position], jatuh + fade,
/// lalu auto-hapus (ParticleSystemComponent menghapus diri saat selesai).
/// [onDone] dipanggil saat dihapus (dipakai game untuk cap burst hidup).
class BurstComponent extends ParticleSystemComponent {
  BurstComponent({
    required super.position,
    required List<Color> colors,
    int count = 8,
    double speed = 140,
    double life = 0.4,
    double size = 3,
    this.onDone,
  }) : super(
          particle: _burstParticle(colors, count, speed, life, size),
        );

  final VoidCallback? onDone;

  @override
  void onRemove() {
    super.onRemove();
    onDone?.call();
  }

  /// Random bersama (bikin Random baru per burst = alokasi + seed jelek).
  static final _rand = math.Random();

  static Particle _burstParticle(
    List<Color> colors,
    int count,
    double speed,
    double life,
    double size,
  ) {
    final rand = _rand;
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
        // Paint dibuat SEKALI per partikel (bukan per frame) — sebelumnya
        // `Paint()` di dalam renderer = alokasi tiap partikel tiap frame.
        final paint = Paint()..color = color;
        return ComputedParticle(
          lifespan: myLife,
          renderer: (canvas, particle) {
            final elapsed = particle.progress * myLife;
            final pos =
                vel * elapsed + Vector2(0, 140) * elapsed * elapsed;
            final alpha = (1 - particle.progress).clamp(0.0, 1.0);
            paint.color = color.withValues(alpha: alpha);
            canvas.drawCircle(
              Offset(pos.x, pos.y),
              radius * (1 - particle.progress * 0.5),
              paint,
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
    // Style di-cache per kuanta alpha 0.1 (bukan rebuild TextPaint tiap frame).
    final q = ((_life / _totalLife) * 10).round().clamp(0, 10);
    if (q != _lastQuantized) {
      _lastQuantized = q;
      textRenderer = _style((_life / _totalLife).clamp(0.0, 1.0));
    }
  }

  int _lastQuantized = -1;

  /// Cache style per kuanta alpha (11 entri max).
  static final _styleCache = <int, TextPaint>{};

  static TextPaint _style(double alpha) {
    final q = (alpha * 10).round().clamp(0, 10);
    return _styleCache.putIfAbsent(
      q,
      () => TextPaint(
        style: TextStyle(
          color: Colors.white.withValues(alpha: q / 10),
          fontSize: 15,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1, 1)),
          ],
        ),
      ),
    );
  }
}
