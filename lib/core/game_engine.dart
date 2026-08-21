import '../models/game_state.dart';

class GameEngine {
  GameEngine(this.state);
  final GameState state;
  void addListener(void Function() listener) => state.addListener(listener);
  void removeListener(void Function() listener) =>
      state.removeListener(listener);
  void dispose() => state.dispose();
  void develop(String provinceId) {
    final p = _playerProvince(provinceId);
    if (p == null || state.playerForce.gold < 100) return;
    state.playerForce.gold -= 100;
    final before = p.land;
    p.land = (p.land + 5).clamp(0, 100).toInt();
    state.log('${p.name} 개발 실행 · 토지 $before → ${p.land} · 금 -100');
  }

  void recruit(String provinceId) {
    final p = _playerProvince(provinceId);
    if (p == null || state.playerForce.gold < 80) return;
    state.playerForce.gold -= 80;
    final gain = (80 * (0.6 + p.publicLoyalty / 200)).round();
    p.soldiers += gain;
    p.publicLoyalty = (p.publicLoyalty - 1).clamp(0, 100).toInt();
    state.log('${p.name} 징병 · 병력 +$gain · 금 -80');
  }

  bool moveOfficer(String officerId, String targetProvinceId) {
    final officer = state.officers.firstWhere((o) => o.id == officerId);
    final from = _playerProvince(officer.provinceId);
    final target = _playerProvince(targetProvinceId);
    if (from == null ||
        target == null ||
        !from.adjacentProvinceIds.contains(target.id)) {
      return false;
    }
    from.officerIds.remove(officer.id);
    target.officerIds.add(officer.id);
    officer.provinceId = target.id;
    state.log('${officer.name}이(가) ${from.name}에서 ${target.name}(으)로 이동');
    return true;
  }

  bool moveFirstOfficerTo(String targetProvinceId) {
    final target = _playerProvince(targetProvinceId);
    if (target == null) return false;
    final source = state.provinces
        .where(
          (p) =>
              p.isPlayerOwned &&
              p.id != target.id &&
              p.adjacentProvinceIds.contains(target.id) &&
              p.officerIds.isNotEmpty,
        )
        .firstOrNull;
    return source != null && moveOfficer(source.officerIds.first, target.id);
  }

  void endTurn() {
    for (final p in state.provinces.where((p) => p.isPlayerOwned)) {
      state.playerForce.gold += 15 + p.land ~/ 5;
      state.playerForce.food += 20 + p.land ~/ 3;
    }
    for (final force in state.forces.where(
      (f) => f.id != state.playerForceId,
    )) {
      if (force.gold >= 80 && force.provinceIds.isNotEmpty) {
        force.gold -= 80;
        final p = state.provinces.firstWhere((p) => p.ownerForceId == force.id);
        p.soldiers += 45;
      }
    }
    state.month++;
    if (state.month > 12) {
      state.month = 1;
      state.year++;
    }
    state.log('월말 정산 및 AI 행동 완료');
  }

  ProvinceState? _playerProvince(String id) =>
      state.provinces.where((p) => p.id == id && p.isPlayerOwned).firstOrNull;
}
