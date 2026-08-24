/// 전투 수식에서 조정 가능한 값을 모아 둔 기준표.
///
/// 데이터팩과 난이도별 밸런스를 조정할 때 BattleEngine의 로직을 건드리지
/// 않도록, 모든 전투 계수는 이 표를 통해 참조한다.
abstract final class BattleBalance {
  static const normalAttackRate = .14;
  static const fireAttackRate = .08;
  static const chargeAttackRate = .22;
  static const counterAttackRate = .10;
  static const unitRetaliationRate = .03;
  static const chargeSelfLossRate = .05;
  static const cooperateBonus = 1.35;

  static const fireMoraleLoss = 8;
  static const fireOngoingDamageRate = .03;
  static const fireOngoingMoraleLoss = 5;
  static const supplyShortageMoraleLoss = 12;
  static const supplyDesertionRate = .04;

  static const maxBattleDay = 8;
  static const maxSupplyShortageDays = 3;
}
