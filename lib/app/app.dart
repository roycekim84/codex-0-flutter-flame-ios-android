import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../battle/battle_engine.dart';
import '../core/game_command.dart';
import '../core/game_engine.dart';
import '../data/demo_scenario.dart';
import '../flame/battle_game.dart';
import '../models/game_state.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scenario = DemoScenario.create();
    final forces = (scenario['forces'] as List).cast<Map<String, dynamic>>();
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
                  Text(
                    '새 게임 · 가상 군웅 시나리오',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...forces.map(
                    (force) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameScreen(
                              playerForceId: force['id'] as String,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.shield_outlined),
                        label: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(force['name'] as String),
                        ),
                      ),
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

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.playerForceId});
  final String playerForceId;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameEngine engine;
  String? selectedProvinceId;
  String? selectedOfficerId;
  @override
  void initState() {
    super.initState();
    engine = GameEngine(
      GameState.fromScenario(
        DemoScenario.create(),
        selectedForceId: widget.playerForceId,
      ),
    );
    selectedProvinceId = engine.state.playerProvinceIds.first;
    selectedOfficerId = engine.state.provinces.first.officerIds.first;
    engine.addListener(_refresh);
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
    final battle = engine.beginBattle(selectedProvinceId!);
    if (battle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인접한 아군 영지에 출병 가능한 병력이 없거나 군량이 부족합니다.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BattleScreen(engine: engine, battle: battle),
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
    GameCommandType.endMonth => '모든 세력의 명령을 처리하고 다음 달로 넘어갑니다.',
  };

  void _endMonth() {
    final beforeGold = engine.state.playerForce.gold;
    final beforeFood = engine.state.playerForce.food;
    engine.dispatch(const GameCommand(type: GameCommandType.endMonth));
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
                selectedId: selectedProvinceId,
                onSelect: _selectProvince,
              ),
            ),
            _ProvincePanel(
              province: selected,
              playerOwned: state.isPlayerProvince(selected),
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
    required this.selectedId,
    required this.onSelect,
  });
  final List<ProvinceState> provinces;
  final String playerForceId;
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
  });
  final ProvinceState province;
  final bool selected;
  final bool playerOwned;
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
      Text('${province.soldiers}명', style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _ProvincePanel extends StatelessWidget {
  const _ProvincePanel({required this.province, required this.playerOwned});
  final ProvinceState province;
  final bool playerOwned;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${province.name} · ${province.ownerName}\n개발 ${province.land}  민심 ${province.publicLoyalty}  장수 ${province.officerIds.length}',
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
  });
  final GameEngine engine;
  final ProvinceState province;
  final bool playerOwned;
  final VoidCallback onBattle;
  final String? officerId;
  final ValueChanged<GameCommand> onDispatch;
  final VoidCallback onEndMonth;
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
        FilledButton.tonal(onPressed: null, child: const Text('장수 이동')),
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

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.engine, required this.battle});
  final GameEngine engine;
  final BattleEngine battle;
  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  void _finishIfNeeded() {
    if (!widget.battle.state.finished) return;
    widget.engine.resolveBattle(widget.battle);
    final message = widget.battle.state.attackerWon
        ? '전투 승리! 목표 지역을 점령했습니다.'
        : '전투 패배. 병력이 후퇴했습니다.';
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
                child: GameWidget(game: BattleGame(battle)),
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: battle.finished
                              ? null
                              : () {
                                  setState(widget.battle.attack);
                                  _finishIfNeeded();
                                },
                          icon: const Icon(Icons.gavel),
                          label: const Text('공격'),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
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
