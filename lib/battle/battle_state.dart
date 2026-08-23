import 'terrain.dart';
import 'battle_command.dart';

enum BattleOfficerResult { escaped, captured, dead }

class BattleOfficerOutcome {
  BattleOfficerOutcome({
    required this.officerId,
    required this.name,
    required this.result,
    required this.soldiers,
  });
  final String officerId, name;
  final BattleOfficerResult result;
  final int soldiers;
}

class BattleUnit {
  BattleUnit({
    required this.officerId,
    required this.name,
    required this.soldiers,
    required this.war,
    required this.intelligence,
    required this.row,
    required this.column,
    this.morale = 100,
  });
  final String officerId, name;
  final int war, intelligence;
  int row, column;
  int soldiers;
  int morale;
  bool burning = false;
}

class BattleState {
  BattleState({
    required this.sourceProvinceId,
    required this.targetProvinceId,
    required this.attackerName,
    required this.defenderName,
    required this.attackerSoldiers,
    required this.defenderSoldiers,
    this.attackerUnits = const [],
    this.defenderUnits = const [],
    this.commanderName = '',
    this.commanderWar = 50,
    this.terrain = TerrainType.plain,
    this.attackerFood = 0,
    this.dailySupplyCost = 50,
    this.attackerMorale = 100,
    this.defenderMorale = 100,
  }) : day = 1;
  final String sourceProvinceId, targetProvinceId, attackerName, defenderName;
  int attackerSoldiers, defenderSoldiers, day;
  final List<BattleUnit> attackerUnits, defenderUnits;
  final String commanderName;
  final int commanderWar;
  final TerrainType terrain;
  int attackerFood;
  final int dailySupplyCost;
  int attackerMorale;
  int defenderMorale;
  bool informationRevealed = false;
  int supplyShortageDays = 0;
  int returnedSoldiers = 0;
  String? returnProvinceId;
  final List<BattleOfficerOutcome> outcomes = [];
  bool finished = false;
  String? winner;
  String? selectedAttackerId;
  String? selectedDefenderId;
  bool get attackerWon => winner == 'attacker';

  BattleUnit? get selectedAttacker =>
      _unitById(attackerUnits, selectedAttackerId);
  BattleUnit? get selectedDefender =>
      _unitById(defenderUnits, selectedDefenderId);

  List<BattleCell> get movementCells {
    final unit = selectedAttacker;
    if (unit == null || finished || unit.soldiers <= 0) return const [];
    return _neighbors(unit).where((cell) => !_occupied(cell)).toList();
  }

  List<BattleCell> get attackCells {
    final unit = selectedAttacker;
    if (unit == null || finished || unit.soldiers <= 0) return const [];
    return _neighbors(unit)
        .where(
          (cell) => defenderUnits.any(
            (enemy) =>
                enemy.row == cell.row &&
                enemy.column == cell.column &&
                enemy.soldiers > 0,
          ),
        )
        .toList();
  }

  int? get expectedDamage {
    final attacker = selectedAttacker;
    final defender = selectedDefender;
    if (attacker == null || defender == null) return null;
    return (attacker.soldiers * .14 * terrain.attackModifier)
        .round()
        .clamp(0, defender.soldiers)
        .toInt();
  }

  BattleUnit? _unitById(List<BattleUnit> units, String? id) => id == null
      ? null
      : units.where((unit) => unit.officerId == id).firstOrNull;

  List<BattleCell> _neighbors(BattleUnit unit) =>
      [
            BattleCell(unit.row - 1, unit.column),
            BattleCell(unit.row + 1, unit.column),
            BattleCell(unit.row, unit.column - 1),
            BattleCell(unit.row, unit.column + 1),
          ]
          .where(
            (cell) =>
                cell.row >= 0 &&
                cell.row < 5 &&
                cell.column >= 0 &&
                cell.column < 6,
          )
          .toList();

  bool _occupied(BattleCell cell) => [...attackerUnits, ...defenderUnits].any(
    (unit) =>
        unit.soldiers > 0 && unit.row == cell.row && unit.column == cell.column,
  );
}
