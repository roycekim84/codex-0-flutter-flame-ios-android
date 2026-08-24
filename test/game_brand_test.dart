import 'package:flutter_test/flutter_test.dart';
import 'package:codex_strategy/core/game_brand.dart';
import 'package:codex_strategy/core/asset_repository.dart';
import 'package:codex_strategy/data/korea_scenario.dart';
import 'package:codex_strategy/models/game_state.dart';

void main() {
  test('해동삼국기 브랜딩과 시나리오 ID가 공통 상수로 정의된다', () {
    expect(GameBrand.title, '해동삼국기');
    expect(GameBrand.subtitle, '삼국의 유산');
    expect(GameBrand.genericScenarioId, 'generic_prototype');
    expect(GameBrand.koreanScenarioId, 'scenario_korea_642');
  });

  test('한국 시나리오 데이터팩은 엔진 공용 형식과 한국 데이터를 사용한다', () {
    final scenario = KoreaScenario.create();
    expect(scenario['id'], GameBrand.koreanScenarioId);
    expect(scenario['year'], 642);
    expect(scenario['forces'], hasLength(3));
    expect(scenario['provinces'], hasLength(12));
    expect(scenario['officers'], hasLength(20));
    expect(
      (scenario['forces'] as List).map((force) => force['name']),
      containsAll(<String>['신라', '고구려', '백제']),
    );
    expect(
      (scenario['provinces'] as List).map((province) => province['name']),
      containsAll(<String>['금성', '평양', '사비', '김해']),
    );
    expect(
      (scenario['officers'] as List).first['historicalStatus'],
      'historical',
    );
    final officers = (scenario['officers'] as List).cast<Map>();
    expect(officers[0]['name'], '선덕여왕');
    expect(officers[6]['name'], '보장왕');
    expect(officers[12]['name'], '의자왕');

    final state = GameState.fromScenario(scenario);
    expect(state.forces.first.bannerAssetId, 'banner_silla');
    expect(state.forces.first.capitalProvinceId, 'p_ash');
    expect(state.officers.first.portraitAssetId, 'portrait_officer_1');
    expect(
      AssetRepository.officerPortrait('officer_1'),
      AssetRepository.portraitOfficer1,
    );
    expect(
      AssetRepository.officerPortrait('officer_7'),
      AssetRepository.portraitOfficer7,
    );
    expect(
      AssetRepository.officerPortrait('officer_13'),
      AssetRepository.portraitOfficer13,
    );
    expect(
      AssetRepository.officerPortrait('officer_3'),
      AssetRepository.portraitOfficer3,
    );
    expect(
      AssetRepository.officerPortrait('officer_8'),
      AssetRepository.portraitOfficer8,
    );
    expect(
      AssetRepository.officerPortrait('officer_14'),
      AssetRepository.portraitOfficer14,
    );
  });

  test('한국 세력 깃발은 독립 투명 PNG 자산으로 매핑된다', () {
    expect(
      AssetRepository.factionBanner('banner_silla'),
      AssetRepository.bannerSilla,
    );
    expect(
      AssetRepository.factionBanner('banner_goguryeo'),
      AssetRepository.bannerGoguryeo,
    );
    expect(
      AssetRepository.factionBanner('banner_baekje'),
      AssetRepository.bannerBaekje,
    );
    expect(
      AssetRepository.factionBanner(null),
      AssetRepository.forceBannerStrip,
    );
  });
}
