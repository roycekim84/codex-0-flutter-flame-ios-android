import 'package:flutter/foundation.dart';

enum AiPersonality {
  aggressive,
  cautious,
  diplomatic,
  development,
  opportunist,
}

List<List<double>> _territoryPoints(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<List>()
      .where((point) => point.length >= 2)
      .map(
        (point) => [(point[0] as num).toDouble(), (point[1] as num).toDouble()],
      )
      .toList();
}

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
    this.settlementType = 'medium',
    this.territoryPoints = const [],
    this.floodControl = 0,
  });
  final String id, name;
  String ownerForceId, ownerName;
  final String settlementType;
  final List<List<double>> territoryPoints;
  final List<String> adjacentProvinceIds, officerIds;
  String? governorId;
  final double mapX, mapY;
  int land, publicLoyalty, soldiers, gold, food, floodControl;
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
    this.aiPersonality = AiPersonality.opportunist,
    this.mapColorValue = 0xff8b7355,
    this.bannerIndex = 0,
  });
  final String id, name, rulerId;
  final AiPersonality aiPersonality;
  final List<String> provinceIds, officerIds;
  final int mapColorValue, bannerIndex;
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

class AiBattleReport {
  AiBattleReport({
    required this.attackerName,
    required this.defenderName,
    required this.targetProvinceName,
    required this.attackerWon,
    required this.day,
    required this.attackerSoldiers,
    required this.defenderSoldiers,
  });
  final String attackerName, defenderName, targetProvinceName;
  final bool attackerWon;
  final int day, attackerSoldiers, defenderSoldiers;
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
    Set<String>? revealedProvinceIds,
    List<AiBattleReport>? lastTurnReports,
    List<String>? gameLog,
  }) : relations = relations ?? {},
       alliedForceIds = alliedForceIds ?? {},
       revealedProvinceIds = revealedProvinceIds ?? {},
       lastTurnReports = lastTurnReports ?? [],
       gameLog = gameLog ?? [];
  final String scenarioId, playerForceId;
  int year, month;
  final List<ForceState> forces;
  final List<ProvinceState> provinces;
  final List<OfficerState> officers;
  final int randomSeed;
  final Map<String, int> relations;
  final Set<String> alliedForceIds;
  final Set<String> revealedProvinceIds;
  final List<AiBattleReport> lastTurnReports;
  final List<String> gameLog;
  String? lastEvent;
  bool gameOver = false;
  String? outcome;
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

  Map<String, dynamic> toSaveMap() => {
    'scenarioId': scenarioId,
    'year': year,
    'month': month,
    'playerForceId': playerForceId,
    'randomSeed': randomSeed,
    'relations': relations,
    'alliedForceIds': alliedForceIds.toList(),
    'revealedProvinceIds': revealedProvinceIds.toList(),
    'gameLog': gameLog,
    'lastEvent': lastEvent,
    'gameOver': gameOver,
    'outcome': outcome,
    'lastTurnReports': lastTurnReports
        .map(
          (r) => {
            'attackerName': r.attackerName,
            'defenderName': r.defenderName,
            'targetProvinceName': r.targetProvinceName,
            'attackerWon': r.attackerWon,
            'day': r.day,
            'attackerSoldiers': r.attackerSoldiers,
            'defenderSoldiers': r.defenderSoldiers,
          },
        )
        .toList(),
    'forces': forces
        .map(
          (f) => {
            'id': f.id,
            'name': f.name,
            'gold': f.gold,
            'food': f.food,
            'rulerId': f.rulerId,
            'provinceIds': f.provinceIds,
            'officerIds': f.officerIds,
            'aiPersonality': f.aiPersonality.name,
            'mapColorValue': f.mapColorValue,
            'bannerIndex': f.bannerIndex,
          },
        )
        .toList(),
    'provinces': provinces
        .map(
          (p) => {
            'id': p.id,
            'name': p.name,
            'ownerForceId': p.ownerForceId,
            'ownerName': p.ownerName,
            'adjacentProvinceIds': p.adjacentProvinceIds,
            'officerIds': p.officerIds,
            'land': p.land,
            'publicLoyalty': p.publicLoyalty,
            'soldiers': p.soldiers,
            'gold': p.gold,
            'food': p.food,
            'floodControl': p.floodControl,
            'mapX': p.mapX,
            'mapY': p.mapY,
            'governorId': p.governorId,
            'settlementType': p.settlementType,
            'territoryPoints': p.territoryPoints,
          },
        )
        .toList(),
    'officers': officers
        .map(
          (o) => {
            'id': o.id,
            'name': o.name,
            'forceId': o.forceId,
            'provinceId': o.provinceId,
            'war': o.war,
            'intelligence': o.intelligence,
            'charisma': o.charisma,
            'loyalty': o.loyalty,
            'status': o.status,
          },
        )
        .toList(),
  };

  static GameState fromSaveMap(Map<String, dynamic> data) {
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
            aiPersonality: AiPersonality.values.byName(
              x['aiPersonality'] as String? ?? 'opportunist',
            ),
            mapColorValue: (x['mapColorValue'] as num?)?.toInt() ?? 0xff8b7355,
            bannerIndex: (x['bannerIndex'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
    final state = GameState(
      scenarioId: data['scenarioId'],
      year: data['year'],
      month: data['month'],
      playerForceId: data['playerForceId'],
      randomSeed: data['randomSeed'],
      relations: Map<String, int>.from(data['relations'] ?? {}),
      alliedForceIds: Set<String>.from(data['alliedForceIds'] ?? []),
      revealedProvinceIds: Set<String>.from(data['revealedProvinceIds'] ?? []),
      gameLog: List<String>.from(data['gameLog'] ?? []),
      lastTurnReports: (data['lastTurnReports'] as List? ?? [])
          .map(
            (x) => AiBattleReport(
              attackerName: x['attackerName'],
              defenderName: x['defenderName'],
              targetProvinceName: x['targetProvinceName'],
              attackerWon: x['attackerWon'],
              day: x['day'],
              attackerSoldiers: x['attackerSoldiers'],
              defenderSoldiers: x['defenderSoldiers'],
            ),
          )
          .toList(),
      forces: forces,
      provinces: (data['provinces'] as List)
          .map(
            (x) => ProvinceState(
              id: x['id'],
              name: x['name'],
              ownerForceId: x['ownerForceId'],
              ownerName: x['ownerName'],
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
              settlementType: x['settlementType'] as String? ?? 'medium',
              territoryPoints: _territoryPoints(x['territoryPoints']),
              floodControl: (x['floodControl'] as num?)?.toInt() ?? 0,
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
    state.lastEvent = data['lastEvent'] as String?;
    state.gameOver = data['gameOver'] as bool? ?? false;
    state.outcome = data['outcome'] as String?;
    return state;
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
            aiPersonality: AiPersonality.values.byName(
              x['aiPersonality'] as String? ?? 'opportunist',
            ),
            mapColorValue: (x['mapColorValue'] as num?)?.toInt() ?? 0xff8b7355,
            bannerIndex: (x['bannerIndex'] as num?)?.toInt() ?? 0,
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
              settlementType: x['settlementType'] as String? ?? 'medium',
              territoryPoints: _territoryPoints(x['territoryPoints']),
              floodControl: (x['floodControl'] as num?)?.toInt() ?? 0,
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
