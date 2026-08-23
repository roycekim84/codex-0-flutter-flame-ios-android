import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../battle/battle_state.dart';

enum BattleUnitScale { small, medium, large }

enum BattleUnitType { infantry, cavalry, spearmen, archers }

class BattleUnitComponent extends PositionComponent {
  BattleUnitComponent({
    required this.unit,
    required this.image,
    required this.isAttacker,
    required Vector2 center,
    this.unitType = BattleUnitType.infantry,
  }) : scaleType = _scaleFor(unit.soldiers),
       super(position: center, anchor: Anchor.center, size: Vector2.all(58));

  final BattleUnit unit;
  final ui.Image image;
  final bool isAttacker;
  final BattleUnitType unitType;
  final BattleUnitScale scaleType;

  @override
  Future<void> onLoad() async {
    final visualSize = switch (scaleType) {
      BattleUnitScale.small => 38.0,
      BattleUnitScale.medium => 47.0,
      BattleUnitScale.large => 56.0,
    };
    add(
      SpriteComponent.fromImage(
        image,
        position: Vector2(29, 24),
        size: Vector2.all(visualSize),
        anchor: Anchor.center,
        paint: Paint()
          ..colorFilter = ColorFilter.mode(
            unit.burning
                ? const Color(0xffd87928)
                : isAttacker
                ? Colors.white
                : const Color(0xffa84f45),
            BlendMode.modulate,
          ),
      ),
    );

    add(
      RectangleComponent(
        position: Vector2(5, 45),
        size: Vector2(48, 14),
        paint: Paint()
          ..color =
              (isAttacker ? const Color(0xff142b42) : const Color(0xff401c1b))
                  .withValues(alpha: .92),
      ),
    );
    add(
      TextComponent(
        text: '${_format(unit.soldiers)}${unit.burning ? ' 🔥' : ''}',
        position: Vector2(29, 47),
        anchor: Anchor.topCenter,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xfffff1d2),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    add(
      RectangleComponent(
        position: Vector2(17, -5),
        size: Vector2(24, 19),
        paint: Paint()
          ..color =
              (isAttacker ? const Color(0xff1d4b61) : const Color(0xff762e2d))
                  .withValues(alpha: .94),
      ),
    );
    add(
      TextComponent(
        text: unit.name,
        position: Vector2(29, -2),
        anchor: Anchor.topCenter,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xfffff0c7),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static BattleUnitScale _scaleFor(int soldiers) => soldiers < 1200
      ? BattleUnitScale.small
      : soldiers < 3000
      ? BattleUnitScale.medium
      : BattleUnitScale.large;

  static String _format(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}
