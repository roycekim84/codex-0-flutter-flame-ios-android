import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../battle/battle_state.dart';

class BattleGame extends FlameGame {
  BattleGame(this.battle);
  final BattleState battle;

  @override
  Future<void> onLoad() async {
    add(
      TextComponent(
        text: 'DAY ${battle.day}',
        position: Vector2(18, 18),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xfff5ead7),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    add(
      RectangleComponent(
        position: Vector2(20, 110),
        size: Vector2(130, 36),
        paint: Paint()..color = const Color(0xff557c68),
      ),
    );
    add(
      RectangleComponent(
        position: Vector2(210, 110),
        size: Vector2(130, 36),
        paint: Paint()..color = const Color(0xffa85d4a),
      ),
    );
    add(
      TextComponent(
        text: battle.attackerName,
        position: Vector2(32, 118),
        textRenderer: TextPaint(
          style: const TextStyle(color: Color(0xffffffff), fontSize: 14),
        ),
      ),
    );
    add(
      TextComponent(
        text: battle.defenderName,
        position: Vector2(222, 118),
        textRenderer: TextPaint(
          style: const TextStyle(color: Color(0xffffffff), fontSize: 14),
        ),
      ),
    );
  }
}
