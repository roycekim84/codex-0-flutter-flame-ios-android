import '../models/game_state.dart';

enum AiDecisionType { gift, spy, fortify }

class AiDecision {
  const AiDecision(this.type, {this.targetProvinceId});
  final AiDecisionType type;
  final String? targetProvinceId;
}

/// AI chooses a small, inspectable action. GameEngine applies the result.
class AiEngine {
  AiDecision choose(GameState state, ForceState force) {
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
