import 'terrain.dart';

class BattleUnit {
  BattleUnit({
    required this.officerId,
    required this.name,
    required this.soldiers,
    required this.war,
    required this.intelligence,
    required this.row,
    required this.column,
  });
  final String officerId, name;
  final int war, intelligence;
  int row, column;
  int soldiers;
}

class BattleState {
  BattleState({
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
  }) : day = 1;
  final String targetProvinceId, attackerName, defenderName;
  int attackerSoldiers, defenderSoldiers, day;
  final List<BattleUnit> attackerUnits, defenderUnits;
  final String commanderName;
  final int commanderWar;
  final TerrainType terrain;
  bool finished = false;
  String? winner;
  bool get attackerWon => winner == 'attacker';
}
