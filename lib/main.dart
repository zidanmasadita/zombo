import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'core/best_score.dart';
import 'core/game_state.dart';
import 'game/zombo_game.dart';
import 'ui/hud_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only (game dirancang untuk HP portrait).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final state = GameState();
  // Best score antar sesi dimuat sebelum UI tampil.
  await BestScoreStorage.loadInto(state);
  final game = ZomboGame(state: state);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: GameWidget(
          game: game,
          overlayBuilderMap: {
            'hud': (context, _) => HudOverlay(
                  state: game.state,
                  onRestart: game.restart,
                  onUpgrade: game.buySwordTier,
                ),
          },
          initialActiveOverlays: const ['hud'],
        ),
      ),
    ),
  );
}
