import 'package:flutter/material.dart';

import '../../battle/battle_engine.dart';
import '../../battle/battle_state.dart';
import '../../battle/terrain.dart';

class BattleTopHud extends StatelessWidget {
  const BattleTopHud({super.key, required this.battle});
  final BattleState battle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
    decoration: const BoxDecoration(
      color: Color(0xff171612),
      border: Border(bottom: BorderSide(color: Color(0xff9c743b))),
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
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: _box(const Color(0xff332b20)),
          child: Column(
            children: [
              const Text(
                '전투',
                style: TextStyle(color: Color(0xfff0d49d), fontSize: 11),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: _box(color),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '${_format(soldiers)}명',
          style: const TextStyle(color: Color(0xffffe6b0), fontSize: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xff171612),
        border: Border(
          top: BorderSide(color: Color(0xff9c743b)),
          bottom: BorderSide(color: Color(0xff4f402a)),
        ),
      ),
      child: Row(
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
    );
  }

  Widget _stat(String label, String value, {bool warning = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xffb99a65), fontSize: 10),
      ),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: warning ? const Color(0xffe98d72) : const Color(0xffffe8b4),
          fontSize: 11,
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
    required this.onMove,
    required this.onAction,
    required this.onRetreat,
    required this.onInfo,
  });
  final bool disabled;
  final VoidCallback onMove;
  final void Function(BattleAction action) onAction;
  final VoidCallback onRetreat;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
    color: const Color(0xff100e0b),
    child: Row(
      children: [
        _button('이동', Icons.directions_run, disabled ? null : onMove),
        _button(
          '공격',
          Icons.gavel,
          disabled ? null : () => onAction(BattleAction.attack),
          selected: true,
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
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
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
            Icon(icon, size: 16),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ),
  );
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

String _format(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
