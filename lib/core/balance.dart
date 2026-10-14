/// Balance v1 — angka awal dari plan §4. Tuning di Phase 2.
/// Semua nilai terpusat di sini supaya tuning tidak ngubek-ubek komponen.
class Balance {
  Balance._();

  // --- Player ---
  static const double playerSpeed = 170;
  static const int playerMaxHp = 100;
  /// Detik kebal setelah kena hit (i-frames).
  static const double playerInvulnerableSeconds = 0.5;

  // --- Joystick ---
  /// Input di bawah nilai ini dianggap nol (anti drift).
  static const double joystickDeadzone = 0.15;

  // --- Pedang (orbit) ---
  /// [damage, radiusOrbit, kecepatanPutar (rad/s), hargaKoin] per tier (index 0 = tier 1).
  static const List<SwordTier> swordTiers = [
    SwordTier(damage: 10, orbitRadius: 70, spinSpeed: 3.5, cost: 0),
    SwordTier(damage: 22, orbitRadius: 95, spinSpeed: 3.5, cost: 30),
    SwordTier(damage: 45, orbitRadius: 125, spinSpeed: 4.0, cost: 80),
  ];

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
  static const double spawnIntervalStart = 1.2;
  static const double spawnIntervalMin = 0.25;
  /// Menit ke berapa spawn mencapai interval minimum.
  static const double spawnRampMinutes = 5;
  static const int maxAliveZombies = 150;

  // --- Koin ---
  static const double coinMagnetRadius = 40;
  static const double coinPickupRadius = 18;
  static const double coinMagnetSpeed = 320;
  static const double coinScatterSpeed = 60;

  // --- Combat (Phase 1) ---
  /// Cooldown hit per zombie agar satu sapuan tidak multi-hit tiap frame.
  static const double swordHitCooldown = 0.35;

  /// Setengah lebar sudut hit pedang (rad).
  static const double swordHitAngle = 0.5;

  /// Radius sentuh player (untuk damage zombie).
  static const double playerHitRadius = 28;
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
