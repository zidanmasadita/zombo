import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/audio_service.dart';
import '../core/balance.dart';
import '../core/best_score.dart';
import '../core/game_state.dart';
import 'components/coin_component.dart';
import 'components/floating_joystick_component.dart';
import 'components/fx_component.dart';
import 'components/ground_component.dart';
import 'components/player_component.dart';
import 'components/spawner_component.dart';
import 'components/sword_component.dart';
import 'components/zombie_component.dart';
import 'components/boss_component.dart';

/// Game utama ZOMBO (v2.1 scrolling world).
///
/// - Scrolling world: kamera ikut player, tanah infinite tiling (tanpa batas arena).
/// - [player] gerak via [joystick] floating (screen-space, di camera.viewport).
/// - [SwordComponent] orbit + hit; tier bisa di-upgrade mid-game.
/// - [SpawnerComponent] spawn zombie di luar layar; koin magnet + pickup.
/// - Juice: partikel burst, angka damage (pool), screen shake.
/// - Audio: SFX + BGM loop via [AudioService].
/// - Alur: menu -> run -> (pause) -> game over -> menu / run lagi.
/// - Game over -> best score disimpan, engine pause + dialog HUD;
///   [restart] reset bersih.
class ZomboGame extends FlameGame {
  ZomboGame({required this.state});

  /// State terpusat (dibaca HUD overlay).
  final GameState state;

  /// Joystick floating: muncul di titik jari menyentuh, bukan fixed kiri bawah.
  late final FloatingJoystickComponent joystick;

  /// Player (dipakai pedang/zombie/koin sebagai target).
  late final PlayerComponent player;

  /// Zombie yang hidup saat ini (termasuk boss — pedang iterate list ini).
  final zombies = <ZombieComponent>[];

  /// Boss yang aktif saat ini (null jika tidak ada). Juga ada di [zombies].
  BossComponent? boss;

  /// Jumlah boss yang sudah spawn dalam run ini.
  int _bossCount = 0;

  /// Run time (detik) saat boss berikutnya dijadwalkan spawn.
  double _nextBossAt = Balance.bossInterval;

  /// True jika banner peringatan boss sudah ditampilkan untuk jadwal ini.
  bool _bossWarningShown = false;

  /// Koin yang jatuh saat ini.
  final coins = <CoinComponent>[];

  late final SwordComponent _sword;
  late final SpawnerComponent _spawner;

  /// Burst partikel yang hidup saat ini (cap anti-stutter).
  int _liveBursts = 0;

  final _random = math.Random();

  /// Detik sejak run dimulai (jam game, berhenti saat game over).
  double runTime = 0;

  bool get isGameOver => state.isGameOver.value;

  /// Pool angka damage (di-reuse, tidak alokasi per hit).
  final _dmgNumbers = <DamageNumberComponent>[];
  int _dmgIndex = 0;

  /// Screen shake: sisa waktu + magnitudo (offset di atas posisi kamera ikut player).
  double _shakeTime = 0;
  double _shakeMag = 0;

  /// Interval spawn saat ini (2.0 dtk -> 0.7 dtk di menit ke-5).
  double get spawnInterval {
    final t = (runTime / (Balance.spawnRampMinutes * 60)).clamp(0.0, 1.0);
    return math.max(
      Balance.spawnIntervalMin,
      Balance.spawnIntervalStart -
          (Balance.spawnIntervalStart - Balance.spawnIntervalMin) * t,
    );
  }

  @override
  Future<void> onLoad() async {
    // Tanah infinite (scrolling world): tile seamless, di-render mengikuti kamera.
    final tileImage = await images.load('ground_tile.png');
    world.add(GroundComponent(tileImage: tileImage));

    // Player di origin dunia (tengah tak berhingga).
    player = PlayerComponent()..position = Vector2.zero();
    world.add(player);

    // Pedang orbit (tier 1 di Phase 1).
    final swordSprite = await loadSprite('sword_tier1.png');
    _sword = SwordComponent(sprite: swordSprite);
    world.add(_sword);

    // Spawner zombie.
    _spawner = SpawnerComponent();
    world.add(_spawner);

    // Pool angka damage (pre-add, di-reuse round-robin).
    for (var i = 0; i < Balance.damageNumberPoolSize; i++) {
      final n = DamageNumberComponent();
      _dmgNumbers.add(n);
      world.add(n);
    }

    // Joystick floating di screen-space (camera.viewport) agar tidak ikut
    // kegeser kamera — koordinat sentuh = koordinat layar.
    joystick = FloatingJoystickComponent();
    camera.viewport.add(joystick);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Kamera ikut player; screen shake sebagai offset acak di atasnya.
    var shake = Vector2.zero();
    if (_shakeTime > 0) {
      _shakeTime -= dt;
      final m = _shakeMag;
      shake = Vector2(
        (_random.nextDouble() * 2 - 1) * m,
        (_random.nextDouble() * 2 - 1) * m,
      );
    }
    camera.viewfinder.position = player.position + shake;
    if (isGameOver) return;
    runTime += dt;
    state.elapsedSeconds.value = runTime.floor();
    // Bersihkan zombie yang HP-nya habis (damage terjadi di SwordComponent).
    // Juga despawn zombie yang terlalu jauh: player (200 px/s) lebih cepat dari
    // semua zombie, jadi yang tertinggal jauh tidak akan terkejar — hapus agar
    // tidak menuhin cap 90 dan spawn baru tetap jalan.
    // Boss dikecualikan dari despawn dan punya death handler sendiri.
    for (final zombie in List.of(zombies)) {
      if (zombie.hp <= 0) {
        if (zombie is BossComponent) {
          _killBoss(zombie);
        } else {
          _killZombie(zombie);
        }
      } else if (zombie is! BossComponent &&
          (zombie.position - player.position).length >
              Balance.zombieDespawnDistance) {
        zombies.remove(zombie);
        zombie.removeFromParent();
      }
    }

    // Timer boss: peringatan 3 dtk sebelum spawn, spawn tiap bossInterval.
    // Kalau boss sebelumnya masih hidup, jadwal tertunda sampai boss mati.
    if (boss == null && runTime >= _nextBossAt - Balance.bossWarningTime) {
      if (!_bossWarningShown) {
        _bossWarningShown = true;
        state.bossWarningVisible.value = true;
        AudioService.playUpgrade();
      }
    }
    if (boss == null && runTime >= _nextBossAt) {
      _spawnBoss();
    }

    // Update fraksi HP boss untuk HP bar di HUD.
    final b = boss;
    if (b != null) {
      state.bossHpFrac.value =
          (b.hp / b.maxHp).clamp(0.0, 1.0).toDouble();
    }
  }

  /// Mulai run baru dari menu: reset bersih, engine jalan, BGM mulai.
  void startRun() {
    _clearEntities();
    runTime = 0;
    state.reset();
    state.isMenu.value = false;
    resumeEngine();
    AudioService.startBgm();
  }

  /// Kembali ke menu utama: reset bersih, engine berhenti.
  void toMenu() {
    _clearEntities();
    runTime = 0;
    state.reset();
    state.isMenu.value = true;
    pauseEngine();
  }

  /// Jeda run (dari tombol pause HUD). Spawner + update berhenti.
  void pauseGame() {
    if (state.isMenu.value || isGameOver || state.isPaused.value) return;
    state.isPaused.value = true;
    pauseEngine();
  }

  /// Lanjut run dari jeda.
  void resumeGame() {
    if (!state.isPaused.value) return;
    state.isPaused.value = false;
    resumeEngine();
  }

  void _clearEntities() {
    for (final zombie in List.of(zombies)) {
      zombie.removeFromParent();
    }
    zombies.clear();
    boss = null;
    _bossCount = 0;
    _nextBossAt = Balance.bossInterval;
    _bossWarningShown = false;
    for (final coin in List.of(coins)) {
      coin.removeFromParent();
    }
    coins.clear();
    // Burst partikel ikut dibersihkan (onDone-nya decrement _liveBursts).
    for (final burst in List.of(world.children.query<BurstComponent>())) {
      burst.removeFromParent();
    }
    _liveBursts = 0;
  }

  /// Pedang menghantam zombie: burst + angka damage + suara.
  void onSwordHit(Vector2 pos, int damage) {
    _spawnBurst(
      pos,
      [Colors.white, Colors.yellowAccent, Colors.orangeAccent],
      Balance.hitParticles,
      130,
    );
    spawnDamageNumber(pos + Vector2(0, -24), damage);
    AudioService.playSwing();
    AudioService.playHit();
  }

  /// Angka damage melayang (pool round-robin).
  void spawnDamageNumber(Vector2 pos, int damage) {
    if (_dmgNumbers.isEmpty) return;
    _dmgIndex = (_dmgIndex + 1) % _dmgNumbers.length;
    _dmgNumbers[_dmgIndex].spawn(pos, damage);
  }

  void _spawnBurst(
    Vector2 pos,
    List<Color> colors,
    int count,
    double speed, {
    double life = 0.4,
    double size = 3,
  }) {
    // Cap burst hidup (anti-stutter saat zombie banyak + hit cincin sering).
    if (_liveBursts >= Balance.maxLiveBursts) return;
    _liveBursts++;
    world.add(
      BurstComponent(
        position: pos,
        colors: colors,
        count: count,
        speed: speed,
        life: life,
        size: size,
        onDone: () {
          if (_liveBursts > 0) _liveBursts--;
        },
      ),
    );
  }

  /// Screen shake kecil (dipakai saat player kena hit).
  void addShake(double magnitude, double duration) {
    _shakeMag = magnitude;
    _shakeTime = duration;
  }

  /// Zombie mati: death burst + suara + drop koin, kills++.
  void _killZombie(ZombieComponent zombie) {
    zombies.remove(zombie);
    final pos = zombie.position.clone();
    zombie.removeFromParent();
    _spawnBurst(
      pos,
      [Colors.lightGreen, Colors.green, Colors.redAccent],
      Balance.deathParticles,
      170,
      life: 0.5,
      size: 4,
    );
    AudioService.playDeath();
    state.kills.value++;
    final coinCount = Balance.zombieStats[zombie.type]!.coins;
    for (var i = 0; i < coinCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final velocity = Vector2(math.cos(angle), math.sin(angle)) *
          Balance.coinScatterSpeed;
      final coin = CoinComponent(
        position: pos.clone(),
        velocity: velocity,
      );
      coins.add(coin);
      world.add(coin);
    }
  }

  /// Spawn boss: tiap bossInterval detik, maks 1 aktif dalam satu waktu.
  void _spawnBoss() {
    _bossCount++;
    _bossWarningShown = false;
    state.bossWarningVisible.value = false;
    _nextBossAt = runTime + Balance.bossInterval;
    final b = BossComponent(
      position: _edgePosition(),
      bossNumber: _bossCount,
    );
    boss = b;
    zombies.add(b);
    world.add(b);
    state.bossHpFrac.value = 1.0;
    addShake(6, 0.5);
    AudioService.playUpgrade();
  }

  /// Boss mati: burst besar + hujan koin + kills++.
  void _killBoss(BossComponent b) {
    zombies.remove(b);
    boss = null;
    final pos = b.position.clone();
    b.removeFromParent();
    _spawnBurst(
      pos,
      [Colors.red, Colors.orange, Colors.yellowAccent, Colors.white],
      Balance.deathParticles * 3,
      260,
      life: 0.8,
      size: 6,
    );
    AudioService.playDeath();
    state.kills.value++;
    state.bossHpFrac.value = -1;
    for (var i = 0; i < b.stats.coins; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final velocity = Vector2(math.cos(angle), math.sin(angle)) *
          Balance.coinScatterSpeed *
          1.5;
      final coin = CoinComponent(
        position: pos.clone(),
        velocity: velocity,
      );
      coins.add(coin);
      world.add(coin);
    }
  }

  /// Player kena hit zombie (i-frames ditangani PlayerComponent).
  /// Hanya yang benar-benar mengurangi HP yang memicu shake/suara/getar.
  void damagePlayer(int damage) {
    if (isGameOver) return;
    final before = state.hp.value;
    player.takeDamage(damage);
    if (state.hp.value < before) {
      addShake(Balance.shakeOnPlayerHit, Balance.shakeDuration);
      AudioService.playPlayerHit();
      if (state.isVibration.value) {
        unawaited(HapticFeedback.mediumImpact());
      }
    }
    if (state.hp.value <= 0) _gameOver();
  }

  void _gameOver() {
    // Best score dulu (sebelum isGameOver -> HUD rebuild dengan nilai final).
    final time = runTime.floor();
    final kills = state.kills.value;
    var newRecord = false;
    if (time > state.bestTime.value) {
      state.bestTime.value = time;
      newRecord = true;
    }
    if (kills > state.bestKills.value) {
      state.bestKills.value = kills;
      newRecord = true;
    }
    state.isNewRecord.value = newRecord;
    if (newRecord) unawaited(BestScoreStorage.save(state));
    state.isGameOver.value = true;
    AudioService.playGameOver();
    if (state.isVibration.value) {
      unawaited(HapticFeedback.heavyImpact());
    }
    pauseEngine();
  }

  /// Beli upgrade pedang ke tier [tier] (1 = Api, 2 = Petir).
  /// Return true jika berhasil (koin cukup + tier lebih tinggi dari aktif).
  /// Sprite + stats pedang langsung berubah via [SwordComponent].
  bool buySwordTier(int tier) {
    if (isGameOver ||
        tier <= state.swordTier.value ||
        tier >= Balance.swordTiers.length) {
      return false;
    }
    final cost = Balance.swordTiers[tier].cost;
    if (state.coins.value < cost) return false;
    state.coins.value -= cost;
    state.swordTier.value = tier;
    _spawnBurst(
      player.position.clone(),
      [Colors.amber, Colors.yellowAccent, Colors.white],
      Balance.upgradeParticles,
      160,
      life: 0.5,
      size: 4,
    );
    AudioService.playUpgrade();
    if (state.isVibration.value) {
      unawaited(HapticFeedback.selectionClick());
    }
    return true;
  }

  /// Restart bersih: hapus semua entitas, reset state, lanjut lagi.
  /// Dipakai dari dialog game over (MAIN LAGI) & pause menu (ULANGI).
  void restart() {
    _clearEntities();
    _liveBursts = 0;
    runTime = 0;
    state.reset();
    player.reset();
    _spawner.resetTimer();
    resumeEngine();
  }

  /// Spawn satu zombie di luar layar, mengelilingi viewport kamera
  /// (dipanggil SpawnerComponent). Zombie jalan ke arah player (AI kejar).
  void spawnZombie() {
    if (zombies.length >= Balance.maxAliveZombies) return;
    final zombie = ZombieComponent(
      type: _pickType(),
      position: _edgePosition(),
    );
    zombies.add(zombie);
    world.add(zombie);
  }

  /// Tipe zombie: Normal selalu ada; Cepat muncul >30 dtk, Tank >90 dtk.
  ZombieType _pickType() {
    final t = runTime;
    final fastWeight = t > 30 ? math.min(0.35, (t - 30) / 300) : 0.0;
    final tankWeight = t > 90 ? math.min(0.2, (t - 90) / 300) : 0.0;
    final roll = _random.nextDouble();
    if (roll < tankWeight) return ZombieType.tank;
    if (roll < tankWeight + fastWeight) return ZombieType.fast;
    return ZombieType.normal;
  }

  /// Posisi spawn: di luar layar, bias ke arah gerakan player.
  /// Kalau player jalan, zombie spawn di depan arah gerak (±90°) agar
  /// player menabrak mereka — bukan ketinggalan di belakang.
  /// Kalau player diam, acak ke segala arah (perilaku lama).
  Vector2 _edgePosition() {
    const margin = 80.0;
    final cam = camera.viewfinder.position;
    final w = size.x;
    final h = size.y;

    final moveDelta = joystick.delta;
    final moving = moveDelta.length > Balance.joystickDeadzone;

    double angle;
    if (moving) {
      final base = math.atan2(moveDelta.y, moveDelta.x);
      angle = base + (_random.nextDouble() - 0.5) * math.pi;
    } else {
      angle = _random.nextDouble() * math.pi * 2;
    }

    // Di luar layar: setengah diagonal + margin.
    final dist = math.sqrt(w * w + h * h) / 2 + margin;
    return cam + Vector2(math.cos(angle), math.sin(angle)) * dist;
  }

  /// Koin keambil player: sparkle + suara + counter naik.
  void collectCoin(CoinComponent coin) {
    coins.remove(coin);
    final pos = coin.position.clone();
    coin.removeFromParent();
    _spawnBurst(
      pos,
      [Colors.amber, Colors.yellowAccent, Colors.white],
      Balance.coinSparkleParticles,
      90,
      life: 0.3,
      size: 2.5,
    );
    AudioService.playCoin();
    state.coins.value++;
  }

}
