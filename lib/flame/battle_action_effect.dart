import 'dart:ui' as ui;
import 'dart:math' as math;

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
  TextComponent? _damageText;
  static const duration = .72;

  @override
  Future<void> onLoad() async {
    if (event.damage > 0) {
      _damageText = TextComponent(
        text: '-${_format(event.damage)}',
        position: Vector2(195, 220),
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
      );
      add(_damageText!);
    }
  }

  @override
  void update(double dt) {
    elapsed += dt;
    final progress = (elapsed / duration).clamp(0.0, 1.0);
    final defender = _center(event.defenderId, false);
    _damageText
      ?..position = Vector2(defender.x, defender.y - 28 - progress * 28)
      ..scale = Vector2.all(.88 + progress * .28);
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
      canvas.drawLine(
        Offset(
          attacker.x + (defender.x - attacker.x) * progress * .78,
          attacker.y + (defender.y - attacker.y) * progress * .78,
        ),
        Offset(
          attacker.x + (defender.x - attacker.x) * progress,
          attacker.y + (defender.y - attacker.y) * progress,
        ),
        Paint()
          ..color = const Color(0xffffe4a6).withValues(alpha: alpha * .9)
          ..strokeWidth = 4
          ..strokeCap = ui.StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(defender.x, defender.y),
        16 + progress * 18,
        Paint()..color = const Color(0xffffeed0).withValues(alpha: alpha * .18),
      );
      for (var i = 0; i < 6; i++) {
        final angle = i * 1.047;
        final inner = 17 + progress * 8;
        final outer = inner + 11 * (1 - progress);
        canvas.drawLine(
          Offset(
            defender.x + math.cos(angle) * inner,
            defender.y + math.sin(angle) * inner,
          ),
          Offset(
            defender.x + math.cos(angle) * outer,
            defender.y + math.sin(angle) * outer,
          ),
          Paint()
            ..color = const Color(0xffffcf6e).withValues(alpha: alpha * .8)
            ..strokeWidth = 2.4,
        );
      }
    }
  }

  static String _format(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  Vector2 _center(String? officerId, bool attacker) {
    final units = attacker ? battle.attackerUnits : battle.defenderUnits;
    final unit = units.where((item) => item.officerId == officerId).firstOrNull;
    return unit == null
        ? Vector2(178, 150)
        : BattleMapLayout.cellCenter(BattleCell(unit.row, unit.column));
  }
}
