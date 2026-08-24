/// Battle UI와 AI가 BattleEngine에 전달하는 명령의 종류.
enum BattleCommandType {
  selectAttacker,
  selectDefender,
  clearSelection,
  move,
  attack,
  fire,
  charge,
  cooperate,
  information,
  wait,
  endTurn,
  retreat,
}

class BattleCommand {
  const BattleCommand._({
    required this.type,
    this.attackerId,
    this.defenderId,
    this.row,
    this.column,
  });

  final BattleCommandType type;
  final String? attackerId;
  final String? defenderId;
  final int? row;
  final int? column;

  const BattleCommand.selectAttacker(String unitId)
    : this._(type: BattleCommandType.selectAttacker, attackerId: unitId);

  const BattleCommand.selectDefender(String unitId)
    : this._(type: BattleCommandType.selectDefender, defenderId: unitId);

  const BattleCommand.clearSelection()
    : this._(type: BattleCommandType.clearSelection);

  const BattleCommand.move({
    required String unitId,
    required int row,
    required int column,
  }) : this._(
         type: BattleCommandType.move,
         attackerId: unitId,
         row: row,
         column: column,
       );

  const BattleCommand.action({
    required BattleCommandType type,
    required String attackerId,
    String? defenderId,
  }) : this._(type: type, attackerId: attackerId, defenderId: defenderId);

  const BattleCommand.wait() : this._(type: BattleCommandType.wait);

  const BattleCommand.endTurn() : this._(type: BattleCommandType.endTurn);

  const BattleCommand.retreat() : this._(type: BattleCommandType.retreat);
}

/// 한 명령의 계산 결과. Flame은 이 결과를 재생하고, 수치를 계산하지 않는다.
class BattleResultEvent {
  const BattleResultEvent({
    required this.command,
    this.attackerId,
    this.defenderId,
    this.damage = 0,
    this.attackerSoldiersLost = 0,
    this.moraleDelta = 0,
    this.fireApplied = false,
    this.informationRevealed = false,
    this.finished = false,
    this.winner,
    this.logMessage = '',
  });

  final BattleCommand command;
  final String? attackerId;
  final String? defenderId;
  final int damage;
  final int attackerSoldiersLost;
  final int moraleDelta;
  final bool fireApplied;
  final bool informationRevealed;
  final bool finished;
  final String? winner;
  final String logMessage;

  bool get hasEffect =>
      damage > 0 ||
      attackerSoldiersLost > 0 ||
      moraleDelta != 0 ||
      fireApplied ||
      informationRevealed ||
      finished;
}

/// 화면/테스트에서 동일하게 쓰는 격자 좌표.
class BattleCell {
  const BattleCell(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is BattleCell && other.row == row && other.column == column;

  @override
  int get hashCode => Object.hash(row, column);
}
