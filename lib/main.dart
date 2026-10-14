import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
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
  final game = ZomboGame(state: state);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: GameWidget(
          game: game,
          overlayBuilderMap: {
            'hud': (context, game) =>
                HudOverlay(state: (game as ZomboGame).state),
          },
          initialActiveOverlays: const ['hud'],
        ),
      ),
    ),
  );
}
