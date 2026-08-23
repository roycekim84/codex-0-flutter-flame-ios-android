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
      final direction = defender - attacker;
      final distance = direction.length;
      final unitDirection = distance == 0
          ? Vector2(1, 0)
          : direction / distance;
      final perpendicular = Vector2(-unitDirection.y, unitDirection.x);
      final flameHead = attacker + direction * progress;
      final flameTail = attacker + direction * (progress * .12);
      final corePaint = Paint()
        ..color = const Color(0xffffc247).withValues(alpha: alpha * .94)
        ..strokeWidth = 10 - progress * 4
        ..strokeCap = ui.StrokeCap.round;
      final outerPaint = Paint()
        ..color = const Color(0xffff6a21).withValues(alpha: alpha * .72)
        ..strokeWidth = 17 - progress * 7
        ..strokeCap = ui.StrokeCap.round;
      canvas.drawLine(
        Offset(flameTail.x, flameTail.y),
        Offset(flameHead.x, flameHead.y),
        outerPaint,
      );
      canvas.drawLine(
        Offset(flameTail.x, flameTail.y),
        Offset(flameHead.x, flameHead.y),
        corePaint,
      );
      for (var i = 0; i < 9; i++) {
        final offset = (i - 4) * 7.0;
        final wave = math.sin(elapsed * 18 + i * 1.7) * 5;
        final start =
            attacker +
            direction * (.12 + (i % 3) * .035) +
            perpendicular * (offset + wave);
        final endProgress = (.42 + (i % 4) * .12) * progress;
        final end =
            attacker +
            direction * endProgress +
            perpendicular * (offset * .45 + wave * .35);
        canvas.drawLine(
          Offset(start.x, start.y),
          Offset(end.x, end.y),
          Paint()
            ..color =
                (i.isEven ? const Color(0xffffe8a0) : const Color(0xffff862c))
                    .withValues(alpha: alpha * (i.isEven ? .9 : .74))
            ..strokeWidth = i.isEven ? 3.2 : 5.0
            ..strokeCap = ui.StrokeCap.round,
        );
      }
      for (var i = 0; i < 8; i++) {
        final t = ((i * .19) + progress * .8) % 1.0;
        final wave = math.sin(elapsed * 9 + i * 2.1) * 10;
        final ember =
            attacker + direction * (.18 + t * .7) + perpendicular * wave;
        canvas.drawCircle(
          Offset(ember.x, ember.y),
          1.5 + (i % 3) * .7,
          Paint()
            ..color = const Color(
              0xffffd56a,
            ).withValues(alpha: alpha * (.45 + (i % 3) * .12)),
        );
      }
      canvas.drawCircle(
        Offset(flameHead.x, flameHead.y),
        24 + progress * 22,
        Paint()..color = const Color(0xffff9d35).withValues(alpha: alpha * .2),
      );
      for (var i = 0; i < 4; i++) {
        final smoke =
            defender -
            direction * (i * 8 + 12) +
            perpendicular * math.sin(elapsed * 5 + i) * 9;
        canvas.drawCircle(
          Offset(smoke.x, smoke.y),
          7 + i * 2.5 + progress * 4,
          Paint()
            ..color = const Color(
              0xff5a5144,
            ).withValues(alpha: alpha * (.16 - i * .02)),
        );
      }
      canvas.drawCircle(
        Offset(defender.x, defender.y),
        20 + progress * 22,
        Paint()..color = const Color(0xffff6b2d).withValues(alpha: alpha * .28),
      );
    } else if (action == BattleCommandType.charge) {
      final direction = defender - attacker;
      final distance = direction.length;
      final unitDirection = distance == 0
          ? Vector2(1, 0)
          : direction / distance;
      final perpendicular = Vector2(-unitDirection.y, unitDirection.x);
      final lancePoint = attacker + direction * progress.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xffffe3a1).withValues(alpha: alpha * .85)
        ..strokeWidth = 3
        ..strokeCap = ui.StrokeCap.round;
      for (var i = 0; i < 7; i++) {
        final offset = (i - 3) * 5.5;
        final trailStart =
            lancePoint -
            unitDirection * (25 + (1 - progress) * 18) +
            perpendicular * offset;
        final trailEnd =
            lancePoint - unitDirection * 4 + perpendicular * offset;
        canvas.drawLine(
          Offset(trailStart.x, trailStart.y),
          Offset(trailEnd.x, trailEnd.y),
          paint,
        );
      }
      canvas.drawCircle(
        Offset(lancePoint.x, lancePoint.y),
        13 + progress * 16,
        Paint()..color = const Color(0xffffd16f).withValues(alpha: alpha * .16),
      );
      canvas.drawCircle(
        Offset(defender.x, defender.y),
        14 + progress * 22,
        Paint()..color = const Color(0xffff9c64).withValues(alpha: alpha * .22),
      );
      canvas.drawCircle(
        Offset(defender.x, defender.y),
        15 + progress * 16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 - progress * 2
          ..color = const Color(0xffffc276).withValues(alpha: alpha),
      );
    } else if (action == BattleCommandType.cooperate) {
      final support = _cooperatorCenter(defender, event.attackerId);
      final supportPoint =
          support ??
          Vector2(
            attacker.x + (defender.x - attacker.x) * .18,
            attacker.y + (defender.y - attacker.y) * .18,
          );
      final linePaint = Paint()
        ..color = const Color(0xfff1ca65).withValues(alpha: alpha * .88)
        ..strokeWidth = 3
        ..strokeCap = ui.StrokeCap.round;
      final supportPaint = Paint()
        ..color = const Color(0xff8fc8ff).withValues(alpha: alpha * .88)
        ..strokeWidth = 3
        ..strokeCap = ui.StrokeCap.round;
      _drawActionLine(canvas, attacker, defender, progress, linePaint);
      _drawActionLine(canvas, supportPoint, defender, progress, supportPaint);
      final impact = Offset(defender.x, defender.y);
      canvas.drawCircle(
        impact,
        20 + progress * 18,
        Paint()..color = const Color(0xffffdc72).withValues(alpha: alpha * .2),
      );
      for (var i = 0; i < 4; i++) {
        final angle = math.pi / 4 + i * math.pi / 2;
        final inner = 17 + progress * 10;
        final outer = inner + 14 * (1 - progress);
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
            ..color = const Color(0xffffedaf).withValues(alpha: alpha * .9)
            ..strokeWidth = 2.5
            ..strokeCap = ui.StrokeCap.round,
        );
      }
    } else if (action == BattleCommandType.information) {
      final direction = defender - attacker;
      final distance = direction.length;
      final unitDirection = distance == 0
          ? Vector2(1, 0)
          : direction / distance;
      final perpendicular = Vector2(-unitDirection.y, unitDirection.x);
      final scanPoint = attacker + direction * progress;
      final scanPaint = Paint()
        ..color = const Color(0xff8ed8ff).withValues(alpha: alpha * .9)
        ..strokeWidth = 3
        ..strokeCap = ui.StrokeCap.round;
      canvas.drawLine(
        Offset(attacker.x, attacker.y),
        Offset(scanPoint.x, scanPoint.y),
        scanPaint,
      );
      canvas.drawCircle(
        Offset(scanPoint.x, scanPoint.y),
        13 + progress * 13,
        Paint()..color = const Color(0xff69c7ff).withValues(alpha: alpha * .15),
      );
      canvas.drawCircle(
        Offset(scanPoint.x, scanPoint.y),
        14 + progress * 11,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xffb8ebff).withValues(alpha: alpha * .8),
      );
      for (var i = 0; i < 5; i++) {
        final offset = (i - 2) * 7.0;
        final particle = scanPoint + perpendicular * offset;
        canvas.drawCircle(
          Offset(particle.x, particle.y),
          1.8 + (i % 2),
          Paint()
            ..color = const Color(
              0xffd6f4ff,
            ).withValues(alpha: alpha * (.55 + i * .06)),
        );
      }
      canvas.drawCircle(
        Offset(defender.x, defender.y),
        17 + progress * 19,
        Paint()..color = const Color(0xff6ecbff).withValues(alpha: alpha * .12),
      );
      canvas.drawCircle(
        Offset(defender.x, defender.y),
        18 + progress * 16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xff9ddfff).withValues(alpha: alpha * .75),
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

  Vector2? _cooperatorCenter(Vector2 defender, String? primaryId) {
    final candidates = battle.attackerUnits
        .where((unit) => unit.officerId != primaryId && unit.soldiers > 0)
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final aCenter = BattleMapLayout.cellCenter(BattleCell(a.row, a.column));
      final bCenter = BattleMapLayout.cellCenter(BattleCell(b.row, b.column));
      return (aCenter - defender).length.compareTo((bCenter - defender).length);
    });
    final unit = candidates.first;
    return BattleMapLayout.cellCenter(BattleCell(unit.row, unit.column));
  }

  void _drawActionLine(
    ui.Canvas canvas,
    Vector2 from,
    Vector2 to,
    double progress,
    Paint paint,
  ) {
    final head = from + (to - from) * progress;
    final tail = from + (to - from) * (progress * .72);
    canvas.drawLine(Offset(tail.x, tail.y), Offset(head.x, head.y), paint);
  }
}
