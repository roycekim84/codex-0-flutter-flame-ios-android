import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';

/// Serialization boundary for AUTO/1..5 save slots.
class SaveRepository {
  String encode(GameState state) =>
      jsonEncode({'saveVersion': 1, ...state.toSaveMap()});

  Map<String, dynamic> decode(String value) =>
      jsonDecode(value) as Map<String, dynamic>;

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
