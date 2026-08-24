import 'dart:convert';

import 'demo_scenario.dart';
import '../core/game_brand.dart';

/// First Korean setting data pack.
///
/// The engine consumes the same map shape as the generic scenario. This first
/// pack deliberately keeps the proven 12-node topology while replacing its
/// world data; the full historically researched roster will be expanded in a
/// later data-only pass.
class KoreaScenario {
  static Map<String, dynamic> create() {
    final scenario =
        jsonDecode(jsonEncode(DemoScenario.create())) as Map<String, dynamic>;
    scenario['id'] = GameBrand.koreanScenarioId;
    scenario['year'] = 642;
    scenario['month'] = 1;
    scenario['randomSeed'] = 642;

    final forceNames = <String, String>{
      'force_green': '신라',
      'force_red': '고구려',
      'force_blue': '백제',
    };
    final forceMetadata = <String, Map<String, dynamic>>{
      'force_green': {
        'bannerAssetId': 'banner_silla',
        'capitalProvinceId': 'p_ash',
        'mapColorValue': 0xff3d7d70,
      },
      'force_red': {
        'bannerAssetId': 'banner_goguryeo',
        'capitalProvinceId': 'p_crown',
        'mapColorValue': 0xff9b443c,
      },
      'force_blue': {
        'bannerAssetId': 'banner_baekje',
        'capitalProvinceId': 'p_elm',
        'mapColorValue': 0xff4b5f8f,
      },
    };
    for (final force in (scenario['forces'] as List).cast<Map>()) {
      final id = force['id'] as String;
      force['name'] = forceNames[id] ?? force['name'];
      force.addAll(forceMetadata[id] ?? const {});
    }

    final provinceNames = [
      '금성',
      '경주',
      '평양',
      '국내성',
      '사비',
      '웅진',
      '한성',
      '김해',
      '요동',
      '남해',
      '부여',
      '우산',
    ];
    final provinces = (scenario['provinces'] as List).cast<Map>();
    for (var i = 0; i < provinces.length; i++) {
      provinces[i]['name'] = provinceNames[i];
    }

    // Keep ruler slots aligned with the three force records: Silla, Goguryeo,
    // and Baekje. This makes the first portrait batch deterministic and keeps
    // the historical identity stable when a save is migrated.
    final historicalNames = [
      '선덕여왕',
      '김춘추',
      '김유신',
      '알천',
      '김품일',
      '흠돌',
      '보장왕',
      '연개소문',
      '고건무',
      '양만춘',
      '검모잠',
      '무력',
      '의자왕',
      '계백',
      '성충',
      '흥수',
      '복신',
      '도침',
      '구형왕',
      '장보고',
    ];
    final officers = (scenario['officers'] as List).cast<Map>();
    for (var i = 0; i < officers.length; i++) {
      officers[i]['name'] = historicalNames[i];
      officers[i]['historicalStatus'] = 'historical';
      officers[i]['portraitAssetId'] = 'portrait_officer_${i + 1}';
    }
    return scenario;
  }
}
