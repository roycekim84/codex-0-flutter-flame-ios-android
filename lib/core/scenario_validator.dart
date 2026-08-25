/// Validates the data-pack boundary before a scenario is handed to GameState.
///
/// This keeps historical data errors out of GameEngine. The validator is
/// intentionally map-based so JSON assets and the current Dart data packs use
/// the same contract.
abstract final class ScenarioValidator {
  static List<String> validate(Map<String, dynamic> scenario) {
    final errors = <String>[];
    final forces = _maps(scenario['forces'], 'forces', errors);
    final provinces = _maps(scenario['provinces'], 'provinces', errors);
    final officers = _maps(scenario['officers'], 'officers', errors);
    if (errors.isNotEmpty) return errors;

    final forceIds = _uniqueIds(forces, '세력', errors);
    final provinceIds = _uniqueIds(provinces, '지역', errors);
    final officerIds = _uniqueIds(officers, '장수', errors);

    final officerById = {for (final o in officers) o['id']: o};

    for (final force in forces) {
      final id = force['id'];
      final capital = force['capitalProvinceId'];
      final ruler = force['rulerId'];
      if (capital != null && !provinceIds.contains(capital)) {
        errors.add('세력 $id: 수도 지역 $capital 이(가) 없습니다.');
      }
      if (ruler != null && !officerIds.contains(ruler)) {
        errors.add('세력 $id: 군주 장수 $ruler 이(가) 없습니다.');
      }
    }

    for (final province in provinces) {
      final id = province['id'];
      final owner = province['ownerForceId'];
      if (!forceIds.contains(owner)) errors.add('지역 $id: 소유 세력이 없습니다.');
      for (final adjacent in _strings(province['adjacentProvinceIds'])) {
        if (!provinceIds.contains(adjacent)) {
          errors.add('지역 $id: 인접 지역 $adjacent 이(가) 없습니다.');
        }
      }
      for (final officerId in _strings(province['officerIds'])) {
        if (!officerIds.contains(officerId)) {
          errors.add('지역 $id: 등록 장수 $officerId 이(가) 없습니다.');
        } else if (officerById[officerId]?['provinceId'] != id) {
          errors.add('장수 $officerId: 지역 $id 와 소속 지역이 다릅니다.');
        }
      }
      final governor = province['governorId'];
      if (governor != null && !officerIds.contains(governor)) {
        errors.add('지역 $id: 태수 $governor 이(가) 없습니다.');
      }
    }

    for (final officer in officers) {
      final id = officer['id'];
      final force = officer['forceId'];
      final province = officer['provinceId'];
      if (force != 'free' && !forceIds.contains(force)) {
        errors.add('장수 $id: 소속 세력 $force 이(가) 없습니다.');
      }
      if (province != 'free' && !provinceIds.contains(province)) {
        errors.add('장수 $id: 소속 지역 $province 이(가) 없습니다.');
      }
      if (officer['historicalStatus'] == 'historical') {
        for (final field in [
          'historicalName',
          'displayName',
          'sourceNote',
          'portraitAssetId',
        ]) {
          final value = officer[field];
          if (value is! String || value.trim().isEmpty) {
            errors.add('장수 $id: 역사 인물 필드 $field 이(가) 없습니다.');
          }
        }
        final birth = officer['birthYear'];
        final death = officer['deathYear'];
        if (birth is int && death is int && birth >= death) {
          errors.add('장수 $id: 출생 연도와 사망 연도 순서가 잘못되었습니다.');
        }
      }
      for (final field in ['war', 'intelligence', 'charisma', 'loyalty']) {
        final value = officer[field];
        final maximum = field == 'loyalty' ? 100 : 100;
        if (value is! int || value < 0 || value > maximum) {
          errors.add('장수 $id: $field 값이 범위를 벗어났습니다.');
        }
      }
    }

    // These references are optional in older prototype packs, but when a
    // force declares them they must point at a real, correctly-owned record.
    for (final force in forces) {
      final forceId = force['id'];
      for (final officerId in _strings(force['officerIds'])) {
        final officer = officerById[officerId];
        if (officer == null) {
          errors.add('세력 $forceId: 등록 장수 $officerId 이(가) 없습니다.');
        } else if (officer['forceId'] != forceId) {
          errors.add('장수 $officerId: 세력 $forceId 와 소속 세력이 다릅니다.');
        }
      }
    }
    return errors;
  }

  static void validateOrThrow(Map<String, dynamic> scenario) {
    final errors = validate(scenario);
    if (errors.isNotEmpty) {
      throw FormatException('시나리오 데이터가 유효하지 않습니다:\n${errors.join('\n')}');
    }
  }

  static List<Map<String, dynamic>> _maps(
    Object? value,
    String field,
    List<String> errors,
  ) {
    if (value is! List) {
      errors.add('$field 배열이 없습니다.');
      return const [];
    }
    return value
        .whereType<Map>()
        .map((map) => Map<String, dynamic>.from(map))
        .toList();
  }

  static Set<Object?> _uniqueIds(
    List<Map<String, dynamic>> records,
    String label,
    List<String> errors,
  ) {
    final ids = <Object?>{};
    for (final record in records) {
      final id = record['id'];
      if (id is! String || id.isEmpty) {
        errors.add('$label: 비어 있는 ID가 있습니다.');
      } else if (!ids.add(id)) {
        errors.add('$label: 중복 ID $id 가 있습니다.');
      }
    }
    return ids;
  }

  static Iterable<String> _strings(Object? value) =>
      value is List ? value.whereType<String>() : const <String>[];
}
