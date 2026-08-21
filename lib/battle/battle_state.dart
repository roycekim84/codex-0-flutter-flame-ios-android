class BattleState {
  BattleState({
    required this.targetProvinceId,
    required this.attackerName,
    required this.defenderName,
    required this.attackerSoldiers,
    required this.defenderSoldiers,
  }) : day = 1;
  final String targetProvinceId, attackerName, defenderName;
  int attackerSoldiers, defenderSoldiers, day;
  bool finished = false;
  String? winner;
  bool get attackerWon => winner == 'attacker';
}
