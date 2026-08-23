import 'battle_state.dart';
import 'battle_command.dart';
import 'terrain.dart';

enum BattleAction { attack, fire, charge, cooperate, information, wait }

class BattleEngine {
  BattleEngine(this.state);
  final BattleState state;

  BattleResultEvent execute(BattleCommand command) {
    switch (command.type) {
      case BattleCommandType.selectAttacker:
        if (!state.attackerUnits.any(
          (unit) => unit.officerId == command.attackerId,
        )) {
          return BattleResultEvent(
            command: command,
            logMessage: '선택할 수 없는 공격 부대입니다.',
          );
        }
        state.selectedAttackerId = command.attackerId;
        state.selectedDefenderId = null;
        return BattleResultEvent(command: command);
      case BattleCommandType.selectDefender:
        if (!state.defenderUnits.any(
          (unit) => unit.officerId == command.defenderId,
        )) {
          return BattleResultEvent(
            command: command,
            logMessage: '선택할 수 없는 방어 부대입니다.',
          );
        }
        state.selectedDefenderId = command.defenderId;
        return BattleResultEvent(command: command);
      case BattleCommandType.clearSelection:
        state.selectedAttackerId = null;
        state.selectedDefenderId = null;
        return BattleResultEvent(command: command);
      case BattleCommandType.move:
        final moved =
            command.attackerId != null &&
            command.row != null &&
            command.column != null &&
            moveUnit(command.attackerId!, command.row!, command.column!);
        return BattleResultEvent(
          command: command,
          attackerId: command.attackerId,
          logMessage: moved ? '부대가 이동했습니다.' : '이동할 수 없는 칸입니다.',
        );
      case BattleCommandType.attack:
      case BattleCommandType.fire:
      case BattleCommandType.charge:
      case BattleCommandType.cooperate:
      case BattleCommandType.information:
      case BattleCommandType.wait:
        final attackerId = command.attackerId ?? state.selectedAttackerId;
        final defenderId = command.defenderId ?? state.selectedDefenderId;
        if (attackerId == null || defenderId == null) {
          return BattleResultEvent(
            command: command,
            logMessage: '대상을 선택해야 합니다.',
          );
        }
        return act(
          attackerId: attackerId,
          defenderId: defenderId,
          action: _actionFor(command.type),
          command: command,
        );
      case BattleCommandType.retreat:
        return retreat(command: command);
    }
  }

  BattleAction _actionFor(BattleCommandType type) => switch (type) {
    BattleCommandType.attack => BattleAction.attack,
    BattleCommandType.fire => BattleAction.fire,
    BattleCommandType.charge => BattleAction.charge,
    BattleCommandType.cooperate => BattleAction.cooperate,
    BattleCommandType.information => BattleAction.information,
    BattleCommandType.wait => BattleAction.wait,
    _ => BattleAction.wait,
  };

  BattleResultEvent attack() {
    if (state.finished) {
      return BattleResultEvent(
        command: const BattleCommand.action(
          type: BattleCommandType.attack,
          attackerId: '',
          defenderId: '',
        ),
        finished: true,
        winner: state.winner,
      );
    }
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
    _syncUnits(state.attackerUnits, state.attackerSoldiers);
    _syncUnits(state.defenderUnits, state.defenderSoldiers);
    _advanceDay();
    return BattleResultEvent(
      command: const BattleCommand.action(
        type: BattleCommandType.attack,
        attackerId: '',
        defenderId: '',
      ),
      damage: attackerDamage,
      attackerSoldiersLost: defenderDamage,
      finished: state.finished,
      winner: state.winner,
      logMessage: '공격이 실행되었습니다.',
    );
  }

  BattleResultEvent act({
    required String attackerId,
    required String defenderId,
    required BattleAction action,
    BattleCommand? command,
  }) {
    final eventCommand =
        command ??
        BattleCommand.action(
          type: _commandTypeFor(action),
          attackerId: attackerId,
          defenderId: defenderId,
        );
    if (state.finished) {
      return BattleResultEvent(
        command: eventCommand,
        finished: true,
        winner: state.winner,
      );
    }
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
      return BattleResultEvent(
        command: eventCommand,
        logMessage: '유효하지 않은 부대입니다.',
      );
    }
    final attackerBefore = attacker.soldiers;
    final defenderMoraleBefore = state.defenderMorale;
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
      BattleAction.cooperate =>
        attacker.soldiers *
            .14 *
            state.terrain.attackModifier *
            (_hasAdjacentSupport(attacker, defender) ? 1.35 : 1.0),
      BattleAction.information => 0,
      BattleAction.wait => 0,
    };
    final damage = base.round().clamp(0, defender.soldiers).toInt();
    defender.soldiers -= damage;
    if (action == BattleAction.fire) {
      defender.burning = true;
      state.defenderMorale = (state.defenderMorale - 8).clamp(0, 100);
    }
    if (action == BattleAction.information) {
      state.informationRevealed = true;
    }
    if (action == BattleAction.charge) {
      attacker.soldiers =
          (attacker.soldiers - (attacker.soldiers * .05).round())
              .clamp(0, attacker.soldiers)
              .toInt();
    }
    if (action != BattleAction.wait && action != BattleAction.information) {
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
    _advanceDay();
    return BattleResultEvent(
      command: eventCommand,
      attackerId: attackerId,
      defenderId: defenderId,
      damage: damage,
      attackerSoldiersLost: attackerBefore - attacker.soldiers,
      moraleDelta: state.defenderMorale - defenderMoraleBefore,
      fireApplied: action == BattleAction.fire,
      informationRevealed: action == BattleAction.information,
      finished: state.finished,
      winner: state.winner,
      logMessage: _logFor(action, damage),
    );
  }

  BattleCommandType _commandTypeFor(BattleAction action) => switch (action) {
    BattleAction.attack => BattleCommandType.attack,
    BattleAction.fire => BattleCommandType.fire,
    BattleAction.charge => BattleCommandType.charge,
    BattleAction.cooperate => BattleCommandType.cooperate,
    BattleAction.information => BattleCommandType.information,
    BattleAction.wait => BattleCommandType.wait,
  };

  String _logFor(BattleAction action, int damage) =>
      '${action.name} 실행 · 피해 $damage';

  bool moveUnit(String unitId, int row, int column) {
    if (state.finished || row < 0 || row > 4 || column < 0 || column > 5) {
      return false;
    }
    final unit = state.attackerUnits
        .where((u) => u.officerId == unitId)
        .firstOrNull;
    if (unit == null ||
        (unit.row - row).abs() + (unit.column - column).abs() != 1) {
      return false;
    }
    final occupied = [...state.attackerUnits, ...state.defenderUnits].any(
      (u) => u != unit && u.row == row && u.column == column && u.soldiers > 0,
    );
    if (occupied) return false;
    unit.row = row;
    unit.column = column;
    state.selectedAttackerId = unitId;
    _advanceDay();
    return true;
  }

  void _syncUnits(List<BattleUnit> units, int total) {
    if (units.isEmpty) return;
    final before = units.fold(0, (sum, unit) => sum + unit.soldiers);
    if (before <= 0) return;
    var remaining = total;
    for (var i = 0; i < units.length; i++) {
      final soldiers = i == units.length - 1
          ? remaining
          : (units[i].soldiers * total / before).round();
      units[i].soldiers = soldiers.clamp(0, remaining).toInt();
      remaining -= units[i].soldiers;
    }
  }

  void _advanceDay() {
    state.day++;
    for (final unit in state.defenderUnits.where((u) => u.burning)) {
      final fireDamage = (unit.soldiers * .03).round().clamp(1, unit.soldiers);
      unit.soldiers -= fireDamage;
      unit.morale = (unit.morale - 5).clamp(0, 100);
    }
    state.defenderSoldiers = state.defenderUnits.fold(
      0,
      (sum, unit) => sum + unit.soldiers,
    );
    if (state.attackerFood >= state.dailySupplyCost) {
      state.attackerFood -= state.dailySupplyCost;
      state.supplyShortageDays = 0;
    } else {
      state.attackerFood = 0;
      state.supplyShortageDays++;
      state.attackerMorale = (state.attackerMorale - 12).clamp(0, 100);
      final desertion = (state.attackerSoldiers * .04).round().clamp(
        1,
        state.attackerSoldiers,
      );
      state.attackerSoldiers -= desertion;
      _syncUnits(state.attackerUnits, state.attackerSoldiers);
    }
    if (state.defenderSoldiers <= 0 ||
        state.attackerSoldiers <= 0 ||
        state.day > 8 ||
        state.supplyShortageDays >= 3) {
      state.finished = true;
      state.winner = state.attackerSoldiers > state.defenderSoldiers
          ? 'attacker'
          : 'defender';
    }
  }

  bool _hasAdjacentSupport(BattleUnit attacker, BattleUnit defender) =>
      state.attackerUnits.any(
        (unit) =>
            unit != attacker &&
            unit.soldiers > 0 &&
            (unit.row - defender.row).abs() +
                    (unit.column - defender.column).abs() <=
                1,
      );

  BattleResultEvent retreat({BattleCommand? command}) {
    final eventCommand = command ?? const BattleCommand.retreat();
    if (state.finished) {
      return BattleResultEvent(
        command: eventCommand,
        finished: true,
        winner: state.winner,
      );
    }
    state.finished = true;
    state.winner = 'defender';
    return BattleResultEvent(
      command: eventCommand,
      finished: true,
      winner: state.winner,
      logMessage: '공격군이 퇴각했습니다.',
    );
  }
}
