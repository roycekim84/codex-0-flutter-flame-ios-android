import 'battle_state.dart';

class BattleEngine {
  BattleEngine(this.state);
  final BattleState state;

  void attack() {
    if (state.finished) return;
    final commanderModifier = 0.12 + state.commanderWar / 1000;
    final attackerDamage = (state.attackerSoldiers * commanderModifier)
        .round()
        .clamp(1, state.defenderSoldiers)
        .toInt();
    final defenderDamage = (state.defenderSoldiers * 0.10)
        .round()
        .clamp(1, state.attackerSoldiers)
        .toInt();
    state.defenderSoldiers -= attackerDamage;
    state.attackerSoldiers -= defenderDamage;
    state.day++;
    if (state.defenderSoldiers <= 0 ||
        state.attackerSoldiers <= 0 ||
        state.day > 8) {
      state.finished = true;
      state.winner = state.attackerSoldiers > state.defenderSoldiers
          ? 'attacker'
          : 'defender';
    }
  }

  void retreat() {
    if (state.finished) return;
    state.finished = true;
    state.winner = 'defender';
  }
}
