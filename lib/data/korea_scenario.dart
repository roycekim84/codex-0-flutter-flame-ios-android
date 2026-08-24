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
      '김법민',
      '김인문',
      '을지문덕',
      '흑치상지',
    ];
    final officers = (scenario['officers'] as List).cast<Map>();
    const historicalDetails = <String, Map<String, dynamic>>{
      '선덕여왕': {
        'birthYear': 606,
        'deathYear': 647,
        'role': '신라 군주',
        'sourceNote': '삼국사기 신라본기',
      },
      '김춘추': {
        'birthYear': 603,
        'deathYear': 661,
        'role': '신라 외교관',
        'sourceNote': '삼국사기 신라본기',
      },
      '김유신': {
        'birthYear': 595,
        'deathYear': 673,
        'role': '신라 총사령관',
        'sourceNote': '삼국사기 김유신 열전',
      },
      '알천': {
        'birthYear': null,
        'deathYear': null,
        'role': '신라 장군',
        'sourceNote': '삼국사기 신라본기',
      },
      '김품일': {
        'birthYear': null,
        'deathYear': null,
        'role': '신라 장군',
        'sourceNote': '삼국사기 신라본기',
      },
      '흠돌': {
        'birthYear': null,
        'deathYear': 681,
        'role': '신라 귀족 장군',
        'sourceNote': '삼국사기 신문왕본기',
      },
      '보장왕': {
        'birthYear': null,
        'deathYear': 682,
        'role': '고구려 군주',
        'sourceNote': '삼국사기 고구려본기',
      },
      '연개소문': {
        'birthYear': 601,
        'deathYear': 666,
        'role': '고구려 대막리지',
        'sourceNote': '삼국사기 개소문 열전',
      },
      '고건무': {
        'birthYear': null,
        'deathYear': null,
        'role': '고구려 장군',
        'sourceNote': '삼국사기 고구려본기',
      },
      '양만춘': {
        'birthYear': null,
        'deathYear': null,
        'role': '고구려 성주',
        'sourceNote': '삼국사기 고구려본기',
      },
      '검모잠': {
        'birthYear': null,
        'deathYear': 670,
        'role': '고구려 부흥군 지휘관',
        'sourceNote': '삼국사기 고구려본기',
      },
      '무력': {
        'birthYear': null,
        'deathYear': null,
        'role': '고구려 변경 장군',
        'sourceNote': '고구려 관련 사료 기록',
      },
      '의자왕': {
        'birthYear': 599,
        'deathYear': 660,
        'role': '백제 군주',
        'sourceNote': '삼국사기 백제본기',
      },
      '계백': {
        'birthYear': null,
        'deathYear': 660,
        'role': '백제 장군',
        'sourceNote': '삼국사기 계백 열전',
      },
      '성충': {
        'birthYear': null,
        'deathYear': null,
        'role': '백제 좌평',
        'sourceNote': '삼국사기 백제본기',
      },
      '흥수': {
        'birthYear': null,
        'deathYear': null,
        'role': '백제 좌평',
        'sourceNote': '삼국사기 백제본기',
      },
      '복신': {
        'birthYear': null,
        'deathYear': 663,
        'role': '백제 부흥군 지휘관',
        'sourceNote': '삼국사기 백제본기',
      },
      '도침': {
        'birthYear': null,
        'deathYear': 661,
        'role': '백제 부흥군 승려 지휘관',
        'sourceNote': '삼국사기 백제본기',
      },
      '구형왕': {
        'birthYear': null,
        'deathYear': null,
        'role': '가야계 군주',
        'sourceNote': '삼국사기 신라본기',
      },
      '장보고': {
        'birthYear': null,
        'deathYear': 846,
        'role': '해상 지휘관',
        'sourceNote': '삼국사기 장보고 열전',
      },
      '김법민': {
        'birthYear': 626,
        'deathYear': 681,
        'role': '신라 왕자·장군',
        'sourceNote': '삼국사기 문무왕본기',
      },
      '김인문': {
        'birthYear': 629,
        'deathYear': 694,
        'role': '신라 외교관·장군',
        'sourceNote': '삼국사기 김인문 열전',
      },
      '을지문덕': {
        'birthYear': null,
        'deathYear': null,
        'role': '고구려 전략가',
        'sourceNote': '삼국사기 을지문덕 열전',
      },
      '흑치상지': {
        'birthYear': 630,
        'deathYear': 689,
        'role': '백제 장군',
        'sourceNote': '구당서 흑치상지 열전',
      },
    };
    for (var i = 0; i < officers.length; i++) {
      final name = historicalNames[i];
      final details = historicalDetails[name]!;
      officers[i]['name'] = historicalNames[i];
      officers[i]['historicalName'] = name;
      officers[i]['displayName'] = name;
      officers[i].addAll(details);
      officers[i]['historicalStatus'] = 'historical';
      officers[i]['portraitAssetId'] = 'portrait_officer_${i + 1}';
    }
    officers.addAll([
      {
        'id': 'officer_21',
        'name': '김법민',
        'forceId': 'free',
        'provinceId': 'free',
        'war': 82,
        'intelligence': 76,
        'charisma': 84,
        'loyalty': 0,
        'status': 'FREE',
        'historicalStatus': 'historical',
        'portraitAssetId': 'portrait_officer_21',
        'historicalName': '김법민',
        'displayName': '김법민',
        'birthYear': 626,
        'deathYear': 681,
        'role': '신라 왕자·장군',
        'sourceNote': '삼국사기 문무왕본기',
      },
      {
        'id': 'officer_22',
        'name': '김인문',
        'forceId': 'free',
        'provinceId': 'free',
        'war': 68,
        'intelligence': 88,
        'charisma': 86,
        'loyalty': 0,
        'status': 'FREE',
        'historicalStatus': 'historical',
        'portraitAssetId': 'portrait_officer_22',
        'historicalName': '김인문',
        'displayName': '김인문',
        'birthYear': 629,
        'deathYear': 694,
        'role': '신라 외교관·장군',
        'sourceNote': '삼국사기 김인문 열전',
      },
      {
        'id': 'officer_23',
        'name': '을지문덕',
        'forceId': 'free',
        'provinceId': 'free',
        'war': 91,
        'intelligence': 96,
        'charisma': 72,
        'loyalty': 0,
        'status': 'FREE',
        'historicalStatus': 'historical',
        'portraitAssetId': 'portrait_officer_23',
        'historicalName': '을지문덕',
        'displayName': '을지문덕',
        'birthYear': null,
        'deathYear': null,
        'role': '고구려 전략가',
        'sourceNote': '삼국사기 을지문덕 열전',
      },
      {
        'id': 'officer_24',
        'name': '흑치상지',
        'forceId': 'free',
        'provinceId': 'free',
        'war': 88,
        'intelligence': 74,
        'charisma': 79,
        'loyalty': 0,
        'status': 'FREE',
        'historicalStatus': 'historical',
        'portraitAssetId': 'portrait_officer_24',
        'historicalName': '흑치상지',
        'displayName': '흑치상지',
        'birthYear': 630,
        'deathYear': 689,
        'role': '백제 장군',
        'sourceNote': '구당서 흑치상지 열전',
      },
    ]);
    return scenario;
  }
}
