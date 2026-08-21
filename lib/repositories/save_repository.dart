import 'dart:convert';

import '../models/game_state.dart';

/// Serialization boundary for AUTO/1..5 save slots.
class SaveRepository {
  String encode(GameState state) => jsonEncode({
    'saveVersion': 1,
    'scenarioId': state.scenarioId,
    'year': state.year,
    'month': state.month,
    'playerForceId': state.playerForceId,
    'randomSeed': state.randomSeed,
    'gameLog': state.gameLog,
  });

  Map<String, dynamic> decode(String value) =>
      jsonDecode(value) as Map<String, dynamic>;
}
