import 'dart:math' as math;

import '../../core/balance.dart';
import 'zombie_component.dart';

/// Boss zombie: spawn tiap [Balance.bossInterval] detik run time.
///
/// - Sprite: `boss.png` (zombie king bermahkota).
/// - HP & damage di-scale per boss ke-n:
///   HP = bossBaseHp * bossHpScale^(n-1), damage = bossBaseDamage + (n-1)*bonus.
/// - Tidak ikut cap 90 zombie biasa dan tidak di-despawn jarak jauh.
/// - Mati -> ditangani [ZomboGame] (hujan koin, kills++).
class BossComponent extends ZombieComponent {
  BossComponent({required super.position, required this.bossNumber})
      : super(type: ZombieType.boss) {
    hp = maxHp;
  }

  /// Boss ke berapa dalam run ini (1 = pertama).
  final int bossNumber;

  late final ZombieStats _scaled = ZombieStats(
    hp: (Balance.bossBaseHp * math.pow(Balance.bossHpScale, bossNumber - 1))
        .round(),
    speed: Balance.zombieStats[ZombieType.boss]!.speed,
    touchDamage:
        Balance.bossBaseDamage + (bossNumber - 1) * Balance.bossDamageBonus,
    coins: Balance.bossBaseCoins,
  );

  @override
  ZombieStats get stats => _scaled;

  @override
  int get maxHp => _scaled.hp;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('boss.png');
  }
}
