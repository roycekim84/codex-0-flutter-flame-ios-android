enum GameCommandType {
  develop,
  recruit,
  tax,
  relief,
  train,
  fortify,
  search,
  recruitOfficer,
  endMonth,
}

class GameCommand {
  const GameCommand({
    required this.type,
    this.officerId,
    this.provinceId,
    this.targetOfficerId,
  });
  final GameCommandType type;
  final String? officerId;
  final String? provinceId;
  final String? targetOfficerId;
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
