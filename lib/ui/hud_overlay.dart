import 'package:flutter/material.dart';

import '../core/game_state.dart';

/// HUD overlay (Flutter, di atas canvas Flame).
/// Phase 1: nilai real dari [GameState] + dialog game over + tombol restart.
/// [onRestart] dipanggil saat tombol MAIN LAGI ditekan.
class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.state,
    required this.onRestart,
  });

  final GameState state;
  final VoidCallback onRestart;

  String _formatTime(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
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
                      final mm = (seconds ~/ 60).toString().padLeft(2, '0');
                      final ss = (seconds % 60).toString().padLeft(2, '0');
                      return Text(
                        '$mm:$ss',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFeatures: [FontFeature.tabularFigures()],
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
              ],
            ),
            const SizedBox(height: 8),
            // Kill counter (kiri, baris kedua).
            Align(
              alignment: Alignment.centerLeft,
              child: _HudChip(
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
            ),
          ],
        ),
      ),
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
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: onRestart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                          ),
                          child: const Text(
                            'MAIN LAGI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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
