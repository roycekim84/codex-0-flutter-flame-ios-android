import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../core/asset_repository.dart';
import '../battle/battle_command.dart';
import '../battle/battle_map.dart';
import '../battle/battle_state.dart';
import 'battle_unit_component.dart';
import 'battle_action_effect.dart';

class BattleGame extends FlameGame {
  BattleGame(this.battle, {this.onCellTap});
  final BattleState battle;
  final void Function(BattleCell cell)? onCellTap;
  late ui.Image unitImage;
  late ui.Image cavalryImage;
  late ui.Image archerImage;
  late ui.Image terrainImage;
  late ui.Image effectsImage;

  @override
  Future<void> onLoad() async {
    // Flame's Images cache owns these decoded images. Loading them together
    // keeps the first battle frame from decoding each layer serially, and the
    // same ui.Image references are reused whenever refreshBoard is called.
    final loaded = await Future.wait(
      AssetRepository.battleRendererAssets.map(
        (path) => images.load(AssetRepository.flameKey(path)),
      ),
    );
    unitImage = loaded[0];
    cavalryImage = loaded[1];
    archerImage = loaded[2];
    terrainImage = loaded[3];
    effectsImage = loaded[4];
    _drawBoard();
  }

  void refreshBoard() {
    removeAll(children.toList());
    _drawBoard();
  }

  Future<void> playEvent(BattleResultEvent event) {
    if (!event.hasEffect) return Future<void>.value();
    final completer = Completer<void>();
    add(
      BattleActionEffectComponent(
        battle: battle,
        event: event,
        onComplete: () {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    return completer.future;
  }

  void _drawBoard() {
    add(
      SpriteComponent.fromImage(
        terrainImage,
        position: BattleMapLayout.mapOffset,
        size: Vector2(BattleMapLayout.boardWidth, BattleMapLayout.boardHeight),
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
          image: switch (unit.type) {
            BattleUnitType.cavalry => cavalryImage,
            BattleUnitType.archers => archerImage,
            BattleUnitType.infantry => unitImage,
          },
          isAttacker: battle.attackerUnits.contains(unit),
          center: center,
          isSelected:
              battle.selectedAttackerId == unit.officerId ||
              battle.selectedDefenderId == unit.officerId,
          unitType: unit.type,
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
          position: Vector2(156, 214),
          size: Vector2(92, 116),
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
