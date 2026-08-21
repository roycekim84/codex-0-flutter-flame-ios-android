import '../models/game_state.dart';
import '../battle/battle_engine.dart';
import '../battle/battle_state.dart';

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

  void tax(String provinceId) {
    final p = _playerProvince(provinceId);
    if (p == null) return;
    state.playerForce.gold += 90 + p.land;
    p.publicLoyalty = (p.publicLoyalty - 4).clamp(0, 100).toInt();
    state.log('${p.name} 징세 · 금 +${90 + p.land} · 민심 -4');
  }

  void relief(String provinceId) {
    final p = _playerProvince(provinceId);
    if (p == null || state.playerForce.gold < 80) return;
    state.playerForce.gold -= 80;
    p.publicLoyalty = (p.publicLoyalty + 6).clamp(0, 100).toInt();
    state.log('${p.name} 시혜 · 금 -80 · 민심 +6');
  }

  void train(String provinceId) {
    final p = _playerProvince(provinceId);
    if (p == null || state.playerForce.gold < 60) return;
    state.playerForce.gold -= 60;
    state.log('${p.name} 훈련 · 군사 훈련도 상승 · 금 -60');
  }

  void fortify(String provinceId) {
    final p = _playerProvince(provinceId);
    if (p == null || state.playerForce.gold < 120) return;
    state.playerForce.gold -= 120;
    p.land = (p.land + 2).clamp(0, 100).toInt();
    state.log('${p.name} 축성 · 방어 기반 +2 · 금 -120');
  }

  BattleEngine? beginBattle(String targetProvinceId) {
    final target = state.provinces
        .where((p) => p.id == targetProvinceId)
        .firstOrNull;
    if (target == null || state.isPlayerProvince(target)) return null;
    final source = state.provinces
        .where(
          (p) =>
              state.isPlayerProvince(p) &&
              p.adjacentProvinceIds.contains(target.id) &&
              p.soldiers > 300,
        )
        .firstOrNull;
    if (source == null || state.playerForce.food < 150) return null;
    final committed = (source.soldiers * 0.65).round();
    source.soldiers -= committed;
    state.playerForce.food -= 150;
    state.log(
      '${source.name}에서 ${target.name}(으)로 출병 · 병력 $committed · 군량 -150',
    );
    return BattleEngine(
      BattleState(
        targetProvinceId: target.id,
        attackerName: state.playerForce.name,
        defenderName: target.ownerName,
        attackerSoldiers: committed,
        defenderSoldiers: target.soldiers,
      ),
    );
  }

  void resolveBattle(BattleEngine battle) {
    final target = state.provinces.firstWhere(
      (p) => p.id == battle.state.targetProvinceId,
    );
    if (battle.state.attackerWon) {
      final oldForce = state.forces.firstWhere(
        (f) => f.id == target.ownerForceId,
      );
      oldForce.provinceIds.remove(target.id);
      final player = state.playerForce;
      if (!player.provinceIds.contains(target.id)) {
        player.provinceIds.add(target.id);
      }
      target.ownerForceId = player.id;
      target.ownerName = player.name;
      target.soldiers = battle.state.attackerSoldiers;
      state.log('${target.name} 점령 · 남은 병력 ${target.soldiers}');
    } else {
      target.soldiers = battle.state.defenderSoldiers;
      state.log('${target.name} 공격 실패 · 방어군이 지켜냄');
    }
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
              state.isPlayerProvince(p) &&
              p.id != target.id &&
              p.adjacentProvinceIds.contains(target.id) &&
              p.officerIds.isNotEmpty,
        )
        .firstOrNull;
    return source != null && moveOfficer(source.officerIds.first, target.id);
  }

  void endTurn() {
    for (final p in state.provinces.where(state.isPlayerProvince)) {
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

  ProvinceState? _playerProvince(String id) => state.provinces
      .where((p) => p.id == id && state.isPlayerProvince(p))
      .firstOrNull;
}
