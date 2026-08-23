import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../core/asset_repository.dart';
import '../battle/battle_command.dart';
import '../battle/battle_map.dart';
import '../battle/battle_state.dart';
import 'battle_unit_component.dart';

class BattleGame extends FlameGame {
  BattleGame(this.battle, {this.onCellTap});
  final BattleState battle;
  final void Function(BattleCell cell)? onCellTap;
  late ui.Image unitImage;
  late ui.Image terrainImage;
  late ui.Image effectsImage;

  @override
  Future<void> onLoad() async {
    unitImage = await images.load('battle_unit_token_alpha.png');
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
    add(BattleMapComponent(battle, onCellTap: onCellTap));
    for (final unit in [...battle.attackerUnits, ...battle.defenderUnits]) {
      final center = BattleMapLayout.worldCenter(
        BattleCell(unit.row, unit.column),
      );
      add(
        BattleUnitComponent(
          unit: unit,
          image: unitImage,
          isAttacker: battle.attackerUnits.contains(unit),
          center: center,
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
  }
}
