import 'battle_state.dart';
import 'terrain.dart';

enum BattleAction { attack, fire, charge, wait }

class BattleEngine {
  BattleEngine(this.state);
  final BattleState state;

  void attack() {
    if (state.finished) return;
    final commanderModifier =
        (0.12 + state.commanderWar / 1000) * state.terrain.attackModifier;
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

  void act({
    required String attackerId,
    required String defenderId,
    required BattleAction action,
  }) {
    if (state.finished) return;
    final attacker = state.attackerUnits
        .where((u) => u.officerId == attackerId)
        .firstOrNull;
    final defender = state.defenderUnits
        .where((u) => u.officerId == defenderId)
        .firstOrNull;
    if (attacker == null ||
        defender == null ||
        attacker.soldiers <= 0 ||
        defender.soldiers <= 0) {
      return;
    }
    final base = switch (action) {
      BattleAction.attack =>
        attacker.soldiers * .14 * state.terrain.attackModifier,
      BattleAction.fire =>
        attacker.soldiers *
            .08 *
            (attacker.intelligence / 70) *
            state.terrain.fireModifier,
      BattleAction.charge =>
        attacker.soldiers *
            .22 *
            (attacker.war / 70) *
            state.terrain.attackModifier,
      BattleAction.wait => 0,
    };
    final damage = base.round().clamp(0, defender.soldiers).toInt();
    defender.soldiers -= damage;
    if (action == BattleAction.charge) {
      attacker.soldiers =
          (attacker.soldiers - (attacker.soldiers * .05).round())
              .clamp(0, attacker.soldiers)
              .toInt();
    }
    if (action != BattleAction.wait) {
      attacker.soldiers =
          (attacker.soldiers - (defender.soldiers * .03).round())
              .clamp(0, attacker.soldiers)
              .toInt();
    }
    state.attackerSoldiers = state.attackerUnits.fold(
      0,
      (sum, u) => sum + u.soldiers,
    );
    state.defenderSoldiers = state.defenderUnits.fold(
      0,
      (sum, u) => sum + u.soldiers,
    );
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
