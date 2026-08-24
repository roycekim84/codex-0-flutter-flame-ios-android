import 'package:flutter_test/flutter_test.dart';
import 'package:codex_strategy/core/game_brand.dart';

void main() {
  test('해동삼국기 브랜딩과 시나리오 ID가 공통 상수로 정의된다', () {
    expect(GameBrand.title, '해동삼국기');
    expect(GameBrand.subtitle, '삼국의 유산');
    expect(GameBrand.genericScenarioId, 'generic_prototype');
    expect(GameBrand.koreanScenarioId, 'scenario_korea_642');
  });
}
