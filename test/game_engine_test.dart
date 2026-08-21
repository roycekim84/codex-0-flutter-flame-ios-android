import 'package:flutter_test/flutter_test.dart';
import 'package:codex_strategy/core/game_engine.dart';
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
}
