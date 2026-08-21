import 'terrain.dart';

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
  bool get attackerWon => winner == 'attacker';
}
