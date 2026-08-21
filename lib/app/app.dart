import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../battle/battle_engine.dart';
import '../battle/battle_state.dart';
import '../core/game_command.dart';
import '../core/game_engine.dart';
import '../data/demo_scenario.dart';
import '../flame/battle_game.dart';
import '../models/game_state.dart';
import '../repositories/save_repository.dart';

class CodexStrategyApp extends StatelessWidget {
  const CodexStrategyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Realm Ledger',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff385b4d)),
      useMaterial3: true,
    ),
    home: const HomeScreen(),
  );
}

Future<void> _loadSavedGame(BuildContext context) async {
  final repository = SaveRepository();
  const slots = ['AUTO', '1', '2', '3', '4', '5'];
  final saves = <String, Map<String, dynamic>>{};
  for (final slot in slots) {
    final save = await repository.load(slot);
    if (save != null) saves[slot] = save;
  }
  if (!context.mounted) return;
  final selectedSlot = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('불러오기'),
      children: slots
          .map(
            (slot) => SimpleDialogOption(
              onPressed: saves.containsKey(slot)
                  ? () => Navigator.pop(dialogContext, slot)
                  : null,
              child: Text(
                saves.containsKey(slot)
                    ? '$slot · ${saves[slot]!['year']}년 ${saves[slot]!['month']}월'
                    : '$slot · 비어 있음',
              ),
            ),
          )
          .toList(),
    ),
  );
  if (selectedSlot == null || !context.mounted) return;
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) =>
          GameScreen(initialState: GameState.fromSaveMap(saves[selectedSlot]!)),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scenario = DemoScenario.create();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.castle, size: 72, color: Color(0xff385b4d)),
                  const SizedBox(height: 16),
                  Text(
                    'REALM LEDGER',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '한 달의 명령으로 왕국의 운명을 바꾸십시오.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ScenarioSelectScreen(scenario: scenario),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('새 게임'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _loadSavedGame(context),
                    icon: const Icon(Icons.folder_open),
                    label: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('불러오기'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '프로토타입 · 193년 1월 · 6지역',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScenarioSelectScreen extends StatelessWidget {
  const ScenarioSelectScreen({super.key, required this.scenario});
  final Map<String, dynamic> scenario;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('시나리오 선택')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('가상 군웅 시나리오', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('6개 지역과 3개 세력이 패권을 다투는 기본 시나리오입니다.'),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('193년 · 군웅할거'),
              subtitle: const Text('난이도 보통 · 6지역 · 3세력 · 20장수'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RulerSelectScreen(scenario: scenario),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class RulerSelectScreen extends StatelessWidget {
  const RulerSelectScreen({super.key, required this.scenario});
  final Map<String, dynamic> scenario;
  @override
  Widget build(BuildContext context) {
    final forces = (scenario['forces'] as List).cast<Map<String, dynamic>>();
    final officers = (scenario['officers'] as List)
        .cast<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(title: const Text('군주 선택')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: forces.map((force) {
          final ruler = officers.firstWhere((o) => o['id'] == force['rulerId']);
          return Card(
            child: ListTile(
              isThreeLine: true,
              leading: CircleAvatar(child: Text('${ruler['war']}')),
              title: Text('${force['name']} · ${ruler['name']}'),
              subtitle: Text(
                '무력 ${ruler['war']} · 지력 ${ruler['intelligence']} · 매력 ${ruler['charisma']}\n영토 ${force['provinceIds'].length}곳 · 장수 ${force['officerIds'].length}명',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      GameScreen(playerForceId: force['id'] as String),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.playerForceId, this.initialState});
  final String? playerForceId;
  final GameState? initialState;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameEngine engine;
  final saveRepository = SaveRepository();
  String? selectedProvinceId;
  String? selectedOfficerId;
  @override
  void initState() {
    super.initState();
    engine = GameEngine(
      widget.initialState ??
          GameState.fromScenario(
            DemoScenario.create(),
            selectedForceId: widget.playerForceId,
          ),
    );
    selectedProvinceId = engine.state.playerProvinceIds.first;
    selectedOfficerId = engine.state.provinces.first.officerIds.first;
    engine.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartReport();
      _saveAuto();
    });
  }

  Future<void> _saveAuto() => saveRepository.save(engine.state, 'AUTO');

  Future<void> _showSaveDialog() async {
    const slots = ['1', '2', '3', '4', '5'];
    final slot = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('저장 슬롯'),
        children: slots
            .map(
              (value) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, value),
                child: Text('슬롯 $value'),
              ),
            )
            .toList(),
      ),
    );
    if (slot == null || !mounted) return;
    await saveRepository.save(engine.state, slot);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('슬롯 $slot에 저장했습니다.')));
  }

  void _showStartReport() {
    if (!mounted) return;
    final state = engine.state;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${state.year}년 ${state.month}월'),
        content: Text(
          '${state.playerForce.name}의 명령을 시작합니다.\n\n영토 ${state.playerProvinceIds.length}곳\n금 ${state.playerForce.gold}\n군량 ${state.playerForce.food}\n병력 ${state.playerSoldiers}\n\n장수를 선택해 이번 달 명령을 내리십시오.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('명령 시작'),
          ),
        ],
      ),
    );
  }

  void _refresh() => setState(() {});
  void _showOfficers() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OfficerSheet(state: engine.state),
    );
  }

  void _showLog() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _LogSheet(state: engine.state),
    );
  }

  void _startBattle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WarPreparationScreen(
          engine: engine,
          targetProvinceId: selectedProvinceId!,
        ),
      ),
    );
  }

  void _selectProvince(String id) {
    final province = engine.state.provinces.firstWhere((p) => p.id == id);
    setState(() {
      selectedProvinceId = id;
      selectedOfficerId = province.officerIds.isEmpty
          ? null
          : province.officerIds.first;
    });
  }

  Future<void> _dispatch(GameCommand command) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_commandTitle(command.type)),
        content: Text(
          '${_commandDescription(command.type)}\n\n담당 장수: ${_officerName(command.officerId)}\n대상 지역: ${selectedProvinceId ?? '-'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('실행'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = engine.dispatch(command);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  String _officerName(String? id) => id == null
      ? '없음'
      : engine.state.officers.firstWhere((o) => o.id == id).name;
  String _commandTitle(GameCommandType type) => switch (type) {
    GameCommandType.develop => '개발',
    GameCommandType.recruit => '징병',
    GameCommandType.tax => '징세',
    GameCommandType.relief => '시혜',
    GameCommandType.train => '훈련',
    GameCommandType.fortify => '축성',
    GameCommandType.search => '탐색',
    GameCommandType.recruitOfficer => '등용',
    GameCommandType.appointGovernor => '태수 임명',
    GameCommandType.moveOfficer => '장수 이동',
    GameCommandType.giftForce => '외교 · 선물',
    GameCommandType.formAlliance => '외교 · 동맹',
    GameCommandType.threatenForce => '외교 · 협박',
    GameCommandType.infiltrate => '첩보 · 잠입',
    GameCommandType.inciteOfficer => '첩보 · 이간',
    GameCommandType.spreadRumor => '첩보 · 유언비어',
    GameCommandType.endMonth => '턴 종료',
  };
  String _commandDescription(GameCommandType type) => switch (type) {
    GameCommandType.develop => '토지와 군량 생산 기반을 높입니다. 금 100을 사용합니다.',
    GameCommandType.recruit => '민심을 바탕으로 병력을 모집합니다. 금 80을 사용합니다.',
    GameCommandType.tax => '즉시 금을 얻지만 민심이 하락합니다.',
    GameCommandType.relief => '금 80을 사용해 민심을 높입니다.',
    GameCommandType.train => '지역 군대의 훈련을 높입니다. 금 60을 사용합니다.',
    GameCommandType.fortify => '지역 방어 기반을 높입니다. 금 120을 사용합니다.',
    GameCommandType.search => '재야 인재와 아이템을 탐색합니다.',
    GameCommandType.recruitOfficer => '발견한 재야 장수를 금 200으로 등용합니다.',
    GameCommandType.appointGovernor => '선택한 장수를 이 지역의 태수로 임명합니다.',
    GameCommandType.moveOfficer => '인접한 아군 지역으로 장수를 이동합니다.',
    GameCommandType.giftForce => '금 100으로 관계를 개선합니다.',
    GameCommandType.formAlliance => '관계 20 이상인 세력과 동맹을 맺습니다.',
    GameCommandType.threatenForce => '관계를 악화시키고 동맹을 파기합니다.',
    GameCommandType.infiltrate => '적 영지 정보를 공개합니다. 금 80을 사용합니다.',
    GameCommandType.inciteOfficer => '적 장수의 충성도를 낮춥니다. 금 100을 사용합니다.',
    GameCommandType.spreadRumor => '적 영지의 민심을 낮춥니다. 금 80을 사용합니다.',
    GameCommandType.endMonth => '모든 세력의 명령을 처리하고 다음 달로 넘어갑니다.',
  };

  Future<void> _showMoveDialog() async {
    final selected = engine.state.provinces.firstWhere(
      (p) => p.id == selectedProvinceId,
    );
    final destinations = engine.state.provinces
        .where(
          (p) =>
              engine.state.isPlayerProvince(p) &&
              selected.adjacentProvinceIds.contains(p.id),
        )
        .toList();
    if (destinations.isEmpty || selectedOfficerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 장수가 이동할 수 있는 인접 아군 지역이 없습니다.')),
      );
      return;
    }
    final destination = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('이동할 지역 선택'),
        children: destinations
            .map(
              (p) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, p.id),
                child: Text('${p.name} · 장수 ${p.officerIds.length}명'),
              ),
            )
            .toList(),
      ),
    );
    if (destination != null && mounted) {
      await _dispatch(
        GameCommand(
          type: GameCommandType.moveOfficer,
          officerId: selectedOfficerId,
          provinceId: selected.id,
          destinationProvinceId: destination,
        ),
      );
    }
  }

  Future<void> _showDiplomacyDialog() async {
    final targets = engine.state.forces
        .where((f) => f.id != engine.state.playerForceId)
        .toList();
    if (targets.isEmpty || selectedOfficerId == null) return;
    var targetId = targets.first.id;
    final choice = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('외교'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                value: targetId,
                items: targets
                    .map(
                      (force) => DropdownMenuItem(
                        value: force.id,
                        child: Text(
                          '${force.name} · 관계 ${engine.state.relationTo(force.id)}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id != null) setDialogState(() => targetId = id);
                },
              ),
              const SizedBox(height: 8),
              Text('현재 관계 ${engine.state.relationTo(targetId)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'forceId': targetId,
                'action': 'gift',
              }),
              child: const Text('선물 100금'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'forceId': targetId,
                'action': 'alliance',
              }),
              child: const Text('동맹'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, {
                'forceId': targetId,
                'action': 'threaten',
              }),
              child: const Text('협박'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final type = switch (choice['action']) {
      'gift' => GameCommandType.giftForce,
      'alliance' => GameCommandType.formAlliance,
      _ => GameCommandType.threatenForce,
    };
    await _dispatch(
      GameCommand(
        type: type,
        officerId: selectedOfficerId,
        provinceId: selectedProvinceId,
        targetForceId: choice['forceId'],
      ),
    );
  }

  Future<void> _showEspionageDialog() async {
    final targets = engine.state.provinces
        .where((p) => !engine.state.isPlayerProvince(p))
        .toList();
    if (targets.isEmpty || selectedOfficerId == null) return;
    var provinceId = targets.first.id;
    var action = 'infiltrate';
    String? officerId;
    final choice = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final province = engine.state.provinces.firstWhere(
            (p) => p.id == provinceId,
          );
          final enemyOfficers = engine.state.officers
              .where((o) => province.officerIds.contains(o.id))
              .toList();
          officerId ??= enemyOfficers.firstOrNull?.id;
          return AlertDialog(
            title: const Text('첩보'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  isExpanded: true,
                  value: provinceId,
                  items: targets
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} · 민심 ${p.publicLoyalty}'),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id != null) {
                      setDialogState(() {
                        provinceId = id;
                        officerId = null;
                      });
                    }
                  },
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: action,
                  items: const [
                    DropdownMenuItem(value: 'infiltrate', child: Text('잠입')),
                    DropdownMenuItem(value: 'incite', child: Text('이간')),
                    DropdownMenuItem(value: 'rumor', child: Text('유언비어')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => action = value);
                  },
                ),
                if (action == 'incite' && enemyOfficers.isNotEmpty)
                  DropdownButton<String>(
                    isExpanded: true,
                    value: officerId,
                    items: enemyOfficers
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.id,
                            child: Text('${o.name} · 충성 ${o.loyalty}'),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) setDialogState(() => officerId = id);
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, {
                  'provinceId': provinceId,
                  'action': action,
                  if (officerId != null) 'officerId': officerId!,
                }),
                child: const Text('실행'),
              ),
            ],
          );
        },
      ),
    );
    if (choice == null || !mounted) return;
    final type = switch (choice['action']) {
      'incite' => GameCommandType.inciteOfficer,
      'rumor' => GameCommandType.spreadRumor,
      _ => GameCommandType.infiltrate,
    };
    await _dispatch(
      GameCommand(
        type: type,
        officerId: selectedOfficerId,
        provinceId: choice['provinceId'],
        targetOfficerId: choice['officerId'],
      ),
    );
  }

  Future<void> _endMonth() async {
    final beforeGold = engine.state.playerForce.gold;
    final beforeFood = engine.state.playerForce.food;
    engine.dispatch(const GameCommand(type: GameCommandType.endMonth));
    await _saveAuto();
    if (!mounted) return;
    final state = engine.state;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${state.year}년 ${state.month}월 시작'),
        content: Text(
          '지난달 정산\n금 $beforeGold → ${state.playerForce.gold}\n군량 $beforeFood → ${state.playerForce.food}\n영토 ${state.playerProvinceIds.length}곳',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    engine.removeListener(_refresh);
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = engine.state;
    final selected = state.provinces.firstWhere(
      (p) => p.id == selectedProvinceId,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('${state.year}년 ${state.month}월'),
        actions: [
          IconButton(
            onPressed: _showOfficers,
            tooltip: '장수',
            icon: const Icon(Icons.people_alt_outlined),
          ),
          IconButton(
            onPressed: _showLog,
            tooltip: '기록',
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            onPressed: _showSaveDialog,
            tooltip: '저장',
            icon: const Icon(Icons.save_outlined),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(child: Text(state.playerForce.name)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ResourceBar(force: state.playerForce, state: state),
            Expanded(
              child: _Map(
                provinces: state.provinces,
                playerForceId: state.playerForceId,
                revealedProvinceIds: state.revealedProvinceIds,
                selectedId: selectedProvinceId,
                onSelect: _selectProvince,
              ),
            ),
            _ProvincePanel(
              province: selected,
              playerOwned: state.isPlayerProvince(selected),
              informationRevealed:
                  state.isPlayerProvince(selected) ||
                  state.revealedProvinceIds.contains(selected.id),
              governorName: selected.governorId == null
                  ? '미임명'
                  : state.officers
                        .firstWhere((o) => o.id == selected.governorId)
                        .name,
            ),
            if (state.isPlayerProvince(selected))
              _OfficerSelector(
                province: selected,
                officers: state.officers,
                selectedOfficerId: selectedOfficerId,
                onSelect: (id) => setState(() => selectedOfficerId = id),
              ),
            _ActionBar(
              engine: engine,
              province: selected,
              playerOwned: state.isPlayerProvince(selected),
              onBattle: _startBattle,
              officerId: selectedOfficerId,
              onDispatch: _dispatch,
              onEndMonth: _endMonth,
              onMove: _showMoveDialog,
              onDiplomacy: _showDiplomacyDialog,
              onEspionage: _showEspionageDialog,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceBar extends StatelessWidget {
  const _ResourceBar({required this.force, required this.state});
  final ForceState force;
  final GameState state;
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xffeef3ef),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Metric('금', force.gold),
        _Metric('군량', force.food),
        _Metric('영토', state.playerProvinceIds.length),
        _Metric('병력', state.playerSoldiers),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

class _Map extends StatelessWidget {
  const _Map({
    required this.provinces,
    required this.playerForceId,
    required this.revealedProvinceIds,
    required this.selectedId,
    required this.onSelect,
  });
  final List<ProvinceState> provinces;
  final String playerForceId;
  final Set<String> revealedProvinceIds;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.clamp(280.0, 520.0);
      return Center(
        child: SizedBox(
          width: width,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _RoadPainter(provinces)),
              ),
              ...provinces.map(
                (p) => Positioned(
                  left: p.mapX * width - 34,
                  top: p.mapY * constraints.maxHeight - 34,
                  child: GestureDetector(
                    onTap: () => onSelect(p.id),
                    child: _ProvinceNode(
                      province: p,
                      playerOwned: p.isOwnedBy(playerForceId),
                      informationRevealed:
                          p.isOwnedBy(playerForceId) ||
                          revealedProvinceIds.contains(p.id),
                      selected: p.id == selectedId,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RoadPainter extends CustomPainter {
  _RoadPainter(this.provinces);
  final List<ProvinceState> provinces;
  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final p in provinces) p.id: p};
    final paint = Paint()
      ..color = const Color(0xffb3c7ba)
      ..strokeWidth = 3;
    for (final p in provinces) {
      for (final id in p.adjacentProvinceIds) {
        final q = byId[id];
        if (q != null && p.id.compareTo(q.id) < 0) {
          canvas.drawLine(
            Offset(p.mapX * size.width, p.mapY * size.height),
            Offset(q.mapX * size.width, q.mapY * size.height),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => false;
}

class _ProvinceNode extends StatelessWidget {
  const _ProvinceNode({
    required this.province,
    required this.selected,
    required this.playerOwned,
    required this.informationRevealed,
  });
  final ProvinceState province;
  final bool selected;
  final bool playerOwned;
  final bool informationRevealed;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: playerOwned
              ? const Color(0xff557c68)
              : const Color(0xffb97b5c),
          border: Border.all(
            color: selected ? Colors.amber : Colors.white,
            width: selected ? 4 : 2,
          ),
          boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)],
        ),
        child: Center(
          child: Text(
            province.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
      Text(
        informationRevealed ? '${province.soldiers}명' : '????명',
        style: const TextStyle(fontSize: 11),
      ),
    ],
  );
}

class _ProvincePanel extends StatelessWidget {
  const _ProvincePanel({
    required this.province,
    required this.playerOwned,
    required this.governorName,
    required this.informationRevealed,
  });
  final ProvinceState province;
  final bool playerOwned;
  final String governorName;
  final bool informationRevealed;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            informationRevealed
                ? '${province.name} · ${province.ownerName}\n태수 $governorName · 개발 ${province.land} · 민심 ${province.publicLoyalty} · 병력 ${province.soldiers} · 장수 ${province.officerIds.length}'
                : '${province.name} · ${province.ownerName}\n태수 ???? · 개발 ???? · 민심 ???? · 병력 ???? · 장수 ${province.officerIds.length}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          playerOwned ? '내 영지' : '타 세력',
          style: TextStyle(color: playerOwned ? Colors.green : Colors.red),
        ),
      ],
    ),
  );
}

class _OfficerSelector extends StatelessWidget {
  const _OfficerSelector({
    required this.province,
    required this.officers,
    required this.selectedOfficerId,
    required this.onSelect,
  });
  final ProvinceState province;
  final List<OfficerState> officers;
  final String? selectedOfficerId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final local = officers
        .where((o) => province.officerIds.contains(o.id))
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 18),
          const SizedBox(width: 6),
          const Text('담당 장수'),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: local.any((o) => o.id == selectedOfficerId)
                  ? selectedOfficerId
                  : null,
              hint: const Text('장수를 선택하세요'),
              items: local
                  .map(
                    (o) => DropdownMenuItem(
                      value: o.id,
                      child: Text(
                        '${o.name} · 충성 ${o.loyalty}${o.id == selectedOfficerId && o.status == 'RULER' ? ' · 군주' : ''}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id != null) onSelect(id);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.engine,
    required this.province,
    required this.playerOwned,
    required this.onBattle,
    required this.officerId,
    required this.onDispatch,
    required this.onEndMonth,
    required this.onMove,
    required this.onDiplomacy,
    required this.onEspionage,
  });
  final GameEngine engine;
  final ProvinceState province;
  final bool playerOwned;
  final VoidCallback onBattle;
  final String? officerId;
  final ValueChanged<GameCommand> onDispatch;
  final VoidCallback onEndMonth;
  final VoidCallback onMove;
  final VoidCallback onDiplomacy;
  final VoidCallback onEspionage;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null
              ? () => onDispatch(
                  GameCommand(
                    type: GameCommandType.develop,
                    officerId: officerId,
                    provinceId: province.id,
                  ),
                )
              : null,
          child: const Text('개발'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null
              ? () => onDispatch(
                  GameCommand(
                    type: GameCommandType.recruit,
                    officerId: officerId,
                    provinceId: province.id,
                  ),
                )
              : null,
          child: const Text('징병'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null ? onMove : null,
          child: const Text('장수 이동'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null ? onDiplomacy : null,
          child: const Text('외교'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null ? onEspionage : null,
          child: const Text('첩보'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null
              ? () => onDispatch(
                  GameCommand(
                    type: GameCommandType.tax,
                    officerId: officerId,
                    provinceId: province.id,
                  ),
                )
              : null,
          child: const Text('징세'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null
              ? () => onDispatch(
                  GameCommand(
                    type: GameCommandType.relief,
                    officerId: officerId,
                    provinceId: province.id,
                  ),
                )
              : null,
          child: const Text('시혜'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null
              ? () => onDispatch(
                  GameCommand(
                    type: GameCommandType.train,
                    officerId: officerId,
                    provinceId: province.id,
                  ),
                )
              : null,
          child: const Text('훈련'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null
              ? () => onDispatch(
                  GameCommand(
                    type: GameCommandType.fortify,
                    officerId: officerId,
                    provinceId: province.id,
                  ),
                )
              : null,
          child: const Text('축성'),
        ),
        FilledButton(
          onPressed: playerOwned ? null : onBattle,
          child: const Text('출병'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null
              ? () => onDispatch(
                  GameCommand(
                    type: GameCommandType.search,
                    officerId: officerId,
                    provinceId: province.id,
                  ),
                )
              : null,
          child: const Text('탐색'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && officerId != null
              ? () => onDispatch(
                  GameCommand(
                    type: GameCommandType.appointGovernor,
                    officerId: officerId,
                    provinceId: province.id,
                  ),
                )
              : null,
          child: const Text('태수 임명'),
        ),
        FilledButton.tonal(
          onPressed: playerOwned && engine.firstFreeOfficer != null
              ? () => onDispatch(
                  GameCommand(
                    type: GameCommandType.recruitOfficer,
                    officerId: officerId,
                    provinceId: province.id,
                    targetOfficerId: engine.firstFreeOfficer!.id,
                  ),
                )
              : null,
          child: const Text('등용'),
        ),
        FilledButton(onPressed: onEndMonth, child: const Text('턴 종료')),
      ],
    ),
  );
}

class WarPreparationScreen extends StatefulWidget {
  const WarPreparationScreen({
    super.key,
    required this.engine,
    required this.targetProvinceId,
  });
  final GameEngine engine;
  final String targetProvinceId;
  @override
  State<WarPreparationScreen> createState() => _WarPreparationScreenState();
}

class _WarPreparationScreenState extends State<WarPreparationScreen> {
  late List<ProvinceState> sources;
  String? sourceId;
  String? commanderId;
  final Set<String> selectedOfficerIds = <String>{};
  double committed = 100;
  @override
  void initState() {
    super.initState();
    final target = widget.engine.state.provinces.firstWhere(
      (p) => p.id == widget.targetProvinceId,
    );
    sources = widget.engine.state.provinces
        .where(
          (p) =>
              widget.engine.state.isPlayerProvince(p) &&
              p.adjacentProvinceIds.contains(target.id) &&
              p.soldiers >= 100,
        )
        .toList();
    sourceId = sources.isEmpty ? null : sources.first.id;
    if (sources.isNotEmpty) {
      committed = (sources.first.soldiers * .65).roundToDouble();
      selectedOfficerIds.addAll(sources.first.officerIds);
      commanderId = sources.first.officerIds.firstOrNull;
    }
  }

  ProvinceState? get source =>
      sourceId == null ? null : sources.firstWhere((p) => p.id == sourceId);
  void _launch() {
    final battle = sourceId == null
        ? null
        : widget.engine.beginBattlePrepared(
            sourceProvinceId: sourceId!,
            targetProvinceId: widget.targetProvinceId,
            committedSoldiers: committed.round(),
            participantOfficerIds: selectedOfficerIds.toList(),
            commanderOfficerId: commanderId,
          );
    if (battle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출병 조건을 만족하지 못했습니다. 군량과 병력을 확인하세요.')),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BattleScreen(engine: widget.engine, battle: battle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.engine.state.provinces.firstWhere(
      (p) => p.id == widget.targetProvinceId,
    );
    final current = source;
    final max = current?.soldiers.toDouble() ?? 100;
    return Scaffold(
      appBar: AppBar(title: const Text('출병 준비')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '목표 지역  ${target.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('방어 병력 ${target.soldiers} · 소유 ${target.ownerName}'),
            const SizedBox(height: 18),
            const Text('출발지', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: sourceId,
              items: sources
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} · 병력 ${p.soldiers}'),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id != null) {
                  setState(() {
                    sourceId = id;
                    committed = (source!.soldiers * .65).roundToDouble();
                    selectedOfficerIds
                      ..clear()
                      ..addAll(source!.officerIds);
                    commanderId = source!.officerIds.firstOrNull;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            const Text('출전 장수', style: TextStyle(fontWeight: FontWeight.bold)),
            if (current != null)
              ...current.officerIds.map((id) {
                final officer = widget.engine.state.officers.firstWhere(
                  (o) => o.id == id,
                );
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: selectedOfficerIds.contains(id),
                  title: Text('${officer.name} · WAR ${officer.war}'),
                  subtitle: Text(
                    selectedOfficerIds.contains(id) && commanderId == id
                        ? '총대장'
                        : '출전 가능',
                  ),
                  onChanged: (value) {
                    if (value == false && selectedOfficerIds.length == 1) {
                      return;
                    }
                    setState(() {
                      if (value == true) {
                        selectedOfficerIds.add(id);
                        commanderId ??= id;
                      } else {
                        selectedOfficerIds.remove(id);
                        if (commanderId == id) {
                          commanderId = selectedOfficerIds.firstOrNull;
                        }
                      }
                    });
                  },
                );
              }),
            if (selectedOfficerIds.isNotEmpty)
              DropdownButton<String>(
                isExpanded: true,
                value: commanderId,
                items: selectedOfficerIds.map((id) {
                  final o = widget.engine.state.officers.firstWhere(
                    (x) => x.id == id,
                  );
                  return DropdownMenuItem(
                    value: id,
                    child: Text('총대장: ${o.name} · WAR ${o.war}'),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) setState(() => commanderId = id);
                },
              ),
            const Text(
              '총대장 및 출전 병력',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              current == null || current.officerIds.isEmpty
                  ? '총대장 없음'
                  : '${widget.engine.state.officers.firstWhere((o) => o.id == current.officerIds.first).name} · ${committed.round()}명',
            ),
            Slider(
              min: 100,
              max: max < 100 ? 100 : max,
              divisions: max <= 100 ? 1 : (max - 100).round(),
              value: committed.clamp(100, max < 100 ? 100 : max),
              label: '${committed.round()}',
              onChanged: current == null
                  ? null
                  : (value) => setState(() => committed = value),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  '출병 비용\n군량 -150\n출전 병력 ${committed.round()}\n예상 잔여 병력 ${(current?.soldiers ?? 0) - committed.round()}',
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: current == null ? null : _launch,
              icon: const Icon(Icons.flag),
              label: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('출병 확정'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }
}

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.engine, required this.battle});
  final GameEngine engine;
  final BattleEngine battle;
  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  String? selectedAttackerId;
  String? selectedDefenderId;
  late final BattleGame battleGame;

  @override
  void initState() {
    super.initState();
    selectedAttackerId =
        widget.battle.state.attackerUnits.firstOrNull?.officerId;
    selectedDefenderId =
        widget.battle.state.defenderUnits.firstOrNull?.officerId;
    battleGame = BattleGame(widget.battle.state);
  }

  void _act(BattleAction action) {
    if (selectedAttackerId == null || selectedDefenderId == null) {
      widget.battle.attack();
    } else {
      widget.battle.act(
        attackerId: selectedAttackerId!,
        defenderId: selectedDefenderId!,
        action: action,
      );
    }
    setState(() {});
    battleGame.refreshBoard();
    _finishIfNeeded();
  }

  Future<void> _moveSelected() async {
    final unit = widget.battle.state.attackerUnits
        .where((u) => u.officerId == selectedAttackerId)
        .firstOrNull;
    if (unit == null) return;
    final cells = <List<int>>[];
    for (final delta in const [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ]) {
      final row = unit.row + delta[0];
      final column = unit.column + delta[1];
      if (row >= 0 && row < 5 && column >= 0 && column < 6) {
        cells.add([row, column]);
      }
    }
    final target = await showDialog<List<int>>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('이동할 칸 선택'),
        children: cells
            .map(
              (cell) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, cell),
                child: Text('행 ${cell[0] + 1} · 열 ${cell[1] + 1}'),
              ),
            )
            .toList(),
      ),
    );
    if (target == null || !mounted) return;
    if (!widget.battle.moveUnit(unit.officerId, target[0], target[1])) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('그 칸으로 이동할 수 없습니다.')));
      return;
    }
    setState(() {});
    battleGame.refreshBoard();
  }

  Future<void> _finishIfNeeded() async {
    if (!widget.battle.state.finished) return;
    final outcomes = widget.engine.resolveBattle(widget.battle);
    final remainingPrisoners = outcomes
        .where((o) => o.result == BattleOfficerResult.captured)
        .toList();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              widget.battle.state.attackerWon ? '전투 결과 · 승리' : '전투 결과 · 패배',
            ),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.battle.state.attackerWon
                          ? '목표 지역을 점령했습니다.'
                          : '공격군이 후퇴했습니다.',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.battle.state.returnedSoldiers}명이 '
                      '${widget.battle.state.returnProvinceId == widget.battle.state.targetProvinceId ? '점령지에 주둔했습니다.' : '출발지로 귀환했습니다.'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...outcomes.map(
                      (outcome) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          '${outcome.name} · ${_battleResultLabel(outcome.result)} · ${outcome.soldiers}명',
                        ),
                      ),
                    ),
                    if (remainingPrisoners.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        '포로 처리',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...remainingPrisoners.map(
                        (prisoner) => Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prisoner.name),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      final handled = widget.engine
                                          .handlePrisoner(
                                            prisoner.officerId,
                                            PrisonerAction.recruit,
                                            widget
                                                .battle
                                                .state
                                                .targetProvinceId,
                                          );
                                      if (handled) {
                                        setDialogState(
                                          () => remainingPrisoners.remove(
                                            prisoner,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('등용 500금'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      widget.engine.handlePrisoner(
                                        prisoner.officerId,
                                        PrisonerAction.release,
                                        widget.battle.state.targetProvinceId,
                                      );
                                      setDialogState(
                                        () =>
                                            remainingPrisoners.remove(prisoner),
                                      );
                                    },
                                    child: const Text('석방'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      widget.engine.handlePrisoner(
                                        prisoner.officerId,
                                        PrisonerAction.execute,
                                        widget.battle.state.targetProvinceId,
                                      );
                                      setDialogState(
                                        () =>
                                            remainingPrisoners.remove(prisoner),
                                      );
                                    },
                                    child: const Text('처형'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              FilledButton(
                onPressed: remainingPrisoners.isEmpty
                    ? () => Navigator.pop(dialogContext)
                    : null,
                child: const Text('확인'),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted) return;
    final message = widget.battle.state.attackerWon
        ? '전투 승리! 목표 지역을 점령했습니다.'
        : '전투 패배. 병력이 후퇴했습니다.';
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _battleResultLabel(BattleOfficerResult result) => switch (result) {
    BattleOfficerResult.escaped => '퇴각',
    BattleOfficerResult.captured => '포로',
    BattleOfficerResult.dead => '전사',
  };

  @override
  Widget build(BuildContext context) {
    final battle = widget.battle.state;
    return Scaffold(
      appBar: AppBar(title: Text('전투 · ${battle.day}일째')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: const Color(0xff263b35),
                child: GameWidget(game: battleGame),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '${battle.attackerName}\n${battle.attackerSoldiers}명',
                        textAlign: TextAlign.center,
                      ),
                      const Text('VS'),
                      Text(
                        '${battle.defenderName}\n${battle.defenderSoldiers}명',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '전투 군량 ${battle.attackerFood} · 일일 소모 ${battle.dailySupplyCost} · 사기 ${battle.attackerMorale}'
                      '${battle.supplyShortageDays > 0 ? ' · 보급 부족 ${battle.supplyShortageDays}일' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: battle.supplyShortageDays > 0
                            ? Colors.red
                            : null,
                      ),
                    ),
                  ),
                  if (battle.attackerUnits.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '출전 부대 · 총대장 ${battle.commanderName} (WAR ${battle.commanderWar})\n${battle.attackerUnits.map((u) => '${u.name} ${u.soldiers}명').join('  ·  ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (battle.attackerUnits.isNotEmpty &&
                      battle.defenderUnits.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedAttackerId,
                            items: battle.attackerUnits
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u.officerId,
                                    child: Text('${u.name} ${u.soldiers}'),
                                  ),
                                )
                                .toList(),
                            onChanged: battle.finished
                                ? null
                                : (id) =>
                                      setState(() => selectedAttackerId = id),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('→'),
                        ),
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedDefenderId,
                            items: battle.defenderUnits
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u.officerId,
                                    child: Text('${u.name} ${u.soldiers}'),
                                  ),
                                )
                                .toList(),
                            onChanged: battle.finished
                                ? null
                                : (id) =>
                                      setState(() => selectedDefenderId = id),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: battle.finished
                              ? null
                              : () => _act(BattleAction.attack),
                          icon: const Icon(Icons.gavel),
                          label: const Text('공격'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: battle.finished
                              ? null
                              : () => _act(BattleAction.fire),
                          child: const Text('화공'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: battle.finished
                              ? null
                              : () => _act(BattleAction.charge),
                          child: const Text('돌격'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: battle.finished
                              ? null
                              : () => _act(BattleAction.wait),
                          child: const Text('대기'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: battle.finished ? null : _moveSelected,
                          child: const Text('이동'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: battle.finished
                              ? null
                              : () {
                                  widget.battle.retreat();
                                  _finishIfNeeded();
                                },
                          icon: const Icon(Icons.undo),
                          label: const Text('퇴각'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficerSheet extends StatelessWidget {
  const _OfficerSheet({required this.state});
  final GameState state;
  @override
  Widget build(BuildContext context) {
    final officers = state.officers
        .where((o) => o.forceId == state.playerForceId)
        .toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('우리 세력 장수', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...officers.map(
              (o) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${o.war}')),
                title: Text(o.name),
                subtitle: Text(
                  '무력 ${o.war} · 지력 ${o.intelligence} · 매력 ${o.charisma}',
                ),
                trailing: Text('충성 ${o.loyalty}'),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => _OfficerDetailDialog(officer: o),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficerDetailDialog extends StatelessWidget {
  const _OfficerDetailDialog({required this.officer});
  final OfficerState officer;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(officer.name),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('상태: ${officer.status}'),
        Text('소속 지역: ${officer.provinceId}'),
        const Divider(),
        Text('WAR  ${officer.war}'),
        Text('INT  ${officer.intelligence}'),
        Text('CHA  ${officer.charisma}'),
        Text('충성도  ${officer.loyalty}'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('닫기'),
      ),
    ],
  );
}

class _LogSheet extends StatelessWidget {
  const _LogSheet({required this.state});
  final GameState state;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: 360,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('월별 기록', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: state.gameLog.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    state.gameLog[state.gameLog.length - 1 - i],
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
