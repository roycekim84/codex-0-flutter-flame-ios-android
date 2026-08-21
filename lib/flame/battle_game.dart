import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../battle/battle_state.dart';

class BattleGame extends FlameGame {
  BattleGame(this.battle);
  final BattleState battle;

  @override
  Future<void> onLoad() async {
    _drawBoard();
  }

  void refreshBoard() {
    removeAll(children.toList());
    _drawBoard();
  }

  void _drawBoard() {
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
    for (var row = 0; row < 5; row++) {
      for (var column = 0; column < 6; column++) {
        add(
          RectangleComponent(
            position: Vector2(12 + column * 62, 58 + row * 62),
            size: Vector2(58, 58),
            paint: Paint()
              ..color = (row + column).isEven
                  ? const Color(0xff5d765d)
                  : const Color(0xff4c674f),
          ),
        );
      }
    }
    for (final unit in [...battle.attackerUnits, ...battle.defenderUnits]) {
      final baseColor = battle.attackerUnits.contains(unit)
          ? const Color(0xff2f6da1)
          : const Color(0xffa84f45);
      final color = unit.burning ? const Color(0xffd87928) : baseColor;
      add(
        CircleComponent(
          position: Vector2(41 + unit.column * 62, 87 + unit.row * 62),
          radius: 20,
          anchor: Anchor.center,
          paint: Paint()..color = color,
        ),
      );
      add(
        TextComponent(
          text: '${unit.soldiers}${unit.burning ? ' 🔥' : ''}',
          position: Vector2(22 + unit.column * 62, 78 + unit.row * 62),
          textRenderer: TextPaint(
            style: const TextStyle(color: Color(0xffffffff), fontSize: 10),
          ),
        ),
      );
    }
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
