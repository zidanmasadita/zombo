/// Balance v1 — angka awal dari plan §4. Tuning di Phase 2.
/// Semua nilai terpusat di sini supaya tuning tidak ngubek-ubek komponen.
class Balance {
  Balance._();

  // --- Player ---
  /// Dinaikkan 2026-10-14 (170 -> 200): menghindar harus terasa responsif.
  static const double playerSpeed = 200;
  static const int playerMaxHp = 100;
  /// Detik kebal setelah kena hit (i-frames).
  static const double playerInvulnerableSeconds = 0.5;

  // --- Joystick ---
  /// Input di bawah nilai ini dianggap nol (anti drift).
  static const double joystickDeadzone = 0.15;

  // --- Pedang (orbit) ---
  /// [damage, radiusOrbit, kecepatanPutar (rad/s), hargaKoin] per tier (index 0 = tier 1).
  /// REVERT 2026-10-15: kembali ke pedang orbit (bukan mesin potong rumput).
  static const List<SwordTier> swordTiers = [
    SwordTier(damage: 10, orbitRadius: 70, spinSpeed: 5.0, cost: 0),
    SwordTier(damage: 22, orbitRadius: 95, spinSpeed: 5.4, cost: 30),
    SwordTier(damage: 45, orbitRadius: 125, spinSpeed: 6.0, cost: 80),
  ];

  /// Nama tier pedang (index sama dengan [swordTiers]).
  static const List<String> swordTierNames = ['Besi', 'Api', 'Petir'];

  // --- Zombie ---
  static const Map<ZombieType, ZombieStats> zombieStats = {
    ZombieType.normal:
        ZombieStats(hp: 30, speed: 55, touchDamage: 10, coins: 1),
    ZombieType.fast:
        ZombieStats(hp: 20, speed: 95, touchDamage: 8, coins: 1),
    ZombieType.tank:
        ZombieStats(hp: 160, speed: 32, touchDamage: 25, coins: 5),
  };

  // --- Spawn ---
  /// Dikurangi 2026-10-14 (feedback user: kebanyakan): interval lebih renggang, cap lebih rendah.
  static const double spawnIntervalStart = 2.0;
  static const double spawnIntervalMin = 0.7;
  /// Menit ke berapa spawn mencapai interval minimum.
  static const double spawnRampMinutes = 5;
  static const int maxAliveZombies = 90;

  // --- Koin ---
  /// Jarak koin mulai ketarik ke player.
  static const double coinMagnetRadius = 110;
  static const double coinPickupRadius = 18;
  /// Percepatan koin saat ketarik magnet (makin dekat makin kencang).
  static const double coinMagnetPull = 1600;
  /// Kecepatan maksimum koin saat ketarik magnet.
  static const double coinMagnetMaxSpeed = 650;
  static const double coinScatterSpeed = 60;

  // --- Combat (Phase 1) ---
  /// Cooldown hit per zombie agar satu sapuan tidak multi-hit tiap frame.
  static const double swordHitCooldown = 0.35;

  /// Setengah lebar sudut hit pedang (rad).
  static const double swordHitAngle = 0.5;

  /// Radius sentuh player (untuk damage zombie).
  static const double playerHitRadius = 28;

  // --- Juice (Phase 3) ---
  /// Jumlah partikel per burst: kena hit / zombie mati / koin / upgrade.
  static const int hitParticles = 6;
  static const int deathParticles = 14;
  static const int coinSparkleParticles = 6;
  static const int upgradeParticles = 16;

  /// Cap burst partikel yang hidup bersamaan (anti-stutter saat zombie banyak).
  static const int maxLiveBursts = 24;

  /// Screen shake saat player kena hit (px) + durasinya (detik).
  static const double shakeOnPlayerHit = 8;
  static const double shakeDuration = 0.25;

  /// Ukuran pool angka damage (di-reuse, tidak alokasi per hit).
  static const int damageNumberPoolSize = 12;
}

class SwordTier {
  final int damage;
  final double orbitRadius;
  final double spinSpeed;
  final int cost;

  const SwordTier({
    required this.damage,
    required this.orbitRadius,
    required this.spinSpeed,
    required this.cost,
  });
}

enum ZombieType { normal, fast, tank }

class ZombieStats {
  final int hp;
  final double speed;
  final int touchDamage;
  final int coins;

  const ZombieStats({
    required this.hp,
    required this.speed,
    required this.touchDamage,
    required this.coins,
  });
}
