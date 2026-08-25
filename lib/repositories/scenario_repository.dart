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

  String encode(Map<String, dynamic> scenario) {
    ScenarioValidator.validateOrThrow(scenario);
    return jsonEncode(scenario);
  }
}
