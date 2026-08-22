import 'package:flutter_test/flutter_test.dart';
import 'package:codex_strategy/core/game_engine.dart';
import 'package:codex_strategy/core/game_command.dart';
import 'package:codex_strategy/battle/battle_engine.dart';
import 'package:codex_strategy/battle/battle_state.dart';
import 'package:codex_strategy/data/demo_scenario.dart';
import 'package:codex_strategy/models/game_state.dart';
import 'package:codex_strategy/repositories/save_repository.dart';

void main() {
  GameEngine createEngine() =>
      GameEngine(GameState.fromScenario(DemoScenario.create()));

  test('개발은 금을 소모하고 토지를 올린다', () {
    final engine = createEngine();
    final province = engine.state.provinces.first;
    final gold = engine.state.playerForce.gold;
    final land = province.land;
    engine.develop(province.id);
    expect(engine.state.playerForce.gold, gold - 100);
    expect(province.land, land + 5);
    expect(engine.state.gameLog, isNotEmpty);
  });

  test('징병은 병력을 늘리고 민심을 소폭 낮춘다', () {
    final engine = createEngine();
    final province = engine.state.provinces.first;
    final soldiers = province.soldiers;
    engine.recruit(province.id);
    expect(province.soldiers, greaterThan(soldiers));
    expect(province.publicLoyalty, 64);
  });

  test('턴 종료는 수입, AI 행동, 월 진행을 처리한다', () {
    final engine = createEngine();
    final gold = engine.state.playerForce.gold;
    final aiProvince = engine.state.provinces[2];
    final aiSoldiers = aiProvince.soldiers;
    engine.endTurn();
    expect(engine.state.month, 2);
    expect(engine.state.playerForce.gold, greaterThan(gold));
    expect(aiProvince.soldiers, aiSoldiers + 45);
    expect(engine.state.relationTo('force_red'), 0);
    expect(engine.state.gameLog.last, contains('월말 정산'));
  });

  test('월말 이벤트는 결정적인 seed로 발생하고 기록된다', () {
    final engine = createEngine();
    for (var i = 0; i < 6 && engine.state.lastEvent == null; i++) {
      engine.endTurn();
    }
    expect(engine.state.lastEvent, isNotNull);
    expect(engine.state.gameLog.any((log) => log.contains('이벤트 ·')), isTrue);
  });

  test('모든 지역 점령과 전 영토 상실은 게임 종료 상태를 만든다', () {
    final victoryEngine = createEngine();
    final player = victoryEngine.state.playerForce;
    player.provinceIds
      ..clear()
      ..addAll(victoryEngine.state.provinces.map((p) => p.id));
    for (final province in victoryEngine.state.provinces) {
      province.ownerForceId = player.id;
      province.ownerName = player.name;
    }
    for (final force in victoryEngine.state.forces.where((f) => f != player)) {
      force.provinceIds.clear();
    }
    victoryEngine.endTurn();
    expect(victoryEngine.state.outcome, 'VICTORY');

    final defeatEngine = createEngine();
    final enemy = defeatEngine.state.forces[1];
    defeatEngine.state.playerForce.provinceIds.clear();
    enemy.provinceIds
      ..clear()
      ..addAll(defeatEngine.state.provinces.map((p) => p.id));
    for (final province in defeatEngine.state.provinces) {
      province.ownerForceId = enemy.id;
      province.ownerName = enemy.name;
    }
    defeatEngine.endTurn();
    expect(defeatEngine.state.outcome, 'DEFEAT');
  });

  test('AI는 낮은 관계에서 선물 외교를 선택하고 로그를 남긴다', () {
    final engine = createEngine();
    engine.endTurn();
    expect(engine.state.relationTo('force_red'), 0);
    expect(
      engine.state.gameLog.any((log) => log.contains('AI · 선물 외교')),
      isTrue,
    );
  });

  test('적대적인 AI는 약한 인접 영지를 공격한다', () {
    final engine = createEngine();
    final target = engine.state.provinces.firstWhere((p) => p.id == 'p_briar');
    target.soldiers = 100;
    engine.state.setRelation('force_red', -30);
    engine.endTurn();
    expect(target.ownerForceId, 'force_red');
    expect(
      engine.state.gameLog.any((log) => log.contains('AI · 가시 숲 전술 전투 승리')),
      isTrue,
    );
    expect(engine.state.lastTurnReports, hasLength(1));
    expect(engine.state.lastTurnReports.first.targetProvinceName, '가시 숲');
  });

  test('인접한 아군 영지 사이에서 장수를 이동할 수 있다', () {
    final engine = createEngine();
    final officer = engine.state.provinces.first.officerIds.first;
    expect(engine.moveOfficer(officer, 'p_briar'), isTrue);
    expect(engine.state.provinces.first.officerIds, isNot(contains(officer)));
    expect(engine.state.provinces[1].officerIds, contains(officer));
  });

  test('저장 데이터에 버전과 결정성 seed가 포함된다', () {
    final state = createEngine().state;
    state.playerForce.gold = 1234;
    final decoded = SaveRepository().decode(SaveRepository().encode(state));
    expect(decoded['saveVersion'], 1);
    expect(decoded['randomSeed'], 42);
    expect(decoded['relations']['force_red'], -10);
    expect(decoded['revealedProvinceIds'], isEmpty);
    final restored = GameState.fromSaveMap(decoded);
    expect(restored.playerForce.gold, 1234);
    expect(restored.provinces.length, 12);
    expect(restored.officers.length, 20);
    expect(restored.forces.first.mapColorValue, 0xff267d70);
    expect(restored.forces[1].bannerIndex, 1);
    expect(restored.provinces.first.floodControl, 25);
  });

  test('첩보는 적 영지 정보를 공개하고 장수 충성도와 민심을 낮춘다', () {
    final engine = createEngine();
    final actor = engine.state.playerForce.officerIds.first;
    final target = engine.state.provinces.firstWhere((p) => p.id == 'p_crown');
    final enemyOfficer = target.officerIds.first;
    final loyaltyBefore = engine.state.officers
        .firstWhere((o) => o.id == enemyOfficer)
        .loyalty;
    final publicLoyaltyBefore = target.publicLoyalty;

    expect(engine.infiltrate(target.id, actor).success, isTrue);
    expect(engine.state.revealedProvinceIds, contains(target.id));
    expect(engine.inciteOfficer(enemyOfficer, actor).success, isTrue);
    expect(
      engine.state.officers.firstWhere((o) => o.id == enemyOfficer).loyalty,
      lessThan(loyaltyBefore),
    );
    expect(engine.spreadRumor(target.id, actor).success, isTrue);
    expect(target.publicLoyalty, lessThan(publicLoyaltyBefore));
  });

  test('외교는 선물로 관계를 높이고 동맹을 맺을 수 있다', () {
    final engine = createEngine();
    final officer = engine.state.playerForce.officerIds.first;
    expect(engine.state.relationTo('force_red'), -10);
    expect(engine.giftForce('force_red', officer).success, isTrue);
    expect(engine.state.relationTo('force_red'), greaterThan(-10));
    engine.state.setRelation('force_red', 25);
    expect(engine.formAlliance('force_red', officer).success, isTrue);
    expect(engine.state.alliedForceIds, contains('force_red'));
  });

  test('협박은 관계를 낮추고 기존 동맹을 해제한다', () {
    final engine = createEngine();
    final officer = engine.state.playerForce.officerIds.first;
    engine.state.setRelation('force_blue', 40);
    engine.state.alliedForceIds.add('force_blue');
    expect(engine.threatenForce('force_blue', officer).success, isTrue);
    expect(engine.state.relationTo('force_blue'), 20);
    expect(engine.state.alliedForceIds, isNot(contains('force_blue')));
  });

  test('선택한 세력에 따라 내 영지가 바뀐다', () {
    final state = GameState.fromScenario(
      DemoScenario.create(),
      selectedForceId: 'force_red',
    );
    expect(state.playerForce.name, '붉은 왕좌');
    expect(state.playerProvinceIds, ['p_crown', 'p_dale', 'p_west', 'p_south']);
    expect(state.playerSoldiers, 6240);
  });

  test('출병과 전투 승리는 영토 소유권을 바꾼다', () {
    final engine = createEngine();
    engine.state.provinces.firstWhere((p) => p.id == 'p_crown').soldiers = 100;
    final battle = engine.beginBattle('p_crown');
    expect(battle, isNotNull);
    while (!battle!.state.finished) {
      battle.attack();
    }
    engine.resolveBattle(battle);
    expect(engine.state.playerProvinceIds, contains('p_crown'));
    expect(
      engine.state.provinces.firstWhere((p) => p.id == 'p_crown').ownerForceId,
      'force_green',
    );
    expect(battle.state.outcomes, isNotEmpty);
  });

  test('전투 패배와 퇴각 시 살아남은 병력이 출발지로 귀환한다', () {
    final engine = createEngine();
    final source = engine.state.provinces.firstWhere((p) => p.id == 'p_briar');
    final before = source.soldiers;
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: source.id,
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    battle!.retreat();
    engine.resolveBattle(battle);
    expect(source.soldiers, before);
    expect(battle.state.returnedSoldiers, greaterThan(0));
    expect(battle.state.returnProvinceId, source.id);
  });

  test('승리 시 잔여 병력이 점령지에 주둔한다', () {
    final engine = createEngine();
    final target = engine.state.provinces.firstWhere((p) => p.id == 'p_crown');
    target.soldiers = 100;
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: target.id,
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    while (!battle!.state.finished) {
      battle.attack();
    }
    engine.resolveBattle(battle);
    expect(target.ownerForceId, engine.state.playerForceId);
    expect(target.soldiers, battle.state.returnedSoldiers);
    expect(battle.state.returnProvinceId, target.id);
  });

  test('전투 결과는 포로를 기록하고 석방 처리할 수 있다', () {
    final engine = createEngine();
    final target = engine.state.provinces.firstWhere((p) => p.id == 'p_crown');
    target.soldiers = 100;
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: target.id,
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    while (!battle!.state.finished) {
      battle.attack();
    }
    final outcomes = engine.resolveBattle(battle);
    final prisoner = outcomes
        .where((o) => o.result == BattleOfficerResult.captured)
        .firstOrNull;
    expect(prisoner, isNotNull);
    expect(
      engine.handlePrisoner(
        prisoner!.officerId,
        PrisonerAction.release,
        target.id,
      ),
      isTrue,
    );
    expect(
      engine.state.officers
          .firstWhere((o) => o.id == prisoner.officerId)
          .status,
      'FREE',
    );
  });

  test('내정 명령은 금과 민심을 서로 다른 방향으로 바꾼다', () {
    final engine = createEngine();
    final province = engine.state.provinces.first;
    final gold = engine.state.playerForce.gold;
    engine.tax(province.id);
    expect(engine.state.playerForce.gold, greaterThan(gold));
    engine.relief(province.id);
    expect(province.publicLoyalty, 67);
  });

  test('장수는 한 달에 한 번만 명령을 수행한다', () {
    final engine = createEngine();
    final province = engine.state.provinces.first;
    final officer = province.officerIds.first;
    final first = engine.dispatch(
      GameCommand(
        type: GameCommandType.develop,
        officerId: officer,
        provinceId: province.id,
      ),
    );
    final second = engine.dispatch(
      GameCommand(
        type: GameCommandType.tax,
        officerId: officer,
        provinceId: province.id,
      ),
    );
    expect(first.success, isTrue);
    expect(second.success, isFalse);
    expect(second.message, contains('이미 명령'));
  });

  test('탐색과 등용은 재야 장수를 세력에 편입한다', () {
    final engine = createEngine();
    final province = engine.state.provinces.first;
    final officer = province.officerIds.first;
    final found = engine.dispatch(
      GameCommand(
        type: GameCommandType.search,
        officerId: officer,
        provinceId: province.id,
      ),
    );
    expect(found.success, isTrue);
    final freeId = engine.firstFreeOfficer!.id;
    final recruit = engine.recruitOfficer(freeId, province.id);
    expect(recruit.success, isTrue);
    expect(engine.state.playerForce.officerIds, contains(freeId));
    expect(province.officerIds, contains(freeId));
  });

  test('장수를 태수로 임명하면 지역에 태수 정보가 기록된다', () {
    final engine = createEngine();
    final province = engine.state.provinces.first;
    final officer = province.officerIds.first;
    final result = engine.dispatch(
      GameCommand(
        type: GameCommandType.appointGovernor,
        officerId: officer,
        provinceId: province.id,
      ),
    );
    expect(result.success, isTrue);
    expect(province.governorId, officer);
  });

  test('이동 명령은 인접 아군 지역으로 장수와 소속 지역을 함께 옮긴다', () {
    final engine = createEngine();
    final source = engine.state.provinces.firstWhere((p) => p.id == 'p_briar');
    final officer = source.officerIds.first;
    final result = engine.dispatch(
      GameCommand(
        type: GameCommandType.moveOfficer,
        officerId: officer,
        provinceId: source.id,
        destinationProvinceId: 'p_ash',
      ),
    );
    expect(result.success, isTrue);
    expect(source.officerIds, isNot(contains(officer)));
    expect(
      engine.state.officers.firstWhere((o) => o.id == officer).provinceId,
      'p_ash',
    );
  });

  test('출병 준비는 선택한 출발지 병력과 군량을 실제로 차감한다', () {
    final engine = createEngine();
    final source = engine.state.provinces.firstWhere((p) => p.id == 'p_briar');
    final soldiers = source.soldiers;
    final food = engine.state.playerForce.food;
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: source.id,
      targetProvinceId: 'p_crown',
      committedSoldiers: 500,
    );
    expect(battle, isNotNull);
    expect(source.soldiers, soldiers - 500);
    expect(engine.state.playerForce.food, food - 150);
  });

  test('출병 준비는 여러 장수의 부대와 총대장을 전투 상태에 기록한다', () {
    final engine = createEngine();
    final source = engine.state.provinces.firstWhere((p) => p.id == 'p_briar');
    final participants = source.officerIds.take(2).toList();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: source.id,
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
      participantOfficerIds: participants,
      commanderOfficerId: participants[1],
    );
    expect(battle, isNotNull);
    expect(battle!.state.attackerUnits.length, 2);
    expect(
      battle.state.attackerUnits.fold(0, (sum, unit) => sum + unit.soldiers),
      600,
    );
    expect(
      battle.state.commanderName,
      engine.state.officers.firstWhere((o) => o.id == participants[1]).name,
    );
  });

  test('전투 행동은 선택한 부대에 따라 피해와 병력을 갱신한다', () {
    final engine = createEngine();
    final source = engine.state.provinces.firstWhere((p) => p.id == 'p_briar');
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: source.id,
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
      participantOfficerIds: source.officerIds.take(2).toList(),
    );
    expect(battle, isNotNull);
    final target = battle!.state.defenderUnits.first;
    final before = target.soldiers;
    battle.act(
      attackerId: battle.state.attackerUnits.first.officerId,
      defenderId: target.officerId,
      action: BattleAction.fire,
    );
    expect(target.soldiers, lessThan(before));
    expect(battle.state.defenderSoldiers, lessThan(1140));
  });

  test('협공과 정보전은 전투 상태를 갱신한다', () {
    final engine = createEngine();
    final source = engine.state.provinces.firstWhere((p) => p.id == 'p_briar');
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: source.id,
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
      participantOfficerIds: source.officerIds.take(2).toList(),
    );
    expect(battle, isNotNull);
    final target = battle!.state.defenderUnits.first;
    battle.act(
      attackerId: battle.state.attackerUnits.first.officerId,
      defenderId: target.officerId,
      action: BattleAction.information,
    );
    expect(battle.state.informationRevealed, isTrue);
    battle.act(
      attackerId: battle.state.attackerUnits.first.officerId,
      defenderId: target.officerId,
      action: BattleAction.cooperate,
    );
    expect(battle.state.defenderSoldiers, lessThan(1140));
  });

  test('화공은 화재와 사기 저하를 남긴다', () {
    final engine = createEngine();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    final target = battle!.state.defenderUnits.first;
    final moraleBefore = battle.state.defenderMorale;
    battle.act(
      attackerId: battle.state.attackerUnits.first.officerId,
      defenderId: target.officerId,
      action: BattleAction.fire,
    );
    expect(target.burning, isTrue);
    expect(battle.state.defenderMorale, lessThan(moraleBefore));
  });

  test('AI 월별 시뮬레이션은 장기 진행 중 음수 자원을 만들지 않는다', () {
    final engine = createEngine();
    for (var i = 0; i < 1000 && !engine.state.gameOver; i++) {
      engine.endTurn();
      for (final force in engine.state.forces) {
        expect(force.gold, greaterThanOrEqualTo(0));
        expect(force.food, greaterThanOrEqualTo(0));
      }
      for (final province in engine.state.provinces) {
        expect(province.soldiers, greaterThanOrEqualTo(0));
        expect(province.publicLoyalty, inInclusiveRange(0, 100));
      }
    }
  });

  test('전투는 매일 군량을 소모하고 보급 부족 시 사기를 낮춘다', () {
    final engine = createEngine();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    battle!.state.attackerFood = 0;
    final moraleBefore = battle.state.attackerMorale;
    battle.attack();
    expect(battle.state.attackerFood, 0);
    expect(battle.state.attackerMorale, lessThan(moraleBefore));
    expect(battle.state.supplyShortageDays, 1);
  });

  test('보급 부족이 3일 지속되면 공격군이 패배한다', () {
    final engine = createEngine();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    battle!.state.attackerFood = 0;
    while (!battle.state.finished && battle.state.supplyShortageDays < 3) {
      battle.attack();
    }
    expect(battle.state.finished, isTrue);
    expect(battle.state.winner, 'defender');
  });

  test('전투 부대는 한 칸씩만 이동하고 점유 칸으로 이동할 수 없다', () {
    final engine = createEngine();
    final source = engine.state.provinces.firstWhere((p) => p.id == 'p_briar');
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: source.id,
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
      participantOfficerIds: source.officerIds.take(2).toList(),
    );
    expect(battle, isNotNull);
    final unit = battle!.state.attackerUnits.first;
    final originalRow = unit.row;
    final originalColumn = unit.column;
    expect(
      battle.moveUnit(unit.officerId, originalRow - 1, originalColumn),
      isTrue,
    );
    expect(
      battle.moveUnit(unit.officerId, originalRow - 3, originalColumn),
      isFalse,
    );
  });
}
