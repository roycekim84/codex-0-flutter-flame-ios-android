import 'package:flutter/material.dart';

import '../../battle/battle_engine.dart';
import '../../battle/battle_state.dart';
import '../../battle/terrain.dart';
import '../../core/asset_repository.dart';

class BattleTopHud extends StatelessWidget {
  const BattleTopHud({super.key, required this.battle});
  final BattleState battle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: BoxDecoration(
      color: const Color(0xff171612),
      image: DecorationImage(
        image: AssetImage(AssetRepository.panelTexture),
        fit: BoxFit.cover,
        opacity: .18,
      ),
      border: const Border(bottom: BorderSide(color: Color(0xffc0924b))),
    ),
    child: Row(
      children: [
        Expanded(
          child: _forceCard(
            battle.attackerName,
            battle.attackerSoldiers,
            const Color(0xff28527a),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 74,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: _box(const Color(0xff332b20)),
          child: Column(
            children: [
              Text(
                battle.phaseLabel,
                style: TextStyle(
                  color: battle.isAttackerTurn
                      ? const Color(0xfff0d49d)
                      : const Color(0xffe58d7b),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${battle.day}일째',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _forceCard(
            battle.defenderName,
            battle.defenderSoldiers,
            const Color(0xff71372e),
          ),
        ),
      ],
    ),
  );

  Widget _forceCard(String name, int soldiers, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: _box(color),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xfffff0d0),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        Text(
          '${_format(soldiers)}명',
          style: const TextStyle(color: Color(0xffffe6b0), fontSize: 13),
        ),
      ],
    ),
  );
}

class BattleInfoPanel extends StatelessWidget {
  const BattleInfoPanel({super.key, required this.battle});
  final BattleState battle;

  @override
  Widget build(BuildContext context) {
    final shortage = battle.supplyShortageDays > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xff171612),
        image: DecorationImage(
          image: AssetImage(AssetRepository.panelTexture),
          fit: BoxFit.cover,
          opacity: .14,
        ),
        border: const Border(
          top: BorderSide(color: Color(0xff9c743b)),
          bottom: BorderSide(color: Color(0xff4f402a)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _stat('지형', _terrainLabel(battle.terrain))),
              Expanded(child: _stat('날씨', '맑음')),
              Expanded(
                child: _stat(
                  '군량',
                  '${_format(battle.attackerFood)} / ${_format(battle.dailySupplyCost)}',
                ),
              ),
              Expanded(
                child: _stat(
                  '사기',
                  '${battle.attackerMorale} / ${battle.defenderMorale}',
                  warning: shortage,
                ),
              ),
            ],
          ),
          if (battle.selectedAttacker != null) ...[
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '선택 ${battle.selectedAttacker!.name} · 이동 ${battle.movementCells.length}칸 · 공격 ${battle.attackCells.length}칸'
                '${battle.expectedDamage == null ? '' : ' · 예상 피해 ${_format(battle.expectedDamage!)}'}',
                style: const TextStyle(color: Color(0xffd8bd89), fontSize: 10),
              ),
            ),
          ],
          if (battle.selectedAttacker != null ||
              battle.selectedDefender != null) ...[
            const SizedBox(height: 6),
            _selectionStrip(battle),
          ],
        ],
      ),
    );
  }

  Widget _selectionStrip(BattleState battle) {
    final attacker = battle.selectedAttacker;
    final defender = battle.selectedDefender;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xff211b13),
        border: Border.all(color: const Color(0xff70552d)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Expanded(
            child: _unitSummary(
              attacker,
              label: '아군',
              color: const Color(0xff8dbbe1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                Text(
                  defender == null ? '선택' : 'VS',
                  style: const TextStyle(
                    color: Color(0xffc9a76b),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (battle.expectedDamage != null)
                  Text(
                    '피해 ${_format(battle.expectedDamage!)}',
                    style: const TextStyle(
                      color: Color(0xffffc46b),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _unitSummary(
              defender,
              label: '적군',
              color: const Color(0xffdf9686),
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitSummary(
    BattleUnit? unit, {
    required String label,
    required Color color,
    bool alignEnd = false,
  }) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        unit == null ? '$label · 대상 미선택' : '$label · ${unit.name}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (unit != null)
        Text(
          '${_unitTypeLabel(unit.type)} · ${_format(unit.soldiers)}명',
          style: const TextStyle(color: Color(0xffe0c99d), fontSize: 10),
        ),
    ],
  );

  Widget _stat(String label, String value, {bool warning = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xffb99a65), fontSize: 11),
      ),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: warning ? const Color(0xffe98d72) : const Color(0xffffe8b4),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class BattleCommandBar extends StatelessWidget {
  const BattleCommandBar({
    super.key,
    required this.disabled,
    required this.turnLabel,
    required this.onMove,
    required this.onAction,
    required this.onRetreat,
    required this.onInfo,
    required this.onEndTurn,
  });
  final bool disabled;
  final String turnLabel;
  final VoidCallback onMove;
  final void Function(BattleAction action) onAction;
  final VoidCallback onRetreat;
  final VoidCallback onInfo;
  final VoidCallback onEndTurn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
    decoration: BoxDecoration(
      color: const Color(0xff100e0b),
      image: DecorationImage(
        image: AssetImage(AssetRepository.panelTexture),
        fit: BoxFit.cover,
        opacity: .12,
      ),
      border: const Border(top: BorderSide(color: Color(0xff9c743b))),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$turnLabel · 부대별 1회 행동',
                style: TextStyle(
                  color: Color(0xffe8c98f),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: disabled ? null : onEndTurn,
              icon: const Icon(Icons.hourglass_bottom, size: 16),
              label: const Text('턴 종료'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                foregroundColor: const Color(0xffffe5ad),
                side: const BorderSide(color: Color(0xffb38343)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _button('이동', Icons.directions_run, disabled ? null : onMove),
            _button(
              '공격',
              Icons.gavel,
              disabled ? null : () => onAction(BattleAction.attack),
            ),
            _button(
              '책략',
              Icons.local_fire_department,
              disabled ? null : () => onAction(BattleAction.fire),
            ),
            _button('정보', Icons.visibility, disabled ? null : onInfo),
            _button(
              '대기',
              Icons.pause,
              disabled ? null : () => onAction(BattleAction.wait),
            ),
            _button('퇴각', Icons.undo, disabled ? null : onRetreat),
          ],
        ),
      ],
    ),
  );

  Widget _button(
    String label,
    IconData icon,
    VoidCallback? onPressed, {
    bool selected = false,
  }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          backgroundColor: selected
              ? const Color(0xff314d65)
              : const Color(0xff241e16),
          foregroundColor: const Color(0xffffe5ad),
          side: BorderSide(
            color: selected ? const Color(0xffc59a52) : const Color(0xff74572f),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    ),
  );
}

class BattleLogPanel extends StatelessWidget {
  const BattleLogPanel({super.key, required this.battle});
  final BattleState battle;

  @override
  Widget build(BuildContext context) {
    final logs = battle.battleLog.reversed.take(4).toList().reversed.toList();
    return Container(
      constraints: const BoxConstraints(minHeight: 32, maxHeight: 74),
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      decoration: const BoxDecoration(
        color: Color(0xff100e0b),
        border: Border(top: BorderSide(color: Color(0xff4f402a))),
      ),
      child: logs.isEmpty
          ? const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '전투 기록이 없습니다.',
                style: TextStyle(color: Color(0xff9d8967), fontSize: 10),
              ),
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: logs
                  .map(
                    (log) => Text(
                      log,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xffcdb58a),
                        fontSize: 10,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

BoxDecoration _box(Color color) => BoxDecoration(
  color: color,
  border: Border.all(color: const Color(0xffa47a3e)),
  borderRadius: BorderRadius.circular(3),
);

String _terrainLabel(TerrainType terrain) => switch (terrain) {
  TerrainType.plain => '평원',
  TerrainType.forest => '숲',
  TerrainType.mountain => '산악',
  TerrainType.river => '강',
  TerrainType.fort => '성채',
};

String _unitTypeLabel(BattleUnitType type) => switch (type) {
  BattleUnitType.infantry => '보병',
  BattleUnitType.cavalry => '기병',
  BattleUnitType.archers => '궁병',
};

String _format(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
