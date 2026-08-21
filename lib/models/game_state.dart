import 'package:flutter/foundation.dart';

class ProvinceState {
  ProvinceState({
    required this.id,
    required this.name,
    required this.ownerForceId,
    required this.adjacentProvinceIds,
    required this.land,
    required this.publicLoyalty,
    required this.soldiers,
    required this.gold,
    required this.food,
    required this.officerIds,
    required this.mapX,
    required this.mapY,
    required this.ownerName,
    this.governorId,
  });
  final String id, name;
  String ownerForceId, ownerName;
  final List<String> adjacentProvinceIds, officerIds;
  String? governorId;
  final double mapX, mapY;
  int land, publicLoyalty, soldiers, gold, food;
  bool isOwnedBy(String forceId) => ownerForceId == forceId;
}

class ForceState {
  ForceState({
    required this.id,
    required this.name,
    required this.gold,
    required this.food,
    required this.rulerId,
    required this.provinceIds,
    required this.officerIds,
  });
  final String id, name, rulerId;
  final List<String> provinceIds, officerIds;
  int gold, food;
}

class OfficerState {
  OfficerState({
    required this.id,
    required this.name,
    required this.forceId,
    required this.provinceId,
    required this.war,
    required this.intelligence,
    required this.charisma,
    required this.loyalty,
    required this.status,
  });
  final String id, name;
  String forceId, status;
  String provinceId;
  final int war, intelligence, charisma;
  int loyalty;
}

class GameState extends ChangeNotifier {
  GameState({
    required this.scenarioId,
    required this.year,
    required this.month,
    required this.playerForceId,
    required this.forces,
    required this.provinces,
    required this.officers,
    required this.randomSeed,
    Map<String, int>? relations,
    Set<String>? alliedForceIds,
    List<String>? gameLog,
  }) : relations = relations ?? {},
       alliedForceIds = alliedForceIds ?? {},
       gameLog = gameLog ?? [];
  final String scenarioId, playerForceId;
  int year, month;
  final List<ForceState> forces;
  final List<ProvinceState> provinces;
  final List<OfficerState> officers;
  final int randomSeed;
  final Map<String, int> relations;
  final Set<String> alliedForceIds;
  final List<String> gameLog;
  final Set<String> actedOfficerIds = <String>{};
  ForceState get playerForce => forces.firstWhere((f) => f.id == playerForceId);
  List<String> get playerProvinceIds => playerForce.provinceIds;
  int get playerSoldiers =>
      provinces.where(isPlayerProvince).fold(0, (sum, p) => sum + p.soldiers);
  void log(String message) {
    gameLog.add('[$year-${month.toString().padLeft(2, '0')}] $message');
    notifyListeners();
  }

  bool isPlayerProvince(ProvinceState province) =>
      province.ownerForceId == playerForceId;

  bool hasActed(String officerId) => actedOfficerIds.contains(officerId);

  void markActed(String officerId) {
    actedOfficerIds.add(officerId);
    notifyListeners();
  }

  void resetMonthlyActions() {
    actedOfficerIds.clear();
  }

  int relationTo(String forceId) => relations[forceId] ?? 0;

  void setRelation(String forceId, int value) {
    relations[forceId] = value.clamp(-100, 100).toInt();
    notifyListeners();
  }

  static GameState fromScenario(
    Map<String, dynamic> data, {
    String? selectedForceId,
  }) {
    final forces = (data['forces'] as List)
        .map(
          (x) => ForceState(
            id: x['id'],
            name: x['name'],
            rulerId: x['rulerId'],
            gold: x['gold'],
            food: x['food'],
            provinceIds: List<String>.from(x['provinceIds']),
            officerIds: List<String>.from(x['officerIds']),
          ),
        )
        .toList();
    final ownerNames = {for (final f in forces) f.id: f.name};
    return GameState(
      scenarioId: data['id'],
      year: data['year'],
      month: data['month'],
      playerForceId: selectedForceId ?? data['playerForceId'],
      randomSeed: data['randomSeed'],
      relations: {
        for (final force in forces.where(
          (f) => f.id != (selectedForceId ?? data['playerForceId']),
        ))
          force.id:
              ((data['relations'] as Map?)?[force.id] as num?)?.toInt() ?? -10,
      },
      forces: forces,
      provinces: (data['provinces'] as List)
          .map(
            (x) => ProvinceState(
              id: x['id'],
              name: x['name'],
              ownerForceId: x['ownerForceId'],
              ownerName: ownerNames[x['ownerForceId']]!,
              adjacentProvinceIds: List<String>.from(x['adjacentProvinceIds']),
              officerIds: List<String>.from(x['officerIds']),
              land: x['land'],
              publicLoyalty: x['publicLoyalty'],
              soldiers: x['soldiers'],
              gold: x['gold'],
              food: x['food'],
              mapX: (x['mapX'] as num).toDouble(),
              mapY: (x['mapY'] as num).toDouble(),
              governorId: x['governorId'],
            ),
          )
          .toList(),
      officers: (data['officers'] as List)
          .map(
            (x) => OfficerState(
              id: x['id'],
              name: x['name'],
              forceId: x['forceId'],
              provinceId: x['provinceId'],
              war: x['war'],
              intelligence: x['intelligence'],
              charisma: x['charisma'],
              loyalty: x['loyalty'],
              status: x['status'],
            ),
          )
          .toList(),
    );
  }
}
