import 'dart:ui';

import 'package:flame/components.dart';

import '../zombo_game.dart';

/// Tanah infinite (scrolling world v2.1): tile seamless digambar berulang
/// hanya untuk area yang terlihat kamera.
///
/// Satu component + satu drawImage per tile terlihat (tanpa alokasi per
/// frame). Prioritas render paling belakang.
class GroundComponent extends Component with HasGameReference<ZomboGame> {
  GroundComponent({required this.tileImage, this.tileSize = 512});

  /// Gambar tile seamless (dari `images.load`, bukan Sprite — digambar mentah).
  final Image tileImage;

  /// Ukuran tile di world (px). Harus sama dengan ukuran file tile.
  final double tileSize;

  final _paint = Paint();

  @override
  Future<void> onLoad() async {
    priority = -100;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Area dunia yang terlihat kamera saat ini.
    final cam = game.camera.viewfinder.position;
    final view = game.size;
    final left = cam.x - view.x / 2;
    final top = cam.y - view.y / 2;
    final tx0 = (left / tileSize).floor();
    final ty0 = (top / tileSize).floor();
    final tx1 = ((left + view.x) / tileSize).ceil();
    final ty1 = ((top + view.y) / tileSize).ceil();
    for (var ty = ty0; ty <= ty1; ty++) {
      for (var tx = tx0; tx <= tx1; tx++) {
        canvas.drawImage(
          tileImage,
          Offset(tx * tileSize, ty * tileSize),
          _paint,
        );
      }
    }
  }
}
