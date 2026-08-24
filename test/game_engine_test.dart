import 'package:flutter_test/flutter_test.dart';
import 'package:codex_strategy/core/game_engine.dart';
import 'package:codex_strategy/core/game_command.dart';
import 'package:codex_strategy/battle/battle_engine.dart';
import 'package:codex_strategy/battle/battle_command.dart';
import 'package:codex_strategy/battle/battle_state.dart';
import 'package:codex_strategy/data/demo_scenario.dart';
import 'package:codex_strategy/models/game_state.dart';
import 'package:codex_strategy/repositories/save_repository.dart';
import 'package:codex_strategy/core/asset_repository.dart';

void main() {
  GameEngine createEngine() =>
      GameEngine(GameState.fromScenario(DemoScenario.create()));

  test('전투 렌더러는 투명 부대 스프라이트와 공용 레이어를 사용한다', () {
    expect(
      AssetRepository.battleRendererAssets,
      contains(AssetRepository.battleUnitTokenAlpha),
    );
    expect(
      AssetRepository.flameKey(AssetRepository.battleEffectsStrip),
      'battle_effects_strip.png',
    );
    expect(
      AssetRepository.battleRendererAssets,
      isNot(contains(AssetRepository.battleUnitToken)),
    );
  });

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
      engine.state.gameLog.any((log) => log.contains('AI · 가시 전술 전투 승리')),
      isTrue,
    );
    expect(engine.state.lastTurnReports, hasLength(1));
    expect(engine.state.lastTurnReports.first.targetProvinceName, '가시');
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

  test('군량 구매와 판매는 금·군량을 실제로 교환한다', () {
    final engine = createEngine();
    final province = engine.state.playerForce.provinceIds
        .map((id) => engine.state.provinces.firstWhere((p) => p.id == id))
        .first;
    final goldBefore = engine.state.playerForce.gold;
    final foodBefore = province.food;
    expect(engine.buyFood(province.id, 100).success, isTrue);
    expect(province.food, foodBefore + 100);
    expect(engine.state.playerForce.gold, goldBefore - 90);
    expect(engine.sellFood(province.id, 50).success, isTrue);
    expect(province.food, foodBefore + 50);
    expect(engine.state.playerForce.gold, goldBefore - 45);
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
    final support = battle.state.attackerUnits[1];
    battle.act(
      attackerId: support.officerId,
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
    final soldiersAfterFire = target.soldiers;

    battle.endTurn();
    expect(battle.state.day, 2);
    expect(target.soldiers, lessThan(soldiersAfterFire));
  });

  test('전술 행동은 각각 실행되고 전투 종료 상태를 반영한다', () {
    final state = BattleState(
      sourceProvinceId: 'source',
      targetProvinceId: 'target',
      attackerName: '아군',
      defenderName: '적군',
      attackerSoldiers: 1000,
      defenderSoldiers: 1000,
      attackerFood: 5000,
      attackerUnits: [
        BattleUnit(
          officerId: 'a1',
          name: '돌격대',
          soldiers: 500,
          war: 80,
          intelligence: 50,
          row: 2,
          column: 1,
        ),
        BattleUnit(
          officerId: 'a2',
          name: '책사',
          soldiers: 500,
          war: 50,
          intelligence: 90,
          row: 2,
          column: 2,
        ),
      ],
      defenderUnits: [
        BattleUnit(
          officerId: 'd1',
          name: '수비대',
          soldiers: 1000,
          war: 60,
          intelligence: 60,
          row: 1,
          column: 2,
        ),
      ],
    );
    final battle = BattleEngine(state);

    final fire = battle.act(
      attackerId: 'a2',
      defenderId: 'd1',
      action: BattleAction.fire,
    );
    expect(fire.fireApplied, isTrue);
    expect(state.defenderMorale, 92);

    final charge = battle.act(
      attackerId: 'a1',
      defenderId: 'd1',
      action: BattleAction.charge,
    );
    expect(charge.damage, greaterThan(0));
    expect(state.battleLog, hasLength(2));
    expect(state.finished, isFalse);
  });

  test('전술 공격으로 병력이 0이 되면 즉시 승패를 확정한다', () {
    final winState = BattleState(
      sourceProvinceId: 'source',
      targetProvinceId: 'target',
      attackerName: '아군',
      defenderName: '적군',
      attackerSoldiers: 1000,
      defenderSoldiers: 1,
      attackerUnits: [
        BattleUnit(
          officerId: 'a1',
          name: '공격대',
          soldiers: 1000,
          war: 80,
          intelligence: 50,
          row: 2,
          column: 1,
        ),
      ],
      defenderUnits: [
        BattleUnit(
          officerId: 'd1',
          name: '수비대',
          soldiers: 1,
          war: 50,
          intelligence: 50,
          row: 1,
          column: 2,
        ),
      ],
    );
    final win = BattleEngine(
      winState,
    ).act(attackerId: 'a1', defenderId: 'd1', action: BattleAction.attack);
    expect(win.finished, isTrue);
    expect(win.winner, 'attacker');
    expect(winState.finishReason, '적군 전멸');

    final retreatState = BattleState(
      sourceProvinceId: 'source',
      targetProvinceId: 'target',
      attackerName: '아군',
      defenderName: '적군',
      attackerSoldiers: 100,
      defenderSoldiers: 100,
    );
    final retreat = BattleEngine(retreatState).retreat();
    expect(retreat.finished, isTrue);
    expect(retreat.winner, 'defender');
    expect(retreatState.finishReason, '공격군의 자발적 퇴각');
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
    expect(battle.state.finishReason, '보급 고갈');
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

  test('육각 격자는 동·서와 네 대각선 방향으로 이동한다', () {
    final unit = BattleUnit(
      officerId: 'test',
      name: '테스트 부대',
      soldiers: 100,
      war: 50,
      intelligence: 50,
      row: 3,
      column: 2,
    );
    final state = BattleState(
      sourceProvinceId: 'source',
      targetProvinceId: 'target',
      attackerName: '아군',
      defenderName: '적군',
      attackerSoldiers: 100,
      defenderSoldiers: 100,
      attackerUnits: [unit],
    );

    expect(state.isAdjacent(unit, 3, 3), isTrue); // 동
    expect(state.isAdjacent(unit, 2, 3), isTrue); // 북동
    expect(state.isAdjacent(unit, 4, 2), isTrue); // 남동
    expect(state.isAdjacent(unit, 3, 1), isTrue); // 서
    expect(state.isAdjacent(unit, 4, 1), isTrue); // 남서
    expect(state.isAdjacent(unit, 2, 2), isTrue); // 북서
    expect(state.isAdjacent(unit, 3, 2), isFalse); // 북·남은 없음
  });

  test('B0 전투 명령은 선택 상태와 이동 가능 칸을 갱신한다', () {
    final engine = createEngine();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    final unit = battle!.state.attackerUnits.first;

    final selection = battle.execute(
      BattleCommand.selectAttacker(unit.officerId),
    );
    expect(selection.hasEffect, isFalse);
    expect(battle.state.selectedAttackerId, unit.officerId);
    expect(battle.state.movementCells, isNotEmpty);
    expect(
      battle.state.movementCells,
      contains(BattleCell(unit.row - 1, unit.column)),
    );
  });

  test('B0 행동 명령은 BattleResultEvent로 연출 데이터를 반환한다', () {
    final engine = createEngine();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    final attacker = battle!.state.attackerUnits.first;
    final defender = battle.state.defenderUnits.first;
    attacker.row = defender.row;
    attacker.column = defender.column - 1;

    final event = battle.execute(
      BattleCommand.action(
        type: BattleCommandType.fire,
        attackerId: attacker.officerId,
        defenderId: defender.officerId,
      ),
    );

    expect(event.command.type, BattleCommandType.fire);
    expect(event.damage, greaterThan(0));
    expect(event.fireApplied, isTrue);
    expect(event.moraleDelta, lessThan(0));
    expect(event.logMessage, isNotEmpty);
    expect(event.logMessage, contains('→'));
    expect(event.logMessage, contains('피해'));
    expect(defender.burning, isTrue);
  });

  test('전투 명령은 비인접 공격과 적군 턴 이동을 거부한다', () {
    final engine = createEngine();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    final current = battle!;
    final attacker = current.state.attackerUnits.first;
    final defender = current.state.defenderUnits.first;
    final invalidAttack = current.execute(
      BattleCommand.action(
        type: BattleCommandType.attack,
        attackerId: attacker.officerId,
        defenderId: defender.officerId,
      ),
    );
    expect(invalidAttack.logMessage, contains('인접한 적'));

    current.state.turnPhase = BattleTurnPhase.defender;
    expect(
      current.moveUnit(attacker.officerId, attacker.row, attacker.column + 1),
      isFalse,
    );
  });

  test('대기는 적 부대 선택 없이도 해당 부대의 행동을 소비한다', () {
    final engine = createEngine();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    final current = battle!;
    final attacker = current.state.attackerUnits.first;
    final event = current.execute(
      BattleCommand.action(
        type: BattleCommandType.wait,
        attackerId: attacker.officerId,
      ),
    );

    expect(event.logMessage, contains('대기'));
    expect(current.state.actedUnitIds, contains(attacker.officerId));
    expect(event.damage, 0);
  });

  test('B4 선택 명령은 범위와 예상 피해를 제공하고 잘못된 선택을 거부한다', () {
    final engine = createEngine();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    final attacker = battle!.state.attackerUnits.first;
    final defender = battle.state.defenderUnits.first;
    attacker.row = defender.row;
    attacker.column = defender.column - 1;

    final invalid = battle.execute(
      const BattleCommand.selectAttacker('missing'),
    );
    expect(invalid.logMessage, isNotEmpty);
    battle.execute(BattleCommand.selectAttacker(attacker.officerId));
    battle.execute(BattleCommand.selectDefender(defender.officerId));
    expect(battle.state.movementCells, isNotEmpty);
    expect(battle.state.expectedDamage, isNotNull);
    expect(battle.state.expectedDamage, greaterThan(0));

    battle.execute(const BattleCommand.clearSelection());
    expect(battle.state.selectedAttacker, isNull);
    expect(battle.state.selectedDefender, isNull);
  });

  test('B6 전투 행동은 최근 전투 로그를 남긴다', () {
    final engine = createEngine();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    final attacker = battle!.state.attackerUnits.first;
    final defender = battle.state.defenderUnits.first;
    attacker.row = defender.row;
    attacker.column = defender.column - 1;
    battle.execute(BattleCommand.selectAttacker(attacker.officerId));
    battle.execute(BattleCommand.selectDefender(defender.officerId));
    final event = battle.execute(
      BattleCommand.action(
        type: BattleCommandType.fire,
        attackerId: attacker.officerId,
        defenderId: defender.officerId,
      ),
    );
    expect(event.logMessage, contains('화공'));
    expect(battle.state.battleLog, hasLength(1));
    expect(battle.state.battleLog.single, contains('화공'));
  });

  test('전투는 아군 행동과 적군 AI 턴을 거쳐 다음 날로 진행된다', () {
    final engine = createEngine();
    final battle = engine.beginBattlePrepared(
      sourceProvinceId: 'p_briar',
      targetProvinceId: 'p_crown',
      committedSoldiers: 600,
    );
    expect(battle, isNotNull);
    final current = battle!;
    final attacker = current.state.attackerUnits.first;
    final defender = current.state.defenderUnits.first;
    attacker.row = defender.row;
    attacker.column = defender.column - 1;
    current.execute(BattleCommand.selectAttacker(attacker.officerId));
    current.execute(BattleCommand.selectDefender(defender.officerId));
    current.execute(
      BattleCommand.action(
        type: BattleCommandType.attack,
        attackerId: attacker.officerId,
        defenderId: defender.officerId,
      ),
    );
    expect(current.state.day, 1);
    expect(current.state.actedUnitIds, contains(attacker.officerId));

    final end = current.execute(const BattleCommand.endTurn());
    expect(end.logMessage, contains('적군 턴'));
    expect(current.state.day, 2);
    expect(current.state.turnPhase, BattleTurnPhase.attacker);
    expect(current.state.actedUnitIds, isEmpty);
  });
}
