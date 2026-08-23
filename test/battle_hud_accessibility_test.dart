import 'package:codex_strategy/battle/battle_state.dart';
import 'package:codex_strategy/ui/battle/battle_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('전투 HUD는 작은 세로 화면과 큰 글자에서도 예외 없이 렌더링된다', (tester) async {
    final battle =
        BattleState(
            sourceProvinceId: 'source',
            targetProvinceId: 'target',
            attackerName: '푸른 연맹',
            defenderName: '적대 세력',
            attackerSoldiers: 11_000,
            defenderSoldiers: 9_000,
            attackerFood: 23_000,
            dailySupplyCost: 500,
          )
          ..battleLog.addAll([
            '[1일째] 조조 → 적장 · 화공 · 피해 1,250 · 아군 손실 96 · 적 사기 -8',
            '[1일째] 하후돈 → 적장 · 협공 · 피해 860 · 아군 손실 42',
            '[1일째] 정보전 실행 · 정보 확보',
            '[1일째] 적군 턴 종료 · 반격 피해 310',
          ]);

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    for (final size in const [Size(375, 812), Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    BattleTopHud(battle: battle),
                    BattleInfoPanel(battle: battle),
                    BattleLogPanel(battle: battle),
                    BattleCommandBar(
                      disabled: false,
                      turnLabel: battle.phaseLabel,
                      onMove: () {},
                      onAction: (_) {},
                      onRetreat: () {},
                      onInfo: () {},
                      onEndTurn: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '뷰포트 $size 렌더링 실패');
      expect(find.text('전투 기록이 없습니다.'), findsNothing);
      expect(find.text('턴 종료'), findsOneWidget);
    }
  });
}
