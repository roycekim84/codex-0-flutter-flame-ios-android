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
    expect(scenario['officers'], hasLength(24));
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
    expect(state.officers.first.historicalName, '선덕여왕');
    expect(state.officers.first.role, '신라 군주');
    expect(state.officers[20].historicalName, '김법민');
    expect(state.officers[20].sourceNote, contains('문무왕'));
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
    expect(
      AssetRepository.officerPortrait('officer_2'),
      AssetRepository.portraitOfficer2,
    );
    expect(
      AssetRepository.officerPortrait('officer_9'),
      AssetRepository.portraitOfficer9,
    );
    expect(
      AssetRepository.officerPortrait('officer_15'),
      AssetRepository.portraitOfficer15,
    );
    expect(
      AssetRepository.officerPortrait('officer_4'),
      AssetRepository.portraitOfficer4,
    );
    expect(
      AssetRepository.officerPortrait('officer_10'),
      AssetRepository.portraitOfficer10,
    );
    expect(
      AssetRepository.officerPortrait('officer_16'),
      AssetRepository.portraitOfficer16,
    );
    expect(
      AssetRepository.officerPortrait('officer_5'),
      AssetRepository.portraitOfficer5,
    );
    expect(
      AssetRepository.officerPortrait('officer_11'),
      AssetRepository.portraitOfficer11,
    );
    expect(
      AssetRepository.officerPortrait('officer_17'),
      AssetRepository.portraitOfficer17,
    );
    expect(
      AssetRepository.officerPortrait('officer_6'),
      AssetRepository.portraitOfficer6,
    );
    expect(
      AssetRepository.officerPortrait('officer_12'),
      AssetRepository.portraitOfficer12,
    );
    expect(
      AssetRepository.officerPortrait('officer_18'),
      AssetRepository.portraitOfficer18,
    );
    expect(
      AssetRepository.officerPortrait('officer_19'),
      AssetRepository.portraitOfficer19,
    );
    expect(
      AssetRepository.officerPortrait('officer_20'),
      AssetRepository.portraitOfficer20,
    );
    expect(
      AssetRepository.officerPortrait('officer_21'),
      AssetRepository.portraitOfficer21,
    );
    expect(
      AssetRepository.officerPortrait('officer_22'),
      AssetRepository.portraitOfficer22,
    );
    expect(
      AssetRepository.officerPortrait('officer_23'),
      AssetRepository.portraitOfficer23,
    );
    expect(
      AssetRepository.officerPortrait('officer_24'),
      AssetRepository.portraitOfficer24,
    );
  });

  test('한국 장수의 역사 메타데이터는 저장과 복원에서 유지된다', () {
    final state = GameState.fromScenario(KoreaScenario.create());
    final restored = GameState.fromSaveMap(state.toSaveMap());
    final officer = restored.officers.firstWhere((o) => o.id == 'officer_24');
    expect(officer.historicalName, '흑치상지');
    expect(officer.displayName, '흑치상지');
    expect(officer.role, '백제 장군');
    expect(officer.birthYear, 630);
    expect(officer.deathYear, 689);
    expect(officer.sourceNote, contains('구당서'));
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
