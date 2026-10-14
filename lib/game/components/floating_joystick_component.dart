import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../zombo_game.dart';

/// Joystick floating: muncul di titik jari menyentuh (di mana saja di area
/// game), knob mengikuti drag, hilang saat jari diangkat.
///
/// - Komponen ini menangkap drag di seluruh layar game (size = viewport).
/// - Sentuhan di tombol overlay Flutter tidak sampai ke sini (overlay di atas
///   GameWidget menyerap sentuhan) — tombol upgrade tidak menggerakkan karakter.
/// - [delta] ternormalisasi -1..1 per sumbu; nol saat tidak disentuh.
/// - Hanya satu jari yang dilacak ([_activePointerId]); jari kedua diabaikan.
class FloatingJoystickComponent extends PositionComponent
    with DragCallbacks, HasGameReference<ZomboGame> {
  /// Jarak maksimum knob dari titik awal sentuh (juga radius visual base).
  static const double maxRadius = 60;

  static const double _knobRadius = 28;

  int? _activePointerId;
  final Vector2 _delta = Vector2.zero();
  Vector2 _basePos = Vector2.zero();
  Vector2 _knobPos = Vector2.zero();

  final _basePaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
  final _knobPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);

  /// Arah gerak ternormalisasi (-1..1 per sumbu). Nol saat tidak disentuh.
  Vector2 get delta => _delta;

  bool get _active => _activePointerId != null;

  @override
  Future<void> onLoad() async {
    size = game.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (game.isGameOver || _activePointerId != null) return;
    final p = event.localPosition;
    // localPosition bisa NaN kalau jari di luar komponen (jarang, tapi jaga).
    if (p.x.isNaN || p.y.isNaN) return;
    _activePointerId = event.pointerId;
    // Base di-clamp agar lingkaran tetap terlihat penuh di dalam layar.
    _basePos = Vector2(
      p.x.clamp(maxRadius, game.size.x - maxRadius),
      p.y.clamp(maxRadius, game.size.y - maxRadius),
    );
    _knobPos = _basePos.clone();
    _delta.setZero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (event.pointerId != _activePointerId) return;
    // DragUpdateEvent tidak punya posisi absolut — akumulasi delta gerak.
    final d = event.localDelta;
    if (d.x.isNaN || d.y.isNaN) return;
    _knobPos += d;
    final offset = _knobPos - _basePos;
    final len = offset.length;
    final clamped = len > maxRadius ? offset.normalized() * maxRadius : offset;
    _knobPos = _basePos + clamped;
    _delta.setFrom(clamped / maxRadius);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (event.pointerId != _activePointerId) return;
    _reset();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    // Default DragCallbacks mengubah cancel jadi onDragEnd (cek pointerId di sana).
    super.onDragCancel(event);
  }

  void _reset() {
    _activePointerId = null;
    _delta.setZero();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_active) return;
    canvas.drawCircle(_basePos.toOffset(), maxRadius, _basePaint);
    canvas.drawCircle(_knobPos.toOffset(), _knobRadius, _knobPaint);
  }
}
