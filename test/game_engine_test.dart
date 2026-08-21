import 'package:flutter_test/flutter_test.dart';
import 'package:codex_strategy/core/game_engine.dart';
import 'package:codex_strategy/core/game_command.dart';
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
    expect(engine.state.gameLog.last, contains('월말 정산'));
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
    final decoded = SaveRepository().decode(SaveRepository().encode(state));
    expect(decoded['saveVersion'], 1);
    expect(decoded['randomSeed'], 42);
  });

  test('선택한 세력에 따라 내 영지가 바뀐다', () {
    final state = GameState.fromScenario(
      DemoScenario.create(),
      selectedForceId: 'force_red',
    );
    expect(state.playerForce.name, '붉은 왕좌');
    expect(state.playerProvinceIds, ['p_crown', 'p_dale']);
    expect(state.playerSoldiers, 2400);
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
    final source = engine.state.provinces.first;
    final officer = source.officerIds.first;
    final result = engine.dispatch(
      GameCommand(
        type: GameCommandType.moveOfficer,
        officerId: officer,
        provinceId: source.id,
        destinationProvinceId: 'p_briar',
      ),
    );
    expect(result.success, isTrue);
    expect(source.officerIds, isNot(contains(officer)));
    expect(
      engine.state.officers.firstWhere((o) => o.id == officer).provinceId,
      'p_briar',
    );
  });
}
