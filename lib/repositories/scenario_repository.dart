import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/scenario_validator.dart';

/// Data-pack boundary for JSON scenarios.
///
/// `decode` is pure and is used by unit tests and migrations. `loadAsset` is
/// the Flutter entry point used when scenarios move from Dart fixtures to
/// `assets/data/scenarios/*.json`.
class ScenarioRepository {
  const ScenarioRepository();

  static const koreanScenarioManifestAsset =
      'assets/data/scenarios/scenario_korea_642.json';

  Map<String, dynamic> decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('시나리오 JSON의 최상위 형식이 올바르지 않습니다.');
    }
    final scenario = Map<String, dynamic>.from(decoded);
    ScenarioValidator.validateOrThrow(scenario);
    return scenario;
  }

  Future<Map<String, dynamic>> loadAsset(String assetPath) async {
    return decode(await rootBundle.loadString(assetPath));
  }

  Future<Map<String, dynamic>> loadKoreanManifest() async {
    return decodeManifest(
      await rootBundle.loadString(koreanScenarioManifestAsset),
    );
  }

  Map<String, dynamic> decodeManifest(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('시나리오팩 매니페스트 형식이 올바르지 않습니다.');
    }
    final manifest = Map<String, dynamic>.from(decoded);
    _validateManifest(manifest);
    return manifest;
  }

  String encode(Map<String, dynamic> scenario) {
    ScenarioValidator.validateOrThrow(scenario);
    return jsonEncode(scenario);
  }

  void _validateManifest(Map<String, dynamic> manifest) {
    final id = manifest['id'];
    final year = manifest['year'];
    final forces = manifest['forces'];
    final provinces = manifest['provinces'];
    if (id is! String || !id.startsWith('scenario_')) {
      throw const FormatException('시나리오팩 ID가 올바르지 않습니다.');
    }
    if (year is! int || year < 1) {
      throw const FormatException('시나리오팩 연도가 올바르지 않습니다.');
    }
    if (forces is! List ||
        forces.isEmpty ||
        forces.any((force) => force is! Map || force['id'] is! String)) {
      throw const FormatException('시나리오팩 세력 목록이 올바르지 않습니다.');
    }
    if (provinces is! List ||
        provinces.isEmpty ||
        provinces.any(
          (province) =>
              province is! Map ||
              province['id'] is! String ||
              province['name'] is! String,
        )) {
      throw const FormatException('시나리오팩 지역 목록이 올바르지 않습니다.');
    }
  }
}
