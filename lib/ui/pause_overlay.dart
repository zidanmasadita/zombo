import 'package:flutter/material.dart';

import '../core/game_state.dart';

/// Menu jeda: Lanjut / Ulangi / Ke Menu + toggle suara/getar.
/// Muncul di atas game yang ter-pause (engine berhenti).
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.state,
    required this.onResume,
    required this.onRestart,
    required this.onToMenu,
    required this.onToggleMute,
    required this.onToggleVibration,
  });

  final GameState state;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onToMenu;
  final ValueChanged<bool> onToggleMute;
  final ValueChanged<bool> onToggleVibration;

  @override
  Widget build(BuildContext context) {
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
                  'JEDA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onResume,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '▶ LANJUT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onRestart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '↻ ULANGI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onToMenu,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '⌂ KE MENU',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                _PauseSettingRow(
                  icon: Icons.volume_up,
                  label: 'Suara',
                  valueListenable: state.isMuted,
                  invert: true,
                  onChanged: (on) => onToggleMute(!on),
                ),
                _PauseSettingRow(
                  icon: Icons.vibration,
                  label: 'Getar',
                  valueListenable: state.isVibration,
                  onChanged: onToggleVibration,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseSettingRow extends StatelessWidget {
  const _PauseSettingRow({
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
  final bool invert;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
