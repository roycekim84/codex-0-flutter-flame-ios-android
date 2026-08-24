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
    for (final force in (scenario['forces'] as List).cast<Map>()) {
      final id = force['id'] as String;
      force['name'] = forceNames[id] ?? force['name'];
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

    final historicalNames = [
      '선덕여왕',
      '김춘추',
      '보장왕',
      '연개소문',
      '의자왕',
      '계백',
      '김유신',
      '알천',
      '고건무',
      '양만춘',
      '성충',
      '흥수',
      '복신',
      '도침',
      '김품일',
      '흠돌',
      '구형왕',
      '무력',
      '장보고',
      '검모잠',
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
