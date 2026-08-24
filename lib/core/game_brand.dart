/// Shared branding and scenario identifiers.
///
/// These values live outside individual screens so the visual theme can change
/// without changing GameEngine, BattleEngine, or save data semantics.
abstract final class GameBrand {
  static const title = '해동삼국기';
  static const subtitle = '삼국의 유산';
  static const englishSubtitle = 'LEGACY OF THE THREE KINGDOMS';
  static const titlePeriodLabel = '서기 642년 · 삼국의 유산';

  static const genericScenarioId = 'generic_prototype';
  static const koreanScenarioId = 'scenario_korea_642';

  static const ink = 0xff171612;
  static const panel = 0xff29241b;
  static const bronze = 0xff9a7138;
  static const gold = 0xfff0d59a;
  static const mutedGold = 0xffb29a71;
}
