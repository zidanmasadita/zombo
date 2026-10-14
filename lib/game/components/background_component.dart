import 'dart:math' as math;

import 'package:flame/components.dart';

/// Background arena: gambar map menutupi seluruh viewport (cover).
/// Fixed arena v1 — tidak ada scroll/kamera bergerak.
class BackgroundComponent extends SpriteComponent {
  BackgroundComponent({required super.sprite}) : super(anchor: Anchor.center);

  /// Atur ukuran + posisi agar sprite menutupi [viewportSize] (cover).
  void fitTo(Vector2 viewportSize, Vector2 spriteSize) {
    final scale = math.max(
      viewportSize.x / spriteSize.x,
      viewportSize.y / spriteSize.y,
    );
    size = spriteSize * scale;
    position = viewportSize / 2;
  }
}
