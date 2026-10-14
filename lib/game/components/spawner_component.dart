import 'package:flame/components.dart';

import '../zombo_game.dart';

/// Timer spawn zombie (logika spawn di [ZomboGame.spawnZombie]).
class SpawnerComponent extends Component with HasGameReference<ZomboGame> {
  double _timer = 0.5;

  void resetTimer() {
    _timer = 0.5;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;
    _timer -= dt;
    if (_timer <= 0) {
      _timer = game.spawnInterval;
      game.spawnZombie();
    }
  }
}
