import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'core/audio_service.dart';
import 'core/best_score.dart';
import 'core/game_state.dart';
import 'core/settings_storage.dart';
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
  // Best score + settings antar sesi dimuat sebelum UI tampil.
  await BestScoreStorage.loadInto(state);
  final settings = await SettingsStorage.load();
  state.isMuted.value = settings.muted;
  state.isVibration.value = settings.vibration;
  AudioService.setMuted(settings.muted);
  await AudioService.init();

  final game = ZomboGame(state: state);
  // App dibuka di menu utama (game ter-pause sampai MAIN ditekan).
  game.pauseEngine();
  state.isMenu.value = true;

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
                  onStartRun: game.startRun,
                  onToMenu: game.toMenu,
                  onPause: game.pauseGame,
                  onResume: game.resumeGame,
                  onToggleMute: (muted) {
                    state.isMuted.value = muted;
                    AudioService.setMuted(muted);
                    if (!muted) AudioService.startBgm();
                    unawaited(
                      SettingsStorage.save(
                        muted: muted,
                        vibration: state.isVibration.value,
                      ),
                    );
                  },
                  onToggleVibration: (on) {
                    state.isVibration.value = on;
                    unawaited(
                      SettingsStorage.save(
                        muted: state.isMuted.value,
                        vibration: on,
                      ),
                    );
                  },
                ),
          },
          initialActiveOverlays: const ['hud'],
        ),
      ),
    ),
  );
}
