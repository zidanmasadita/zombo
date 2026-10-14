import 'package:flutter/material.dart';

import '../core/game_state.dart';

/// HUD overlay (Flutter, di atas canvas Flame).
/// Phase 0: skeleton — bar HP + koin + timer + kills, nilai dari [GameState].
/// Phase 1/2: nilai diisi game logic (HP berkurang, koin nambah, dst).
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
