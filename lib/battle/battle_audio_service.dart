import 'package:audioplayers/audioplayers.dart';

import 'battle_command.dart';

/// Best-effort battle audio. Web autoplay restrictions are intentionally
/// handled by ignoring playback failures until the first user gesture.
class BattleAudioService {
  BattleAudioService._();
  static final instance = BattleAudioService._();

  AudioPlayer? _music;
  bool _musicStarted = false;

  Future<void> startMusic() async {
    if (_musicStarted) return;
    _musicStarted = true;
    try {
      final player = AudioPlayer();
      _music = player;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(.18);
      await player.play(AssetSource('audio/battle_bgm.wav'));
    } catch (_) {
      // A browser may reject autoplay. The next action retries it.
      _musicStarted = false;
      await _music?.dispose();
      _music = null;
    }
  }

  Future<void> playAction(BattleCommandType type) async {
    await startMusic();
    final asset = switch (type) {
      BattleCommandType.attack => 'audio/battle_attack.wav',
      BattleCommandType.fire => 'audio/battle_fire.wav',
      BattleCommandType.charge => 'audio/battle_charge.wav',
      BattleCommandType.retreat => 'audio/battle_retreat.wav',
      _ => null,
    };
    if (asset == null) return;
    final player = AudioPlayer();
    try {
      await player.play(AssetSource(asset));
      await player.onPlayerComplete.first;
    } catch (_) {
      // Sound is non-critical and must never block a battle command.
    } finally {
      await player.dispose();
    }
  }

  Future<void> stop() async {
    _musicStarted = false;
    final player = _music;
    _music = null;
    await player?.stop();
    await player?.dispose();
  }
}
