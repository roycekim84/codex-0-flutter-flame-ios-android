enum GameCommandType {
  develop,
  recruit,
  tax,
  relief,
  train,
  fortify,
  buyWeapons,
  buyHorses,
  search,
  recruitOfficer,
  rewardOfficer,
  appointGovernor,
  moveOfficer,
  giftForce,
  formAlliance,
  threatenForce,
  infiltrate,
  inciteOfficer,
  bribeOfficer,
  spreadRumor,
  buyFood,
  sellFood,
  endMonth,
}

class GameCommand {
  const GameCommand({
    required this.type,
    this.officerId,
    this.provinceId,
    this.targetOfficerId,
    this.targetForceId,
    this.destinationProvinceId,
    this.soldiers,
  });
  final GameCommandType type;
  final String? officerId;
  final String? provinceId;
  final String? targetOfficerId;
  final String? targetForceId;
  final String? destinationProvinceId;
  final int? soldiers;
}

class CommandResult {
  const CommandResult._(this.success, this.message, {this.targetOfficerId});
  const CommandResult.success(String message, {String? targetOfficerId})
    : this._(true, message, targetOfficerId: targetOfficerId);
  const CommandResult.failure(String message) : this._(false, message);
  final bool success;
  final String message;
  final String? targetOfficerId;
}
