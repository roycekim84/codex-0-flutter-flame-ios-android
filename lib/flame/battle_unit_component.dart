import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../battle/battle_state.dart';

enum BattleUnitScale { small, medium, large }

class BattleUnitComponent extends PositionComponent {
  BattleUnitComponent({
    required this.unit,
    required this.image,
    required this.bannerImage,
    required this.isAttacker,
    required Vector2 center,
    this.isSelected = false,
    this.unitType = BattleUnitType.infantry,
  }) : scaleType = _scaleFor(unit.soldiers),
       super(position: center, anchor: Anchor.center, size: Vector2.all(64));

  final BattleUnit unit;
  final ui.Image image;
  final ui.Image bannerImage;
  final bool isAttacker;
  final bool isSelected;
  final BattleUnitType unitType;
  final BattleUnitScale scaleType;

  @override
  Future<void> onLoad() async {
    final visualSize = switch (scaleType) {
      BattleUnitScale.small => 48.0,
      BattleUnitScale.medium => 56.0,
      BattleUnitScale.large => 64.0,
    };
    if (isSelected) {
      add(
        CircleComponent(
          radius: 29,
          position: Vector2(32, 30),
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
        position: Vector2(32, 30),
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
        position: Vector2(3, 45),
        size: Vector2(58, 19),
        paint: Paint()
          ..color = (isSelected ? const Color(0xffffd66e) : panelColor)
              .withValues(alpha: .96),
      ),
    );
    add(
      RectangleComponent(
        position: Vector2(5, 47),
        size: Vector2(54, 15),
        paint: Paint()..color = panelColor.withValues(alpha: .96),
      ),
    );
    add(
      TextComponent(
        text: '${_format(unit.soldiers)}${unit.burning ? ' 🔥' : ''}',
        position: Vector2(32, 47),
        anchor: Anchor.topCenter,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xfffff1d2),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    // The three transparent banners live in one horizontal strip:
    // green, red, blue.  Use red for the opposing side and blue for the
    // player side so a unit remains identifiable even when sprites overlap.
    add(
      SpriteComponent.fromImage(
        bannerImage,
        srcPosition: Vector2(isAttacker ? 1448 : 724, 0),
        srcSize: Vector2(724, 724),
        position: Vector2(32, -8),
        size: Vector2(20, 30),
        anchor: Anchor.bottomCenter,
        paint: Paint()
          ..colorFilter = isSelected
              ? const ColorFilter.mode(Color(0xffffd66e), BlendMode.modulate)
              : null,
      ),
    );
    add(
      RectangleComponent(
        position: Vector2(4, -8),
        size: Vector2(56, 14),
        paint: Paint()..color = const Color(0xff090807).withValues(alpha: .74),
      ),
    );
    add(
      TextComponent(
        text: unit.name,
        position: Vector2(32, -7),
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
