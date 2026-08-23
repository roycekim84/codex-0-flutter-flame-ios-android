import 'package:codex_strategy/core/game_engine.dart';
import 'package:codex_strategy/data/demo_scenario.dart';
import 'package:codex_strategy/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('automated battle capture fixture creates a playable battle', () {
    final engine = GameEngine(
      GameState.fromScenario(
        DemoScenario.create(),
        selectedForceId: 'force_green',
      ),
    );

    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_ash',
      targetProvinceId: 'p_ford',
      committedSoldiers: 600,
      participantOfficerIds: const ['officer_1', 'officer_5'],
      commanderOfficerId: 'officer_1',
    );

    expect(battle, isNotNull);
    expect(battle!.state.attackerUnits, isNotEmpty);
    expect(battle.state.defenderUnits, isNotEmpty);
    engine.dispose();
  });
}
