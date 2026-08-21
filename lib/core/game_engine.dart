import '../models/game_state.dart';
import '../battle/battle_engine.dart';
import '../battle/battle_state.dart';
import 'game_command.dart';

class GameEngine {
  GameEngine(this.state);
  final GameState state;
  void addListener(void Function() listener) => state.addListener(listener);
  void removeListener(void Function() listener) =>
      state.removeListener(listener);
  void dispose() => state.dispose();

  CommandResult dispatch(GameCommand command) {
    if (command.officerId != null && state.hasActed(command.officerId!)) {
      return const CommandResult.failure('이 장수는 이번 달에 이미 명령을 수행했습니다.');
    }
    switch (command.type) {
      case GameCommandType.develop:
        develop(command.provinceId!);
      case GameCommandType.recruit:
        recruit(command.provinceId!);
      case GameCommandType.tax:
        tax(command.provinceId!);
      case GameCommandType.relief:
        relief(command.provinceId!);
      case GameCommandType.train:
        train(command.provinceId!);
      case GameCommandType.fortify:
        fortify(command.provinceId!);
      case GameCommandType.search:
        final result = search(command.provinceId!);
        if (!result.success) return result;
      case GameCommandType.recruitOfficer:
        final result = recruitOfficer(
          command.targetOfficerId!,
          command.provinceId!,
        );
        if (!result.success) return result;
      case GameCommandType.appointGovernor:
        final result = appointGovernor(command.officerId!, command.provinceId!);
        if (!result.success) return result;
      case GameCommandType.moveOfficer:
        if (command.destinationProvinceId == null ||
            !moveOfficer(command.officerId!, command.destinationProvinceId!)) {
          return const CommandResult.failure('인접한 아군 지역으로만 장수를 이동할 수 있습니다.');
        }
      case GameCommandType.endMonth:
        endTurn();
        return const CommandResult.success('월말 정산을 완료했습니다.');
    }
    if (command.officerId != null) state.markActed(command.officerId!);
    return const CommandResult.success('명령을 실행했습니다.');
  }

  OfficerState? get firstFreeOfficer =>
      state.officers.where((o) => o.status == 'FREE').firstOrNull;

  CommandResult search(String provinceId) {
    final province = _playerProvince(provinceId);
    final candidate = firstFreeOfficer;
    if (province == null) {
      return const CommandResult.failure('아군 영지에서만 탐색할 수 있습니다.');
    }
    if (candidate == null) {
      state.log('${province.name} 탐색 · 재야 인재를 찾지 못했습니다.');
      return const CommandResult.success('아무것도 발견하지 못했습니다.');
    }
    state.log('${province.name} 탐색 · ${candidate.name}의 행방을 발견했습니다.');
    return CommandResult.success(
      '${candidate.name}을 발견했습니다.',
      targetOfficerId: candidate.id,
    );
  }

  CommandResult recruitOfficer(String officerId, String provinceId) {
    final candidate = state.officers
        .where((o) => o.id == officerId && o.status == 'FREE')
        .firstOrNull;
    final province = _playerProvince(provinceId);
    if (candidate == null || province == null) {
      return const CommandResult.failure('등용할 대상을 찾을 수 없습니다.');
    }
    const cost = 200;
    if (state.playerForce.gold < cost) {
      return const CommandResult.failure('등용 자금이 부족합니다.');
    }
    state.playerForce.gold -= cost;
    candidate.forceId = state.playerForceId;
    candidate.status = 'OFFICER';
    candidate.provinceId = province.id;
    candidate.loyalty = 60;
    state.playerForce.officerIds.add(candidate.id);
    province.officerIds.add(candidate.id);
    state.log('${candidate.name} 등용 · 금 -$cost · ${province.name} 배치');
    return CommandResult.success('${candidate.name}을 등용했습니다.');
  }

  CommandResult appointGovernor(String officerId, String provinceId) {
    final province = _playerProvince(provinceId);
    final officer = state.officers
        .where(
          (o) =>
              o.id == officerId &&
              o.forceId == state.playerForceId &&
              o.provinceId == provinceId,
        )
        .firstOrNull;
    if (province == null || officer == null) {
      return const CommandResult.failure('이 지역에 있는 아군 장수만 태수로 임명할 수 있습니다.');
    }
    province.governorId = officer.id;
    state.log('${province.name} 태수 임명 · ${officer.name}');
    return CommandResult.success(
      '${officer.name}을 ${province.name} 태수로 임명했습니다.',
    );
  }

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
    state.resetMonthlyActions();
    state.log('월말 정산 및 AI 행동 완료');
  }

  ProvinceState? _playerProvince(String id) => state.provinces
      .where((p) => p.id == id && state.isPlayerProvince(p))
      .firstOrNull;
}
