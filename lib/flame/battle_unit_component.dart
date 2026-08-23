import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../battle/battle_state.dart';

enum BattleUnitScale { small, medium, large }

class BattleUnitComponent extends PositionComponent {
  BattleUnitComponent({
    required this.unit,
    required this.image,
    required this.isAttacker,
    required Vector2 center,
    this.isSelected = false,
    this.unitType = BattleUnitType.infantry,
  }) : scaleType = _scaleFor(unit.soldiers),
       super(position: center, anchor: Anchor.center, size: Vector2.all(82));

  final BattleUnit unit;
  final ui.Image image;
  final bool isAttacker;
  final bool isSelected;
  final BattleUnitType unitType;
  final BattleUnitScale scaleType;

  @override
  Future<void> onLoad() async {
    final visualSize = switch (scaleType) {
      BattleUnitScale.small => 48.0,
      BattleUnitScale.medium => 58.0,
      BattleUnitScale.large => 68.0,
    };
    if (isSelected) {
      add(
        CircleComponent(
          radius: 39,
          position: Vector2(41, 38),
          anchor: Anchor.center,
          paint: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = const Color(0xffffd66e).withValues(alpha: .9),
        ),
      );
    }
    add(
      SpriteComponent.fromImage(
        image,
        position: Vector2(41, 36),
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

    final panelColor = isAttacker
        ? const Color(0xff142b42)
        : const Color(0xff401c1b);
    add(
      RectangleComponent(
        position: Vector2(5, 57),
        size: Vector2(72, 21),
        paint: Paint()
          ..color = (isSelected ? const Color(0xffffd66e) : panelColor)
              .withValues(alpha: .96),
      ),
    );
    add(
      RectangleComponent(
        position: Vector2(7, 59),
        size: Vector2(68, 17),
        paint: Paint()..color = panelColor.withValues(alpha: .96),
      ),
    );
    add(
      TextComponent(
        text: '${_format(unit.soldiers)}${unit.burning ? ' 🔥' : ''}',
        position: Vector2(41, 59),
        anchor: Anchor.topCenter,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xfffff1d2),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    final flagColor = isAttacker
        ? const Color(0xff1d4b61)
        : const Color(0xff762e2d);
    add(
      RectangleComponent(
        position: Vector2(18, -15),
        size: Vector2(2, 31),
        paint: Paint()..color = const Color(0xffc69b55),
      ),
    );
    add(
      RectangleComponent(
        position: Vector2(17, -15),
        size: Vector2(50, 26),
        paint: Paint()
          ..color = (isSelected ? const Color(0xffffd66e) : flagColor)
              .withValues(alpha: .98),
      ),
    );
    add(
      RectangleComponent(
        position: Vector2(19, -13),
        size: Vector2(46, 22),
        paint: Paint()..color = flagColor.withValues(alpha: .98),
      ),
    );
    add(
      TextComponent(
        text: unit.name,
        position: Vector2(42, -10),
        anchor: Anchor.topCenter,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xfffff0c7),
            fontSize: 10,
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
