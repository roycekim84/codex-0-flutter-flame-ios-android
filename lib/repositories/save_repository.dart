import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';

/// Serialization boundary for AUTO/1..5 save slots.
class SaveRepository {
  static const currentSaveVersion = 1;

  String encode(GameState state) =>
      jsonEncode({'saveVersion': currentSaveVersion, ...state.toSaveMap()});

  Map<String, dynamic> decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('저장 데이터의 최상위 형식이 올바르지 않습니다.');
    }
    final data = Map<String, dynamic>.from(decoded);
    final version = (data['saveVersion'] as num?)?.toInt() ?? 0;
    if (version > currentSaveVersion) {
      throw FormatException('지원하지 않는 저장 버전입니다: $version');
    }
    return _migrate(data, version);
  }

  Map<String, dynamic> _migrate(Map<String, dynamic> data, int version) {
    var migrated = Map<String, dynamic>.from(data);
    var migratedVersion = version;

    // Version 0 was the pre-versioned format. Its required fields are
    // compatible with version 1; only the marker needs to be added.
    if (migratedVersion < 1) {
      migrated = {...migrated, 'saveVersion': 1};
      migratedVersion = 1;
    }
    return migrated;
  }

  Future<void> save(GameState state, String slot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('save_$slot', encode(state));
  }

  Future<Map<String, dynamic>?> load(String slot) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('save_$slot');
    return value == null ? null : decode(value);
  }

  Future<bool> hasSave(String slot) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.containsKey('save_$slot');
  }

  Future<void> delete(String slot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('save_$slot');
  }
}
