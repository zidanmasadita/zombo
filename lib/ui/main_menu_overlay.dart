import 'package:flutter/material.dart';

import '../core/game_state.dart';

/// Menu utama: logo + tombol MAIN + best score + toggle suara/getar.
/// Tampil saat app dibuka (game ter-pause di belakang menu).
class MainMenuOverlay extends StatelessWidget {
  const MainMenuOverlay({
    super.key,
    required this.state,
    required this.onStart,
    required this.onToggleMute,
    required this.onToggleVibration,
  });

  final GameState state;
  final VoidCallback onStart;
  final ValueChanged<bool> onToggleMute;
  final ValueChanged<bool> onToggleVibration;

  String _formatTime(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1F0D), Color(0xFF050805)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/images/logo_zombo.png',
                width: MediaQuery.of(context).size.width * 0.85,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              const Text(
                'BERTAHANLAH SELAMA MUNGKIN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<int>(
                valueListenable: state.bestTime,
                builder: (context, bestTime, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: state.bestKills,
                    builder: (context, bestKills, _) {
                      if (bestTime == 0 && bestKills == 0) {
                        return const Text(
                          'Belum ada rekor — jadilah yang pertama!',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        );
                      }
                      return Text(
                        '🏆 TERBAIK: ${_formatTime(bestTime)} • $bestKills kills',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '▶ MAIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SettingRow(
                icon: Icons.volume_up,
                label: 'Suara',
                valueListenable: state.isMuted,
                // Switch ON = suara nyala (kebalikan dari isMuted).
                invert: true,
                onChanged: (on) => onToggleMute(!on),
              ),
              const SizedBox(height: 8),
              _SettingRow(
                icon: Icons.vibration,
                label: 'Getar',
                valueListenable: state.isVibration,
                onChanged: onToggleVibration,
              ),
              const Spacer(flex: 2),
              const Text(
                'ZOMBO v1',
                style: TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris setting: ikon + label + switch.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.valueListenable,
    required this.onChanged,
    this.invert = false,
  });

  final IconData icon;
  final String label;
  final ValueNotifier<bool> valueListenable;
  final ValueChanged<bool> onChanged;

  /// Jika true, switch menampilkan kebalikan nilai notifier
  /// (dipakai mute: notifier = isMuted, switch = suara nyala).
  final bool invert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: valueListenable,
            builder: (context, value, _) => Switch(
              value: invert ? !value : value,
              onChanged: onChanged,
              activeThumbColor: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}
