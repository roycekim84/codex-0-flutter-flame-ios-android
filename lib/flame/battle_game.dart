import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../core/asset_repository.dart';
import '../battle/battle_command.dart';
import '../battle/battle_map.dart';
import '../battle/battle_state.dart';

class BattleGame extends FlameGame {
  BattleGame(this.battle);
  final BattleState battle;
  late ui.Image unitImage;
  late ui.Image terrainImage;
  late ui.Image effectsImage;

  @override
  Future<void> onLoad() async {
    unitImage = await images.load('battle_unit_token.png');
    terrainImage = await images.load(
      AssetRepository.battleTerrainOverlay.replaceFirst('assets/images/', ''),
    );
    effectsImage = await images.load(
      AssetRepository.battleEffectsStrip.replaceFirst('assets/images/', ''),
    );
    _drawBoard();
  }

  void refreshBoard() {
    removeAll(children.toList());
    _drawBoard();
  }

  void _drawBoard() {
    add(
      SpriteComponent.fromImage(
        terrainImage,
        position: Vector2(8, 48),
        size: Vector2(356, 310),
        paint: Paint()
          ..colorFilter = ColorFilter.mode(
            Colors.white.withValues(alpha: .32),
            BlendMode.modulate,
          ),
      ),
    );
    add(BattleMapComponent(battle));
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
    for (final unit in [...battle.attackerUnits, ...battle.defenderUnits]) {
      final center = BattleMapLayout.worldCenter(
        BattleCell(unit.row, unit.column),
      );
      add(
        SpriteComponent.fromImage(
          unitImage,
          position: center,
          size: Vector2.all(48),
          anchor: Anchor.center,
          paint: Paint()
            ..colorFilter = ColorFilter.mode(
              unit.burning
                  ? const Color(0xffd87928)
                  : battle.attackerUnits.contains(unit)
                  ? Colors.white
                  : const Color(0xffa84f45),
              BlendMode.modulate,
            ),
        ),
      );
      add(
        TextComponent(
          text: '${unit.soldiers}${unit.burning ? ' 🔥' : ''}',
          position: center - Vector2(18, 8),
          textRenderer: TextPaint(
            style: const TextStyle(color: Color(0xffffffff), fontSize: 10),
          ),
        ),
      );
    }
    final hasFire = [
      ...battle.attackerUnits,
      ...battle.defenderUnits,
    ].any((unit) => unit.burning);
    if (hasFire) {
      add(
        SpriteComponent.fromImage(
          effectsImage,
          srcPosition: Vector2.zero(),
          srcSize: Vector2(341, 437),
          position: Vector2(150, 172),
          size: Vector2(78, 92),
          paint: Paint()
            ..colorFilter = ColorFilter.mode(
              Colors.white.withValues(alpha: .88),
              BlendMode.modulate,
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
