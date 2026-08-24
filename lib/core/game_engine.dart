import '../models/game_state.dart';
import '../ai/ai_engine.dart';
import '../battle/battle_engine.dart';
import '../battle/battle_state.dart';
import '../battle/terrain.dart';
import 'game_command.dart';

enum PrisonerAction { recruit, release, execute }

class GameEngine {
  GameEngine(this.state);
  final GameState state;
  final AiEngine aiEngine = AiEngine();
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
      case GameCommandType.rewardOfficer:
        final result = rewardOfficer(
          command.targetOfficerId ?? command.officerId!,
        );
        if (!result.success) return result;
      case GameCommandType.appointGovernor:
        final result = appointGovernor(command.officerId!, command.provinceId!);
        if (!result.success) return result;
      case GameCommandType.moveOfficer:
        if (command.destinationProvinceId == null ||
            !moveOfficer(
              command.officerId!,
              command.destinationProvinceId!,
              soldiers: command.soldiers,
            )) {
          return const CommandResult.failure('인접한 아군 지역으로만 장수를 이동할 수 있습니다.');
        }
      case GameCommandType.giftForce:
        final result = giftForce(command.targetForceId!, command.officerId!);
        if (!result.success) return result;
      case GameCommandType.formAlliance:
        final result = formAlliance(command.targetForceId!, command.officerId!);
        if (!result.success) return result;
      case GameCommandType.threatenForce:
        final result = threatenForce(
          command.targetForceId!,
          command.officerId!,
        );
        if (!result.success) return result;
      case GameCommandType.infiltrate:
        final result = infiltrate(command.provinceId!, command.officerId!);
        if (!result.success) return result;
      case GameCommandType.inciteOfficer:
        final result = inciteOfficer(
          command.targetOfficerId!,
          command.officerId!,
        );
        if (!result.success) return result;
      case GameCommandType.spreadRumor:
        final result = spreadRumor(command.provinceId!, command.officerId!);
        if (!result.success) return result;
      case GameCommandType.buyFood:
        final result = buyFood(command.provinceId!, command.soldiers ?? 0);
        if (!result.success) return result;
      case GameCommandType.sellFood:
        final result = sellFood(command.provinceId!, command.soldiers ?? 0);
        if (!result.success) return result;
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

  CommandResult rewardOfficer(String officerId) {
    final officer = _playerOfficer(officerId);
    if (officer == null) {
      return const CommandResult.failure('포상할 장수를 찾을 수 없습니다.');
    }
    const cost = 100;
    if (state.playerForce.gold < cost) {
      return const CommandResult.failure('포상할 금이 부족합니다.');
    }
    state.playerForce.gold -= cost;
    officer.loyalty = (officer.loyalty + 5).clamp(0, 100).toInt();
    state.log('${officer.name} 포상 · 충성도 +5 · 금 -$cost');
    return CommandResult.success('${officer.name}을 포상했습니다.');
  }

  CommandResult giftForce(String targetForceId, String officerId) {
    final target = _diplomaticTarget(targetForceId);
    final officer = _playerOfficer(officerId);
    if (target == null || officer == null) {
      return const CommandResult.failure('외교 대상 또는 수행 장수를 찾을 수 없습니다.');
    }
    if (state.playerForce.gold < 100) {
      return const CommandResult.failure('선물할 금이 부족합니다.');
    }
    state.playerForce.gold -= 100;
    final before = state.relationTo(target.id);
    state.setRelation(target.id, before + 15 + officer.charisma ~/ 30);
    state.log(
      '${target.name}에 선물 · 금 -100 · 관계 $before → ${state.relationTo(target.id)}',
    );
    return CommandResult.success('${target.name}과의 관계가 좋아졌습니다.');
  }

  CommandResult formAlliance(String targetForceId, String officerId) {
    final target = _diplomaticTarget(targetForceId);
    final officer = _playerOfficer(officerId);
    if (target == null || officer == null) {
      return const CommandResult.failure('외교 대상 또는 수행 장수를 찾을 수 없습니다.');
    }
    if (state.relationTo(target.id) < 20) {
      return const CommandResult.failure('관계가 아직 동맹을 맺기에는 낮습니다. 선물을 먼저 보내십시오.');
    }
    state.alliedForceIds.add(target.id);
    state.log('${target.name}과 동맹 체결 · ${officer.name}의 외교');
    return CommandResult.success('${target.name}과 동맹을 맺었습니다.');
  }

  CommandResult threatenForce(String targetForceId, String officerId) {
    final target = _diplomaticTarget(targetForceId);
    final officer = _playerOfficer(officerId);
    if (target == null || officer == null) {
      return const CommandResult.failure('외교 대상 또는 수행 장수를 찾을 수 없습니다.');
    }
    final before = state.relationTo(target.id);
    state.setRelation(target.id, before - 20);
    state.alliedForceIds.remove(target.id);
    state.log(
      '${target.name} 협박 · 관계 $before → ${state.relationTo(target.id)}',
    );
    return CommandResult.success('${target.name}을 협박했습니다. 관계가 악화되었습니다.');
  }

  CommandResult infiltrate(String provinceId, String officerId) {
    final province = _enemyProvince(provinceId);
    final officer = _playerOfficer(officerId);
    if (province == null || officer == null) {
      return const CommandResult.failure('적 영지와 수행 장수를 확인할 수 없습니다.');
    }
    if (state.playerForce.gold < 80) {
      return const CommandResult.failure('잠입 자금이 부족합니다.');
    }
    state.playerForce.gold -= 80;
    state.revealedProvinceIds.add(province.id);
    state.log(
      '${province.name} 잠입 · 병력 ${province.soldiers} · 군량 ${province.food} · 금 -80',
    );
    return CommandResult.success('${province.name}의 정보가 공개되었습니다.');
  }

  CommandResult buyFood(String provinceId, int amount) {
    final province = _playerProvince(provinceId);
    if (province == null || amount <= 0) {
      return const CommandResult.failure('구매할 군량 수량을 확인할 수 없습니다.');
    }
    final cost = (amount * .9).round();
    if (state.playerForce.gold < cost) {
      return const CommandResult.failure('군량 구매에 필요한 금이 부족합니다.');
    }
    state.playerForce.gold -= cost;
    province.food += amount;
    state.log('${province.name} 군량 구매 · 군량 +$amount · 금 -$cost');
    return CommandResult.success('군량 $amount을 구매했습니다.');
  }

  CommandResult sellFood(String provinceId, int amount) {
    final province = _playerProvince(provinceId);
    if (province == null || amount <= 0 || province.food < amount) {
      return const CommandResult.failure('판매할 군량이 부족합니다.');
    }
    final income = (amount * .9).round();
    province.food -= amount;
    state.playerForce.gold += income;
    state.log('${province.name} 군량 판매 · 군량 -$amount · 금 +$income');
    return CommandResult.success('군량 $amount을 판매했습니다.');
  }

  CommandResult inciteOfficer(String targetOfficerId, String officerId) {
    final target = state.officers
        .where(
          (o) =>
              o.id == targetOfficerId &&
              o.forceId != state.playerForceId &&
              o.status != 'DEAD',
        )
        .firstOrNull;
    final officer = _playerOfficer(officerId);
    if (target == null || officer == null) {
      return const CommandResult.failure('이간할 적 장수와 수행 장수를 확인할 수 없습니다.');
    }
    if (state.playerForce.gold < 100) {
      return const CommandResult.failure('이간 공작 자금이 부족합니다.');
    }
    state.playerForce.gold -= 100;
    final before = target.loyalty;
    target.loyalty = (target.loyalty - 10 - officer.intelligence ~/ 25)
        .clamp(0, 100)
        .toInt();
    state.log('${target.name} 이간 · 충성 $before → ${target.loyalty} · 금 -100');
    return CommandResult.success('${target.name}의 충성도가 낮아졌습니다.');
  }

  CommandResult spreadRumor(String provinceId, String officerId) {
    final province = _enemyProvince(provinceId);
    final officer = _playerOfficer(officerId);
    if (province == null || officer == null) {
      return const CommandResult.failure('유언비어 대상과 수행 장수를 확인할 수 없습니다.');
    }
    if (state.playerForce.gold < 80) {
      return const CommandResult.failure('유언비어 자금이 부족합니다.');
    }
    state.playerForce.gold -= 80;
    final before = province.publicLoyalty;
    province.publicLoyalty = (before - 8 - officer.intelligence ~/ 40)
        .clamp(0, 100)
        .toInt();
    state.log(
      '${province.name} 유언비어 · 민심 $before → ${province.publicLoyalty} · 금 -80',
    );
    return CommandResult.success('${province.name}의 민심이 흔들렸습니다.');
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
    p.training = (p.training + 5).clamp(0, 100).toInt();
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
    return beginBattlePrepared(
      sourceProvinceId: source.id,
      targetProvinceId: target.id,
      committedSoldiers: committed,
    );
  }

  BattleEngine? beginBattlePrepared({
    required String sourceProvinceId,
    required String targetProvinceId,
    required int committedSoldiers,
    List<String>? participantOfficerIds,
    String? commanderOfficerId,
  }) {
    final source = _playerProvince(sourceProvinceId);
    final target = state.provinces
        .where((p) => p.id == targetProvinceId)
        .firstOrNull;
    if (source == null ||
        target == null ||
        state.isPlayerProvince(target) ||
        !source.adjacentProvinceIds.contains(target.id)) {
      return null;
    }
    if (committedSoldiers < 100 ||
        committedSoldiers > source.soldiers ||
        state.playerForce.food < 150) {
      return null;
    }
    final participants =
        participantOfficerIds == null || participantOfficerIds.isEmpty
        ? [source.officerIds.first]
        : participantOfficerIds.where(source.officerIds.contains).toList();
    if (participants.isEmpty) return null;
    final commanderId =
        commanderOfficerId != null && participants.contains(commanderOfficerId)
        ? commanderOfficerId
        : participants.first;
    final base = committedSoldiers ~/ participants.length;
    final units = <BattleUnit>[];
    for (var i = 0; i < participants.length; i++) {
      final officer = state.officers.firstWhere((o) => o.id == participants[i]);
      units.add(
        BattleUnit(
          officerId: officer.id,
          name: officer.name,
          soldiers:
              base +
              (i == 0 ? committedSoldiers - base * participants.length : 0),
          war: officer.war,
          intelligence: officer.intelligence,
          row: 3 + i ~/ 3,
          // Leave one hex between formations so banners and troop counts
          // remain readable on the narrow portrait battlefield.
          column: (i % 3) * 2,
          type: switch (i) {
            0 => BattleUnitType.cavalry,
            1 => BattleUnitType.archers,
            _ => BattleUnitType.infantry,
          },
        ),
      );
    }
    final commander = state.officers.firstWhere((o) => o.id == commanderId);
    final defenders = <BattleUnit>[];
    if (target.officerIds.isNotEmpty) {
      final baseDefenderSoldiers = target.soldiers ~/ target.officerIds.length;
      for (var i = 0; i < target.officerIds.length; i++) {
        final officer = state.officers.firstWhere(
          (o) => o.id == target.officerIds[i],
        );
        defenders.add(
          BattleUnit(
            officerId: officer.id,
            name: officer.name,
            soldiers: baseDefenderSoldiers,
            war: officer.war,
            intelligence: officer.intelligence,
            row: i ~/ 3,
            column: 1 + (i % 3) * 2,
            type: switch (i) {
              0 => BattleUnitType.cavalry,
              1 => BattleUnitType.archers,
              _ => BattleUnitType.infantry,
            },
          ),
        );
      }
    }
    if (defenders.isNotEmpty) {
      defenders.first.soldiers +=
          target.soldiers - defenders.fold(0, (sum, u) => sum + u.soldiers);
    }
    source.soldiers -= committedSoldiers;
    state.playerForce.food -= 150;
    state.log(
      '${source.name}에서 ${target.name}(으)로 출병 · 병력 $committedSoldiers · 군량 -150',
    );
    return BattleEngine(
      BattleState(
        sourceProvinceId: source.id,
        targetProvinceId: target.id,
        attackerName: state.playerForce.name,
        defenderName: target.ownerName,
        attackerSoldiers: committedSoldiers,
        defenderSoldiers: target.soldiers,
        attackerUnits: units,
        defenderUnits: defenders,
        commanderName: commander.name,
        commanderWar: commander.war,
        terrain: target.id == 'p_dale' ? TerrainType.fort : TerrainType.plain,
        attackerFood: state.playerForce.food,
        dailySupplyCost: (committedSoldiers ~/ 20).clamp(50, 500),
      ),
    );
  }

  List<BattleOfficerOutcome> resolveBattle(BattleEngine battle) {
    if (battle.state.outcomes.isNotEmpty) return battle.state.outcomes;
    final target = state.provinces.firstWhere(
      (p) => p.id == battle.state.targetProvinceId,
    );
    final source = state.provinces.firstWhere(
      (p) => p.id == battle.state.sourceProvinceId,
    );
    final oldForce = state.forces.firstWhere(
      (f) => f.id == target.ownerForceId,
    );
    final attackerWon = battle.state.attackerWon;

    for (final unit in battle.state.attackerUnits) {
      final result = unit.soldiers <= 0
          ? (attackerWon
                ? BattleOfficerResult.dead
                : BattleOfficerResult.captured)
          : BattleOfficerResult.escaped;
      final officer = state.officers.firstWhere((o) => o.id == unit.officerId);
      battle.state.outcomes.add(
        BattleOfficerOutcome(
          officerId: officer.id,
          name: officer.name,
          result: result,
          soldiers: unit.soldiers,
        ),
      );
      if (result == BattleOfficerResult.captured) {
        source.officerIds.remove(officer.id);
        officer.status = 'CAPTIVE';
        officer.provinceId = target.id;
      } else if (result == BattleOfficerResult.dead) {
        source.officerIds.remove(officer.id);
        officer.status = 'DEAD';
        officer.provinceId = 'dead';
      } else if (attackerWon) {
        source.officerIds.remove(officer.id);
        target.officerIds.add(officer.id);
        officer.provinceId = target.id;
      }
    }
    for (final unit in battle.state.defenderUnits) {
      final result = unit.soldiers <= 0
          ? (attackerWon
                ? BattleOfficerResult.captured
                : BattleOfficerResult.dead)
          : BattleOfficerResult.escaped;
      final officer = state.officers.firstWhere((o) => o.id == unit.officerId);
      battle.state.outcomes.add(
        BattleOfficerOutcome(
          officerId: officer.id,
          name: officer.name,
          result: result,
          soldiers: unit.soldiers,
        ),
      );
      if (result == BattleOfficerResult.captured) {
        target.officerIds.remove(officer.id);
        officer.status = 'CAPTIVE';
        officer.provinceId = target.id;
      } else if (result == BattleOfficerResult.dead) {
        target.officerIds.remove(officer.id);
        officer.status = 'DEAD';
        officer.provinceId = 'dead';
      } else if (attackerWon) {
        target.officerIds.remove(officer.id);
        oldForce.officerIds.remove(officer.id);
        officer.status = 'FREE';
        officer.provinceId = 'free';
      }
    }
    if (battle.state.attackerWon) {
      oldForce.provinceIds.remove(target.id);
      final player = state.playerForce;
      if (!player.provinceIds.contains(target.id)) {
        player.provinceIds.add(target.id);
      }
      target.ownerForceId = player.id;
      target.ownerName = player.name;
      target.soldiers = battle.state.attackerSoldiers;
      battle.state.returnedSoldiers = battle.state.attackerSoldiers;
      battle.state.returnProvinceId = target.id;
      state.log('${target.name} 점령 · 남은 병력 ${target.soldiers}');
    } else {
      target.soldiers = battle.state.defenderSoldiers;
      source.soldiers += battle.state.attackerSoldiers;
      battle.state.returnedSoldiers = battle.state.attackerSoldiers;
      battle.state.returnProvinceId = source.id;
      state.log('${source.name} 귀환 · 잔여 병력 ${battle.state.attackerSoldiers}');
      state.log('${target.name} 공격 실패 · 방어군이 지켜냄');
    }
    state.log(
      '전투 장수 결과 · 포로 ${battle.state.outcomes.where((o) => o.result == BattleOfficerResult.captured).length}명 · 전사 ${battle.state.outcomes.where((o) => o.result == BattleOfficerResult.dead).length}명',
    );
    return battle.state.outcomes;
  }

  bool handlePrisoner(
    String officerId,
    PrisonerAction action,
    String provinceId,
  ) {
    final officer = state.officers
        .where((o) => o.id == officerId && o.status == 'CAPTIVE')
        .firstOrNull;
    final province = state.provinces
        .where((p) => p.id == provinceId)
        .firstOrNull;
    if (officer == null ||
        province == null ||
        !state.isPlayerProvince(province)) {
      return false;
    }
    final oldForce = state.forces
        .where((f) => f.id == officer.forceId)
        .firstOrNull;
    province.officerIds.remove(officer.id);
    switch (action) {
      case PrisonerAction.recruit:
        if (state.playerForce.gold < 500) {
          province.officerIds.add(officer.id);
          return false;
        }
        state.playerForce.gold -= 500;
        oldForce?.officerIds.remove(officer.id);
        state.playerForce.officerIds.add(officer.id);
        officer.forceId = state.playerForceId;
        officer.status = 'OFFICER';
        officer.provinceId = province.id;
        officer.loyalty = 45;
        province.officerIds.add(officer.id);
        state.log('${officer.name} 포로 등용 · 금 -500');
      case PrisonerAction.release:
        officer.status = 'FREE';
        officer.provinceId = 'free';
        state.log('${officer.name} 포로 석방');
      case PrisonerAction.execute:
        oldForce?.officerIds.remove(officer.id);
        officer.status = 'DEAD';
        officer.provinceId = 'dead';
        state.log('${officer.name} 포로 처형');
    }
    return true;
  }

  bool moveOfficer(String officerId, String targetProvinceId, {int? soldiers}) {
    final officer = state.officers.firstWhere((o) => o.id == officerId);
    final from = _playerProvince(officer.provinceId);
    final target = _playerProvince(targetProvinceId);
    if (from == null ||
        target == null ||
        !from.adjacentProvinceIds.contains(target.id)) {
      return false;
    }
    final transfer = (soldiers ?? 0).clamp(0, from.soldiers).toInt();
    from.soldiers -= transfer;
    target.soldiers += transfer;
    from.officerIds.remove(officer.id);
    target.officerIds.add(officer.id);
    officer.provinceId = target.id;
    state.log(
      '${officer.name}이(가) ${from.name}에서 ${target.name}(으)로 이동 · 병력 $transfer',
    );
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
    if (state.gameOver) return;
    state.lastTurnReports.clear();
    for (final p in state.provinces.where(state.isPlayerProvince)) {
      state.playerForce.gold += 15 + p.land ~/ 5;
      state.playerForce.food += 20 + p.land ~/ 3;
    }
    for (final force in state.forces.where(
      (f) => f.id != state.playerForceId,
    )) {
      final ownedProvinces = state.provinces
          .where((p) => p.ownerForceId == force.id)
          .toList();
      if (force.gold >= 80 && ownedProvinces.isNotEmpty) {
        force.gold -= 80;
        final p = ownedProvinces.first;
        p.soldiers += 45;
        state.log('${force.name} AI · ${p.name} 병력 +45');
      }
      final decision = aiEngine.choose(state, force);
      switch (decision.type) {
        case AiDecisionType.gift:
          if (force.gold >= 100) {
            force.gold -= 100;
            final before = state.relationTo(force.id);
            state.setRelation(force.id, before + 10);
            state.log(
              '${force.name} AI · 선물 외교 · 관계 $before → ${state.relationTo(force.id)}',
            );
          }
        case AiDecisionType.spy:
          final province = state.provinces
              .where((p) => p.id == decision.targetProvinceId)
              .firstOrNull;
          if (province != null && force.gold >= 80) {
            force.gold -= 80;
            final before = province.publicLoyalty;
            province.publicLoyalty = (before - 5).clamp(0, 100).toInt();
            state.log(
              '${force.name} AI · ${province.name} 첩보 · 민심 $before → ${province.publicLoyalty}',
            );
          }
        case AiDecisionType.fortify:
          if (force.gold >= 120 && ownedProvinces.isNotEmpty) {
            force.gold -= 120;
            final p = ownedProvinces.first;
            p.land = (p.land + 2).clamp(0, 100).toInt();
            state.log('${force.name} AI · ${p.name} 축성');
          }
        case AiDecisionType.attack:
          _runAiBattle(force, decision);
      }
    }
    state.month++;
    if (state.month > 12) {
      state.month = 1;
      state.year++;
    }
    _resolveMonthlyEvent();
    _checkGameOutcome();
    state.resetMonthlyActions();
    state.log('월말 정산 및 AI 행동 완료');
  }

  void _resolveMonthlyEvent() {
    state.lastEvent = null;
    if ((state.year + state.month + state.randomSeed) % 4 != 0) return;
    final province = state.provinces.where(state.isPlayerProvince).firstOrNull;
    if (province == null) return;
    switch ((state.year + state.month) % 4) {
      case 0:
        state.playerForce.food += 180;
        state.lastEvent = '${province.name}에 풍년이 들어 군량이 180 늘었습니다.';
      case 1:
        province.publicLoyalty = (province.publicLoyalty - 8)
            .clamp(0, 100)
            .toInt();
        state.lastEvent = '${province.name}에 홍수가 발생해 민심이 하락했습니다.';
      case 2:
        state.playerForce.gold += 150;
        state.lastEvent = '상인이 방문해 금 150을 얻었습니다.';
      case 3:
        province.publicLoyalty = (province.publicLoyalty - 5)
            .clamp(0, 100)
            .toInt();
        state.lastEvent = '${province.name}에 질병이 퍼져 민심이 하락했습니다.';
    }
    if (state.lastEvent != null) state.log('이벤트 · ${state.lastEvent}');
  }

  void _checkGameOutcome() {
    if (state.playerProvinceIds.length == state.provinces.length) {
      state.gameOver = true;
      state.outcome = 'VICTORY';
      state.lastEvent = '모든 지역을 통일했습니다.';
    } else if (state.playerProvinceIds.isEmpty) {
      state.gameOver = true;
      state.outcome = 'DEFEAT';
      state.lastEvent = '모든 영토를 잃었습니다.';
    }
  }

  void _runAiBattle(ForceState force, AiDecision decision) {
    final source = state.provinces
        .where((p) => p.id == decision.sourceProvinceId)
        .firstOrNull;
    final target = state.provinces
        .where((p) => p.id == decision.targetProvinceId)
        .firstOrNull;
    if (source == null ||
        target == null ||
        target.ownerForceId != state.playerForceId ||
        source.soldiers <= 300 ||
        force.food < 150 ||
        source.officerIds.isEmpty) {
      return;
    }
    final committed = (source.soldiers * .6).round();
    final attackerOfficer = state.officers.firstWhere(
      (o) => o.id == source.officerIds.first,
    );
    final battle = BattleEngine(
      BattleState(
        sourceProvinceId: source.id,
        targetProvinceId: target.id,
        attackerName: force.name,
        defenderName: target.ownerName,
        attackerSoldiers: committed,
        defenderSoldiers: target.soldiers,
        commanderName: attackerOfficer.name,
        commanderWar: attackerOfficer.war,
        attackerFood: force.food - 150,
        dailySupplyCost: (committed ~/ 20).clamp(50, 500),
      ),
    );
    source.soldiers -= committed;
    force.food -= 150;
    while (!battle.state.finished) {
      battle.attack();
    }
    if (battle.state.attackerWon) {
      final oldOwner = state.playerForce;
      oldOwner.provinceIds.remove(target.id);
      force.provinceIds.add(target.id);
      target.ownerForceId = force.id;
      target.ownerName = force.name;
      target.soldiers = battle.state.attackerSoldiers;
      for (final officerId in target.officerIds) {
        final officer = state.officers.firstWhere((o) => o.id == officerId);
        oldOwner.officerIds.remove(officer.id);
        officer.forceId = 'free';
        officer.status = 'FREE';
        officer.provinceId = 'free';
      }
      target.officerIds.clear();
      state.log(
        '${force.name} AI · ${target.name} 전술 전투 승리 · 영토 점령 · ${battle.state.day}일',
      );
    } else {
      source.soldiers += battle.state.attackerSoldiers;
      target.soldiers = battle.state.defenderSoldiers;
      state.log(
        '${force.name} AI · ${target.name} 전술 전투 패배 · 병력 귀환 · ${battle.state.day}일',
      );
    }
    state.lastTurnReports.add(
      AiBattleReport(
        attackerName: force.name,
        defenderName: state.playerForce.name,
        targetProvinceName: target.name,
        attackerWon: battle.state.attackerWon,
        day: battle.state.day,
        attackerSoldiers: battle.state.attackerSoldiers,
        defenderSoldiers: battle.state.defenderSoldiers,
      ),
    );
  }

  ProvinceState? _playerProvince(String id) => state.provinces
      .where((p) => p.id == id && state.isPlayerProvince(p))
      .firstOrNull;

  ForceState? _diplomaticTarget(String id) => state.forces
      .where((f) => f.id == id && f.id != state.playerForceId)
      .firstOrNull;

  OfficerState? _playerOfficer(String id) => state.officers
      .where((o) => o.id == id && o.forceId == state.playerForceId)
      .firstOrNull;

  ProvinceState? _enemyProvince(String id) => state.provinces
      .where((p) => p.id == id && !state.isPlayerProvince(p))
      .firstOrNull;
}
