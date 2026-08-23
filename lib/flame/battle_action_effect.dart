import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../battle/battle_command.dart';
import '../battle/battle_state.dart';
import '../battle/battle_map.dart';

class BattleActionEffectComponent extends PositionComponent {
  BattleActionEffectComponent({
    required this.battle,
    required this.event,
    required this.onComplete,
  }) : super(
         position: BattleMapLayout.mapOffset,
         size: Vector2(BattleMapLayout.boardWidth, BattleMapLayout.boardHeight),
       );

  final BattleState battle;
  final BattleResultEvent event;
  final VoidCallback onComplete;
  double elapsed = 0;
  static const duration = .72;

  @override
  Future<void> onLoad() async {
    if (event.damage > 0) {
      add(
        TextComponent(
          text: '-${event.damage}',
          position: Vector2(195, 260),
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              color: event.fireApplied
                  ? const Color(0xffffc05c)
                  : const Color(0xfffff0c6),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
            ),
          ),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    elapsed += dt;
    if (elapsed >= duration) {
      onComplete();
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final progress = (elapsed / duration).clamp(0.0, 1.0);
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final attacker = _center(event.attackerId, true);
    final defender = _center(event.defenderId, false);
    final action = event.command.type;

    if (action == BattleCommandType.fire) {
      final paint = Paint()
        ..color = const Color(0xffff7b22).withValues(alpha: alpha * .9)
        ..strokeWidth = 7 - progress * 3
        ..strokeCap = ui.StrokeCap.round;
      for (var i = 0; i < 7; i++) {
        final offset = (i - 3) * 8.0;
        canvas.drawLine(
          Offset(defender.x - 18, defender.y + offset),
          Offset(attacker.x + 18, attacker.y - offset),
          paint,
        );
      }
      canvas.drawCircle(
        Offset((attacker.x + defender.x) / 2, (attacker.y + defender.y) / 2),
        22 + progress * 18,
        Paint()..color = const Color(0xffffb52e).withValues(alpha: alpha * .22),
      );
    } else if (action == BattleCommandType.charge) {
      final paint = Paint()
        ..color = const Color(0xffffe3a1).withValues(alpha: alpha * .85)
        ..strokeWidth = 3
        ..strokeCap = ui.StrokeCap.round;
      for (var i = 0; i < 5; i++) {
        final y = attacker.y + (i - 2) * 7.0;
        canvas.drawLine(
          Offset(attacker.x - 28 - progress * 22, y),
          Offset(attacker.x + 10, y),
          paint,
        );
      }
      canvas.drawCircle(
        Offset(defender.x, defender.y),
        14 + progress * 15,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xffff9c64).withValues(alpha: alpha),
      );
    } else if (action == BattleCommandType.cooperate) {
      final paint = Paint()
        ..color = const Color(0xfff1ca65).withValues(alpha: alpha)
        ..strokeWidth = 3;
      canvas.drawLine(
        Offset(attacker.x, attacker.y),
        Offset(defender.x, defender.y),
        paint,
      );
      canvas.drawCircle(
        Offset(defender.x, defender.y),
        18 + progress * 10,
        Paint()..color = const Color(0xffffdc72).withValues(alpha: alpha * .2),
      );
    } else if (action == BattleCommandType.attack) {
      canvas.drawCircle(
        Offset(defender.x, defender.y),
        18 + progress * 12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0xffffeed0).withValues(alpha: alpha),
      );
    }
  }

  Vector2 _center(String? officerId, bool attacker) {
    final units = attacker ? battle.attackerUnits : battle.defenderUnits;
    final unit = units.where((item) => item.officerId == officerId).firstOrNull;
    return unit == null
        ? Vector2(178, 150)
        : BattleMapLayout.cellCenter(BattleCell(unit.row, unit.column));
  }
}
