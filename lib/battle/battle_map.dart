import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'battle_command.dart';
import 'battle_state.dart';
import 'terrain.dart';

/// 전투판의 논리 좌표와 Flame 좌표를 한 곳에서 관리한다.
class BattleMapLayout {
  static const rows = 5;
  static const columns = 6;
  static final mapOffset = Vector2(8, 48);

  static Vector2 cellCenter(BattleCell cell) => Vector2(
    35 + cell.column * 58,
    30 + cell.row * 51 + (cell.column.isOdd ? 25.5 : 0),
  );

  static Vector2 worldCenter(BattleCell cell) => mapOffset + cellCenter(cell);
}

/// 배경 이미지 위에 투명한 육각 격자와 상호작용 상태를 그린다.
class BattleMapComponent extends PositionComponent with TapCallbacks {
  BattleMapComponent(this.battle, {this.onCellTap})
    : super(position: BattleMapLayout.mapOffset, size: Vector2(356, 310));

  final BattleState battle;
  final void Function(BattleCell cell)? onCellTap;
  static const _radius = 28.5;

  @override
  void onTapUp(TapUpEvent event) {
    final point = event.localPosition;
    BattleCell? closest;
    var closestDistance = double.infinity;
    for (var row = 0; row < BattleMapLayout.rows; row++) {
      for (var column = 0; column < BattleMapLayout.columns; column++) {
        final center = BattleMapLayout.cellCenter(BattleCell(row, column));
        final distance = (center - point).length;
        if (distance < closestDistance) {
          closestDistance = distance;
          closest = BattleCell(row, column);
        }
      }
    }
    if (closest != null && closestDistance <= _radius) onCellTap?.call(closest);
    event.handled = true;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    for (var row = 0; row < BattleMapLayout.rows; row++) {
      for (var column = 0; column < BattleMapLayout.columns; column++) {
        final cell = BattleCell(row, column);
        final center = BattleMapLayout.cellCenter(cell);
        final path = _hexPath(center);
        final fill = Paint()
          ..style = PaintingStyle.fill
          ..color = _tileColor(row, column).withValues(alpha: .12);
        canvas.drawPath(path, fill);

        final highlight = _highlightColor(cell);
        if (highlight != null) {
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.fill
              ..color = highlight.withValues(alpha: .30),
          );
        }

        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = highlight == null ? .75 : 1.8
            ..color = (highlight ?? const Color(0xff1e241b)).withValues(
              alpha: highlight == null ? .48 : .95,
            ),
        );
      }
    }

    final selectedAttacker = battle.selectedAttacker;
    if (selectedAttacker != null) {
      _drawSelection(
        canvas,
        BattleMapLayout.cellCenter(
          BattleCell(selectedAttacker.row, selectedAttacker.column),
        ),
        const Color(0xffffd66e),
      );
    }
    final selectedDefender = battle.selectedDefender;
    if (selectedDefender != null) {
      _drawSelection(
        canvas,
        BattleMapLayout.cellCenter(
          BattleCell(selectedDefender.row, selectedDefender.column),
        ),
        const Color(0xffe37b68),
      );
    }
  }

  Path _hexPath(Vector2 center) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final point = Offset(
        center.x + _radius * math.cos(angle),
        center.y + _radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  void _drawSelection(ui.Canvas canvas, Vector2 center, Color color) {
    canvas.drawCircle(
      Offset(center.x, center.y),
      _radius - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color.withValues(alpha: .92),
    );
  }

  Color? _highlightColor(BattleCell cell) {
    if (battle.attackCells.contains(cell)) return const Color(0xffd45b4c);
    if (battle.movementCells.contains(cell)) return const Color(0xff63a9d8);
    return null;
  }

  Color _tileColor(int row, int column) {
    final terrain = battle.terrain;
    if (terrain == TerrainType.forest && row.isEven) {
      return const Color(0xff587f54);
    }
    if (terrain == TerrainType.mountain && column.isEven) {
      return const Color(0xffa99b78);
    }
    if (terrain == TerrainType.river && column == 2) {
      return const Color(0xff4d8aaa);
    }
    if (terrain == TerrainType.fort && row == 2 && column == 3) {
      return const Color(0xffc18d4d);
    }
    return (row + column).isEven
        ? const Color(0xff78915d)
        : const Color(0xff617d55);
  }
}
