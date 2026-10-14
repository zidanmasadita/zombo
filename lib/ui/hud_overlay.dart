import 'package:flutter/material.dart';

import '../core/balance.dart';
import '../core/game_state.dart';
import 'main_menu_overlay.dart';
import 'pause_overlay.dart';

/// HUD overlay (Flutter, di atas canvas Flame).
///
/// - Di menu: [MainMenuOverlay] (logo + MAIN + best score + settings).
/// - Di run: HP bar + timer + koin + kills + tier pedang + tombol pause
///   + tombol upgrade + dialog jeda + dialog game over.
/// Semua callback diteruskan dari main.dart ke [ZomboGame]/settings.
class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.state,
    required this.onRestart,
    required this.onUpgrade,
    required this.onStartRun,
    required this.onToMenu,
    required this.onPause,
    required this.onResume,
    required this.onToggleMute,
    required this.onToggleVibration,
  });

  final GameState state;
  final VoidCallback onRestart;
  final bool Function(int tier) onUpgrade;
  final VoidCallback onStartRun;
  final VoidCallback onToMenu;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final ValueChanged<bool> onToggleMute;
  final ValueChanged<bool> onToggleVibration;

  String _formatTime(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: state.isMenu,
      builder: (context, inMenu, _) {
        if (inMenu) {
          return MainMenuOverlay(
            state: state,
            onStart: onStartRun,
            onToggleMute: onToggleMute,
            onToggleVibration: onToggleVibration,
          );
        }
        return Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HP bar (kiri atas).
                        Expanded(
                          child: ValueListenableBuilder<int>(
                            valueListenable: state.hp,
                            builder: (context, hp, _) => _HudChip(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    size: 16,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: (hp / 100).clamp(0, 1),
                                        minHeight: 10,
                                        backgroundColor: Colors.black45,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$hp',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Timer (tengah atas).
                        _HudChip(
                          child: ValueListenableBuilder<int>(
                            valueListenable: state.elapsedSeconds,
                            builder: (context, seconds, _) {
                              final mm = (seconds ~/ 60)
                                  .toString()
                                  .padLeft(2, '0');
                              final ss = (seconds % 60)
                                  .toString()
                                  .padLeft(2, '0');
                              return Text(
                                '$mm:$ss',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFeatures: [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Koin (kanan atas).
                        _HudChip(
                          child: ValueListenableBuilder<int>(
                            valueListenable: state.coins,
                            builder: (context, coins, _) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$coins',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Tombol pause (kanan atas, sentuhan diserap Flutter).
                        _HudChip(
                          child: InkWell(
                            onTap: onPause,
                            borderRadius: BorderRadius.circular(10),
                            child: const Icon(
                              Icons.pause,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Kill counter + tier pedang aktif (baris kedua).
                    Row(
                      children: [
                        _HudChip(
                          child: ValueListenableBuilder<int>(
                            valueListenable: state.kills,
                            builder: (context, kills, _) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.whatshot,
                                  size: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$kills kills',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _HudChip(
                          child: ValueListenableBuilder<int>(
                            valueListenable: state.swordTier,
                            builder: (context, tier, _) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _tierIcon(tier),
                                  size: 15,
                                  color: _tierColor(tier),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pedang ${Balance.swordTierNames[tier]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Tombol upgrade (bawah, selama run jalan).
                    // Sentuhan di sini diserap Flutter — tidak menggerakkan karakter.
                    ValueListenableBuilder<bool>(
                      valueListenable: state.isGameOver,
                      builder: (context, over, _) {
                        if (over) return const SizedBox.shrink();
                        return Row(
                          children: [
                            Expanded(
                              child: _UpgradeButton(
                                tier: 1,
                                state: state,
                                onUpgrade: onUpgrade,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _UpgradeButton(
                                tier: 2,
                                state: state,
                                onUpgrade: onUpgrade,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Dialog jeda (muncul saat pause, engine berhenti).
            ValueListenableBuilder<bool>(
              valueListenable: state.isPaused,
              builder: (context, paused, _) {
                if (!paused) return const SizedBox.shrink();
                return PauseOverlay(
                  state: state,
                  onResume: onResume,
                  onRestart: onRestart,
                  onToMenu: onToMenu,
                  onToggleMute: onToggleMute,
                  onToggleVibration: onToggleVibration,
                );
              },
            ),
            // Dialog game over (muncul saat HP habis, engine ter-pause).
            ValueListenableBuilder<bool>(
              valueListenable: state.isGameOver,
              builder: (context, over, _) {
                if (!over) return const SizedBox.shrink();
                return Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'GAME OVER',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                                letterSpacing: 2,
                              ),
                            ),
                            if (state.isNewRecord.value) ...[
                              const SizedBox(height: 8),
                              const Text(
                                '🏆 REKOR BARU!',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              'Waktu: ${_formatTime(state.elapsedSeconds.value)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kills: ${state.kills.value}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Koin: ${state.coins.value}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 12),
                            Text(
                              'TERBAIK: ${_formatTime(state.bestTime.value)} • '
                              '${state.bestKills.value} kills',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: onRestart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text(
                                      'MAIN LAGI',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: onToMenu,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white38,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text(
                                      'KE MENU',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Ikon per tier pedang (0 = Besi, 1 = Api, 2 = Petir).
IconData _tierIcon(int tier) {
  switch (tier) {
    case 1:
      return Icons.local_fire_department;
    case 2:
      return Icons.bolt;
    default:
      return Icons.construction;
  }
}

/// Warna aksen per tier pedang.
Color _tierColor(int tier) {
  switch (tier) {
    case 1:
      return Colors.deepOrangeAccent;
    case 2:
      return Colors.amber;
    default:
      return Colors.white70;
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: child,
    );
  }
}

/// Tombol upgrade satu tier pedang.
///
/// - Tier aktif: "AKTIF" (hijau, disable).
/// - Tier di bawah aktif (sudah terlewati): "TERPAKAI" (abu, disable).
/// - Tier di atas aktif: "BELI · N koin" — enable hanya jika koin cukup.
/// Harga & stats dari [Balance.swordTiers] (tidak hardcode di UI).
class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({
    required this.tier,
    required this.state,
    required this.onUpgrade,
  });

  final int tier;
  final GameState state;
  final bool Function(int tier) onUpgrade;

  @override
  Widget build(BuildContext context) {
    final tierData = Balance.swordTiers[tier];
    final name = Balance.swordTierNames[tier];
    return ValueListenableBuilder<int>(
      valueListenable: state.swordTier,
      builder: (context, currentTier, _) {
        return ValueListenableBuilder<int>(
          valueListenable: state.coins,
          builder: (context, coins, _) {
            final isActive = tier == currentTier;
            final isPassed = tier < currentTier;
            final canAfford = coins >= tierData.cost;
            final enabled = !isActive && !isPassed && canAfford;
            final label = isActive
                ? 'AKTIF'
                : isPassed
                    ? 'TERPAKAI'
                    : 'BELI · ${tierData.cost} koin';
            final bg = isActive
                ? Colors.green
                : enabled
                    ? _tierColor(tier)
                    : Colors.grey.shade800;
            return ElevatedButton(
              onPressed: enabled ? () => onUpgrade(tier) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_tierIcon(tier), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$name ${tier + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'DMG ${tierData.damage} · $label',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
