import '../models/game_state.dart';

enum AiDecisionType { gift, spy, fortify, attack }

class AiDecision {
  const AiDecision(this.type, {this.targetProvinceId, this.sourceProvinceId});
  final AiDecisionType type;
  final String? targetProvinceId, sourceProvinceId;
}

/// AI chooses a small, inspectable action. GameEngine applies the result.
class AiEngine {
  AiDecision choose(GameState state, ForceState force) {
    if (state.relationTo(force.id) <= -30) {
      for (final source in state.provinces.where(
        (p) => p.ownerForceId == force.id && p.soldiers > 300,
      )) {
        final target = state.provinces
            .where(
              (p) =>
                  state.isPlayerProvince(p) &&
                  source.adjacentProvinceIds.contains(p.id),
            )
            .where((p) => p.soldiers < source.soldiers)
            .firstOrNull;
        if (target != null) {
          return AiDecision(
            AiDecisionType.attack,
            sourceProvinceId: source.id,
            targetProvinceId: target.id,
          );
        }
      }
    }
    if (state.relationTo(force.id) <= -10 && force.gold >= 100) {
      return const AiDecision(AiDecisionType.gift);
    }
    final target =
        state.provinces.where((p) => state.isPlayerProvince(p)).toList()
          ..sort((a, b) => a.publicLoyalty.compareTo(b.publicLoyalty));
    if (target.isNotEmpty && force.gold >= 80) {
      return AiDecision(AiDecisionType.spy, targetProvinceId: target.first.id);
    }
    return const AiDecision(AiDecisionType.fortify);
  }
}
