import 'dart:async';

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
import '../core/asset_repository.dart';
import '../core/asset_precache.dart';
import '../ui/widgets/asset_widgets.dart';

class CodexStrategyApp extends StatelessWidget {
  const CodexStrategyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Realm Ledger',
    debugShowCheckedModeBanner: false,
    builder: (context, child) {
      AssetPrecache.schedule(context);
      return child ?? const SizedBox.shrink();
    },
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff9a7138),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xff171612),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff1d1a15),
        foregroundColor: Color(0xfff1dfb4),
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xff29241b),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xff665337)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xff72542c),
          foregroundColor: const Color(0xffffedc4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xffa8844b)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xffe0b96e)),
      ),
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

class _RealmBackdrop extends StatelessWidget {
  const _RealmBackdrop({
    required this.child,
    this.asset = 'assets/images/title_background.png',
  });
  final Widget child;
  final String asset;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(asset, fit: BoxFit.cover),
      Container(color: Colors.black.withValues(alpha: .46)),
      child,
    ],
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scenario = DemoScenario.create();
    return Scaffold(
      body: _RealmBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth.clamp(260.0, 420.0);
              final crestSize = (constraints.maxHeight * .19).clamp(
                112.0,
                164.0,
              );
              return Center(
                child: SizedBox(
                  width: contentWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Image.asset(
                        AssetRepository.titleCrest,
                        width: crestSize,
                        height: crestSize,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '군웅의 시대',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                              color: const Color(0xfff0d59a),
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 12,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'THE THREE REALMS',
                        style: TextStyle(
                          color: Color(0xffd5bd8c),
                          fontSize: 12,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Spacer(flex: 3),
                      _TitleMenuButton(
                        label: '새 게임',
                        primary: true,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ScenarioSelectScreen(scenario: scenario),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TitleMenuButton(
                        label: '불러오기',
                        onPressed: () => _loadSavedGame(context),
                      ),
                      const SizedBox(height: 10),
                      _TitleMenuButton(
                        label: '설정',
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('설정 화면은 다음 단계에서 연결됩니다.'),
                              ),
                            ),
                      ),
                      const SizedBox(height: 10),
                      _TitleMenuButton(
                        label: '게임 종료',
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('모바일에서는 홈 버튼으로 게임을 종료할 수 있습니다.'),
                              ),
                            ),
                      ),
                      const Spacer(flex: 2),
                      const Text(
                        'ORIGINAL STRATEGY GAME  ·  193년 1월',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xffb29a71),
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TitleMenuButton extends StatelessWidget {
  const _TitleMenuButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: primary
            ? const Color(0xff75562d).withValues(alpha: .96)
            : const Color(0xff1f2928).withValues(alpha: .94),
        foregroundColor: primary
            ? const Color(0xffffe6a9)
            : const Color(0xffe2d0a8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: BorderSide(
            color: primary ? const Color(0xffd4aa60) : const Color(0xff806742),
            width: primary ? 1.4 : 1,
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black87,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class ScenarioSelectScreen extends StatefulWidget {
  const ScenarioSelectScreen({super.key, required this.scenario});
  final Map<String, dynamic> scenario;

  @override
  State<ScenarioSelectScreen> createState() => _ScenarioSelectScreenState();
}

class _ScenarioSelectScreenState extends State<ScenarioSelectScreen> {
  int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final scenarios = [
      ('184년 · 황혼의 반란', '난이도 쉬움 · 6지역 · 3세력', '평화로운 봄의 시작'),
      ('193년 · 군웅할거', '난이도 보통 · 6지역 · 3세력', '가상의 군웅들이 패권을 다툼'),
      ('201년 · 북방의 겨울', '난이도 어려움 · 6지역 · 3세력', '산성과 보급선이 핵심'),
      ('208년 · 강의 전쟁', '난이도 매우 어려움 · 6지역 · 3세력', '강을 둘러싼 최후의 결전'),
    ];
    return Scaffold(
      body: _RealmBackdrop(
        asset: AssetRepository.worldMapBackground,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xffe3c88f),
                  ),
                  Expanded(
                    child: Text(
                      '시나리오 선택',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xffedd49e),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 6),
              AssetPanel(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '시나리오 선택',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xffebd09a),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '당신의 첫 장정을 선택하십시오.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xffbca981), fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ...scenarios.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ScenarioCard(
                          title: entry.value.$1,
                          subtitle: entry.value.$2,
                          description: entry.value.$3,
                          imageIndex: entry.key,
                          selected: entry.key == selectedIndex,
                          onTap: () =>
                              setState(() => selectedIndex = entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FilledButton(
                      onPressed: () {
                        final selected = scenarios[selectedIndex];
                        final selectedScenario =
                            Map<String, dynamic>.from(widget.scenario)
                              ..['selectedScenarioId'] =
                                  'scenario_${selectedIndex + 1}';
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RulerSelectScreen(
                              scenario: selectedScenario,
                              scenarioTitle: selected.$1,
                            ),
                          ),
                        );
                      },
                      child: Text('${scenarios[selectedIndex].$1} 시작'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffd8c297),
                        side: const BorderSide(color: Color(0xff806742)),
                      ),
                      child: const Text('뒤로'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageIndex,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String description;
  final int imageIndex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff76572e).withValues(alpha: .94)
              : const Color(0xff211f1a).withValues(alpha: .94),
          border: Border.all(
            color: selected ? const Color(0xffd4aa62) : const Color(0xff665238),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: AssetSlice(
                asset: AssetRepository.scenarioThumbnailStrip,
                index: imageIndex,
                segments: 4,
                width: 104,
                height: 74,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xffffe6ae)
                          : const Color(0xffead8ad),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xffc3ae87),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff99866a),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: selected
                  ? const Color(0xffffdf99)
                  : const Color(0xffa18a67),
            ),
          ],
        ),
      ),
    ),
  );
}

class RulerSelectScreen extends StatefulWidget {
  const RulerSelectScreen({
    super.key,
    required this.scenario,
    this.scenarioTitle,
  });
  final Map<String, dynamic> scenario;
  final String? scenarioTitle;

  @override
  State<RulerSelectScreen> createState() => _RulerSelectScreenState();
}

class _RulerSelectScreenState extends State<RulerSelectScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final forces = (widget.scenario['forces'] as List)
        .cast<Map<String, dynamic>>();
    final officers = (widget.scenario['officers'] as List)
        .cast<Map<String, dynamic>>();
    final selectedForce = forces[selectedIndex];
    final selectedRuler = officers.firstWhere(
      (o) => o['id'] == selectedForce['rulerId'],
    );

    return Scaffold(
      body: _RealmBackdrop(
        asset: AssetRepository.titleBackground,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      color: const Color(0xffe3c88f),
                      tooltip: '뒤로',
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '군주 선택',
                            style: TextStyle(
                              color: Color(0xffffe2aa),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                            ),
                          ),
                          if (widget.scenarioTitle != null)
                            Text(
                              widget.scenarioTitle!,
                              style: const TextStyle(
                                color: Color(0xffc7aa78),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '이끌 세력과 군주를 선택하십시오',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xffd1bb91), fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...forces.asMap().entries.map((entry) {
                  final force = entry.value;
                  final ruler = officers.firstWhere(
                    (o) => o['id'] == force['rulerId'],
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _RulerCard(
                      force: force,
                      ruler: ruler,
                      index: entry.key,
                      selected: entry.key == selectedIndex,
                      onTap: () => setState(() => selectedIndex = entry.key),
                    ),
                  );
                }),
                const SizedBox(height: 2),
                _RulerBrief(force: selectedForce, ruler: selectedRuler),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        playerForceId: selectedForce['id'] as String,
                      ),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xff75562d),
                    foregroundColor: const Color(0xffffe4a7),
                    side: const BorderSide(color: Color(0xffd1a45a)),
                  ),
                  child: Text('${selectedRuler['name']}로 시작'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    foregroundColor: const Color(0xffd8c297),
                    side: const BorderSide(color: Color(0xff806742)),
                  ),
                  child: const Text('뒤로'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerCard extends StatelessWidget {
  const _RulerCard({
    required this.force,
    required this.ruler,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> force;
  final Map<String, dynamic> ruler;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 112,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff674a29).withValues(alpha: .98)
              : const Color(0xff211d18).withValues(alpha: .97),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? const Color(0xffd7ad68) : const Color(0xff715a3d),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x66000000), blurRadius: 7)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected
                      ? const Color(0xffe2bb76)
                      : const Color(0xff756044),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _GeneratedPortrait(seed: ruler['id'] as String, size: 92),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      AssetSlice(
                        asset: AssetRepository.factionEmblemStrip,
                        index: index % 3,
                        segments: 3,
                        size: 26,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          ruler['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xffffe5ae)
                                : const Color(0xffead8ad),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selected
                            ? const Color(0xffffd37f)
                            : const Color(0xff8e7757),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    force['name'] as String,
                    style: const TextStyle(
                      color: Color(0xffc9aa78),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '무력 ${ruler['war']}   지력 ${ruler['intelligence']}   매력 ${ruler['charisma']}',
                    style: const TextStyle(
                      color: Color(0xffd7c19a),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: List.generate(
                      5,
                      (star) => Icon(
                        star < (3 + index % 3) ? Icons.star : Icons.star_border,
                        size: 15,
                        color: const Color(0xffe1b75b),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RulerBrief extends StatelessWidget {
  const _RulerBrief({required this.force, required this.ruler});
  final Map<String, dynamic> force;
  final Map<String, dynamic> ruler;

  @override
  Widget build(BuildContext context) => AssetPanel(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    child: Row(
      children: [
        AssetSlice(
          asset: AssetRepository.factionEmblemStrip,
          index: 0,
          segments: 3,
          size: 38,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '${force['name']} · 영토 ${force['provinceIds'].length}곳 · 장수 ${force['officerIds'].length}명',
            style: const TextStyle(color: Color(0xffcbb486), fontSize: 12),
          ),
        ),
        Text(
          '충성 ${ruler['loyalty']}',
          style: const TextStyle(color: Color(0xffe1ba70), fontSize: 12),
        ),
      ],
    ),
  );
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
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '지난달 정산\n금 $beforeGold → ${state.playerForce.gold}\n군량 $beforeFood → ${state.playerForce.food}\n영토 ${state.playerProvinceIds.length}곳',
              ),
              if (state.lastTurnReports.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  '전쟁 보고',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...state.lastTurnReports.map(
                  (report) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      '${report.attackerName} → ${report.targetProvinceName}',
                    ),
                    subtitle: Text(
                      '${report.attackerWon ? 'AI 승리' : 'AI 패배'} · ${report.day}일 · 공격 ${report.attackerSoldiers} / 방어 ${report.defenderSoldiers}',
                    ),
                    trailing: TextButton(
                      onPressed: () => _watchAiReport(report),
                      child: const Text('관전'),
                    ),
                  ),
                ),
              ],
              if (state.lastEvent != null) ...[
                const Divider(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AssetSlice(
                    asset: AssetRepository.eventArtStrip,
                    index: _eventArtIndex(state.lastEvent!),
                    segments: 4,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 8),
                Text(state.lastEvent!),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
          if (state.gameOver)
            FilledButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('메인 메뉴'),
            ),
        ],
      ),
    );
  }

  void _watchAiReport(AiBattleReport report) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AiBattleReplayScreen(report: report)),
    );
  }

  void _showDomesticMenu() {
    if (selectedOfficerId == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff211d18),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '내정',
                style: TextStyle(
                  color: Color(0xffffdfa4),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '선택한 지역의 발전과 민심을 관리합니다.',
                style: TextStyle(color: Color(0xffbca981), fontSize: 12),
              ),
              const SizedBox(height: 12),
              _SheetCommand(
                title: '개발',
                detail: '토지와 군량 생산 기반을 높입니다 · 금 100',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _dispatch(
                    GameCommand(
                      type: GameCommandType.develop,
                      officerId: selectedOfficerId,
                      provinceId: selectedProvinceId,
                    ),
                  );
                },
              ),
              _SheetCommand(
                title: '징세',
                detail: '금 100을 얻고 민심이 하락합니다',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _dispatch(
                    GameCommand(
                      type: GameCommandType.tax,
                      officerId: selectedOfficerId,
                      provinceId: selectedProvinceId,
                    ),
                  );
                },
              ),
              _SheetCommand(
                title: '시혜',
                detail: '금 80을 사용해 민심을 높입니다',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _dispatch(
                    GameCommand(
                      type: GameCommandType.relief,
                      officerId: selectedOfficerId,
                      provinceId: selectedProvinceId,
                    ),
                  );
                },
              ),
              _SheetCommand(
                title: '훈련 · 축성',
                detail: '군대의 준비도 또는 지역 방어를 높입니다',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _dispatch(
                    GameCommand(
                      type: GameCommandType.train,
                      officerId: selectedOfficerId,
                      provinceId: selectedProvinceId,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProvinceInfo(ProvinceState province, GameState state) {
    final governor = province.governorId == null
        ? '미임명'
        : state.officers.firstWhere((o) => o.id == province.governorId).name;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(province.name),
        content: Text(
          '소유 세력  ${province.ownerName}\n'
          '태수  $governor\n'
          '개발  ${province.land}\n'
          '치수  ${province.food}\n'
          '민심  ${province.publicLoyalty}\n'
          '병력  ${province.soldiers}\n'
          '장수  ${province.officerIds.length}',
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
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xff9c7137), width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 12, spreadRadius: 1),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _WorldMapHeader(
                force: state.playerForce,
                state: state,
                onClose: () => Navigator.pop(context),
                onOfficers: _showOfficers,
                onLog: _showLog,
                onSave: _showSaveDialog,
              ),
              Expanded(
                child: _Map(
                  provinces: state.provinces,
                  playerForceId: state.playerForceId,
                  revealedProvinceIds: state.revealedProvinceIds,
                  selectedId: selectedProvinceId,
                  onSelect: _selectProvince,
                ),
              ),
              _ProvinceDetailPanel(
                province: selected,
                state: state,
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
              _MapCommandBar(
                playerOwned: state.isPlayerProvince(selected),
                onDomestic: _showDomesticMenu,
                onPersonnel: _showOfficers,
                onMilitary: () {
                  if (state.isPlayerProvince(selected)) {
                    _showMoveDialog();
                  } else {
                    _startBattle();
                  }
                },
                onDiplomacy: _showDiplomacyDialog,
                onEspionage: _showEspionageDialog,
                onInfo: () => _showProvinceInfo(selected, state),
                onEndMonth: _endMonth,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldMapHeader extends StatelessWidget {
  const _WorldMapHeader({
    required this.force,
    required this.state,
    required this.onClose,
    required this.onOfficers,
    required this.onLog,
    required this.onSave,
  });
  final ForceState force;
  final GameState state;
  final VoidCallback onClose;
  final VoidCallback onOfficers;
  final VoidCallback onLog;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      image: const DecorationImage(
        image: AssetImage(AssetRepository.panelTexture),
        fit: BoxFit.cover,
        opacity: .22,
      ),
      gradient: const LinearGradient(
        colors: [Color(0xff342616), Color(0xff171612)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      border: const Border(
        bottom: BorderSide(color: Color(0xffbd8b45), width: 1.4),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(12, 5, 8, 9),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xffd9af65), size: 21),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '세계 지도',
                style: const TextStyle(
                  color: Color(0xffffdfa1),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
            ),
            IconButton.filled(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 21),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xff5c4528),
                foregroundColor: const Color(0xffffe2a5),
                side: const BorderSide(color: Color(0xffc09953)),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 65,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${state.year}년 ${state.month}월 · 봄\n${force.name}',
                  style: const TextStyle(
                    color: Color(0xfff0d9a7),
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(width: 1, height: 48, color: const Color(0xff725632)),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderMetric(
                    Icons.monetization_on_outlined,
                    '금',
                    force.gold,
                  ),
                  _HeaderMetric(Icons.grass, '군량', force.food),
                  _HeaderMetric(Icons.shield, '병력', state.playerSoldiers),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Icon(icon, color: const Color(0xffd1a75d), size: 16),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(color: Color(0xffd6c09a), fontSize: 12),
      ),
      const SizedBox(width: 4),
      Text(
        '$value',
        style: const TextStyle(
          color: Color(0xfff0d08e),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

class _MapCommandBar extends StatelessWidget {
  const _MapCommandBar({
    required this.playerOwned,
    required this.onDomestic,
    required this.onPersonnel,
    required this.onMilitary,
    required this.onDiplomacy,
    required this.onEspionage,
    required this.onInfo,
    required this.onEndMonth,
  });
  final bool playerOwned;
  final VoidCallback onDomestic;
  final VoidCallback onPersonnel;
  final VoidCallback onMilitary;
  final VoidCallback onDiplomacy;
  final VoidCallback onEspionage;
  final VoidCallback onInfo;
  final VoidCallback onEndMonth;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Color(0xff1c1a16),
      border: Border(
        top: BorderSide(color: Color(0xff715631)),
        bottom: BorderSide(color: Color(0xff3b3021)),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
    child: Row(
      children: [
        _MapCommand(
          label: '내정',
          iconIndex: 0,
          onTap: playerOwned ? onDomestic : null,
        ),
        _MapCommand(label: '인사', iconIndex: 1, onTap: onPersonnel),
        _MapCommand(label: '군사', iconIndex: 2, onTap: onMilitary),
        _MapCommand(label: '외교', iconIndex: 3, onTap: onDiplomacy),
        _MapCommand(label: '첩보', iconIndex: 4, onTap: onEspionage),
        _MapCommand(label: '정보', iconIndex: 5, onTap: onInfo),
        _MapCommand(
          label: '턴 종료',
          iconIndex: 6,
          onTap: onEndMonth,
          accent: true,
        ),
      ],
    ),
  );
}

class _MapCommand extends StatelessWidget {
  const _MapCommand({
    required this.label,
    required this.iconIndex,
    required this.onTap,
    this.accent = false,
  });
  final String label;
  final int iconIndex;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: onTap == null
                ? const Color(0xff28241e)
                : accent
                ? const Color(0xff614927)
                : const Color(0xff29261f),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: onTap == null
                  ? const Color(0xff41382d)
                  : accent
                  ? const Color(0xffb98c4e)
                  : const Color(0xff665238),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  onTap == null
                      ? const Color(0xff5c5140)
                      : const Color(0xffe0bc73),
                  BlendMode.modulate,
                ),
                child: Image.asset(
                  AssetRepository.commandIcon(iconIndex),
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onTap == null
                      ? const Color(0xff796d5a)
                      : const Color(0xffe2cea3),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SheetCommand extends StatelessWidget {
  const _SheetCommand({
    required this.title,
    required this.detail,
    required this.onTap,
  });
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 2),
    leading: const Icon(Icons.menu_book_outlined, color: Color(0xffd4ab68)),
    title: Text(title, style: const TextStyle(color: Color(0xffffe0a3))),
    subtitle: Text(
      detail,
      style: const TextStyle(color: Color(0xffad9874), fontSize: 11),
    ),
    trailing: const Icon(Icons.chevron_right, color: Color(0xffa78a5e)),
    onTap: onTap,
  );
}

// Legacy compact resource row retained for alternate layouts.
// ignore: unused_element
class _ResourceBar extends StatelessWidget {
  const _ResourceBar({required this.force, required this.state});
  final ForceState force;
  final GameState state;
  @override
  Widget build(BuildContext context) => AssetPanel(
    decoration: const BoxDecoration(
      color: Color(0xff211e18),
      border: Border(bottom: BorderSide(color: Color(0xff6d5431))),
    ),
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
      Text(
        label,
        style: const TextStyle(color: Color(0xffbba887), fontSize: 11),
      ),
      Text(
        '$value',
        style: const TextStyle(
          color: Color(0xfff0d08e),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
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
          height: constraints.maxHeight,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff35443c), Color(0xff182522)],
              ),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final tap = details.localPosition;
                ProvinceState? nearest;
                var nearestDistance = double.infinity;
                for (final province in provinces) {
                  final dx = province.mapX * width - tap.dx;
                  final dy = province.mapY * constraints.maxHeight - tap.dy;
                  final distance = dx * dx + dy * dy;
                  if (distance < nearestDistance) {
                    nearestDistance = distance;
                    nearest = province;
                  }
                }
                if (nearest != null) onSelect(nearest.id);
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      AssetRepository.worldMapBackground,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TerritoryOverlayPainter(
                        provinces,
                        selectedId: selectedId,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: .25),
                    ),
                  ),
                  ...provinces.map(
                    (p) => Positioned(
                      left: p.mapX * width - 34,
                      top: p.mapY * constraints.maxHeight - 46,
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
          ),
        ),
      );
    },
  );
}

class _TerritoryOverlayPainter extends CustomPainter {
  _TerritoryOverlayPainter(this.provinces, {this.selectedId});
  final List<ProvinceState> provinces;
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final province in provinces)
        Offset(province.mapX * size.width, province.mapY * size.height),
    ];
    for (var i = 0; i < provinces.length; i++) {
      final customPoints = provinces[i].territoryPoints;
      final polygon = customPoints.length >= 3
          ? [
              for (final point in customPoints)
                Offset(point[0] * size.width, point[1] * size.height),
            ]
          : _voronoiPolygon(i, points, size);
      if (polygon.length < 3) continue;
      final color = _forceColor(provinces[i].ownerForceId);
      final path = _smoothTerritoryPath(polygon);
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .38)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      if (provinces[i].id == selectedId) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xffffd36a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xffffe3a0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  List<Offset> _voronoiPolygon(int index, List<Offset> points, Size size) {
    var polygon = <Offset>[
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(size.width, size.height),
      Offset(0, size.height),
    ];
    final site = points[index];
    for (var j = 0; j < points.length; j++) {
      if (index == j) continue;
      polygon = _clipToBisector(polygon, site, points[j]);
      if (polygon.isEmpty) break;
    }
    return polygon;
  }

  Path _smoothTerritoryPath(List<Offset> polygon) {
    final path = Path();
    final midpoint = (polygon.last + polygon.first) / 2;
    path.moveTo(midpoint.dx, midpoint.dy);
    for (var i = 0; i < polygon.length; i++) {
      final vertex = polygon[i];
      final next = polygon[(i + 1) % polygon.length];
      final nextMidpoint = (vertex + next) / 2;
      path.quadraticBezierTo(
        vertex.dx,
        vertex.dy,
        nextMidpoint.dx,
        nextMidpoint.dy,
      );
    }
    path.close();
    return path;
  }

  List<Offset> _clipToBisector(
    List<Offset> polygon,
    Offset site,
    Offset other,
  ) {
    final normal = Offset(2 * (other.dx - site.dx), 2 * (other.dy - site.dy));
    final limit =
        other.dx * other.dx +
        other.dy * other.dy -
        site.dx * site.dx -
        site.dy * site.dy;
    final result = <Offset>[];
    for (var i = 0; i < polygon.length; i++) {
      final start = polygon[i];
      final end = polygon[(i + 1) % polygon.length];
      final startInside = _dot(normal, start) <= limit;
      final endInside = _dot(normal, end) <= limit;
      if (startInside) result.add(start);
      if (startInside != endInside) {
        final direction = end - start;
        final denominator = _dot(normal, direction);
        if (denominator.abs() > .0001) {
          final t = (limit - _dot(normal, start)) / denominator;
          result.add(start + direction * t);
        }
      }
    }
    return result;
  }

  double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  Color _forceColor(String forceId) => switch (forceId) {
    'force_green' => const Color(0xff2e806c),
    'force_red' => const Color(0xffa94c3c),
    'force_blue' => const Color(0xff6b5b9d),
    _ => const Color(0xff9c7a3d),
  };

  @override
  bool shouldRepaint(covariant _TerritoryOverlayPainter oldDelegate) =>
      oldDelegate.provinces != provinces ||
      oldDelegate.selectedId != selectedId;
}

// Retained for optional adjacency-debug rendering.
// ignore: unused_element
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

// Retained as an optional debug map overlay.
// ignore: unused_element
class _MapBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final contour = Paint()
      ..color = const Color(0x225f816f)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i++) {
      final rect = Rect.fromCenter(
        center: Offset(
          size.width * (.18 + i * .08),
          size.height * (.54 + (i % 3) * .04),
        ),
        width: size.width * (.45 + (i % 4) * .1),
        height: size.height * (.2 + (i % 3) * .08),
      );
      canvas.drawOval(rect, contour);
    }
    final river = Paint()
      ..color = const Color(0x885f8990)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final path = Path()
      ..moveTo(size.width * .08, size.height * .1)
      ..cubicTo(
        size.width * .4,
        size.height * .35,
        size.width * .2,
        size.height * .65,
        size.width * .86,
        size.height * .92,
      );
    canvas.drawPath(path, river);
  }

  @override
  bool shouldRepaint(covariant _MapBackdropPainter oldDelegate) => false;
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
  Widget build(BuildContext context) {
    final (asset, markerSize) = switch (province.settlementType) {
      'large' => (AssetRepository.fortressLarge, 56.0),
      'small' => (AssetRepository.fortressSmall, 34.0),
      _ => (AssetRepository.fortressMedium, 44.0),
    };
    return SizedBox(
      width: 88,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (selected)
            const Positioned(
              top: -7,
              child: Icon(Icons.flag, color: Color(0xffffd46b), size: 24),
            ),
          Positioned(
            top: 7,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: selected
                  ? BoxDecoration(
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 16,
                          spreadRadius: 3,
                          color: Color(0xffe6ae3e),
                        ),
                      ],
                    )
                  : null,
              child: Image.asset(asset, width: markerSize, height: markerSize),
            ),
          ),
          Positioned(
            top: 57,
            child: Text(
              province.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xffffefd0),
                fontWeight: FontWeight.w800,
                fontSize: 13,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 1,
                    offset: Offset(1, 0),
                  ),
                  Shadow(
                    color: Colors.black,
                    blurRadius: 1,
                    offset: Offset(-1, 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvinceDetailPanel extends StatelessWidget {
  const _ProvinceDetailPanel({
    required this.province,
    required this.state,
    required this.playerOwned,
    required this.governorName,
    required this.informationRevealed,
  });
  final ProvinceState province;
  final GameState state;
  final bool playerOwned;
  final String governorName;
  final bool informationRevealed;
  @override
  Widget build(BuildContext context) {
    final ownerForce = state.forces.firstWhere(
      (force) => force.id == province.ownerForceId,
    );
    final governor = province.governorId == null
        ? null
        : state.officers.firstWhere((o) => o.id == province.governorId);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff171612),
        image: const DecorationImage(
          image: AssetImage(AssetRepository.panelTexture),
          fit: BoxFit.cover,
          opacity: .18,
        ),
        border: const Border(
          top: BorderSide(color: Color(0xffbd8b45), width: 1.5),
          bottom: BorderSide(color: Color(0xff634723)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (governor != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _GeneratedPortrait(seed: governor.id, size: 108),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      province.name,
                      style: const TextStyle(
                        color: Color(0xffffdfa0),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '태수  ${governor?.name ?? governorName}',
                      style: const TextStyle(
                        color: Color(0xffd4ba88),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProvinceStatColumn(
                        values: informationRevealed
                            ? [
                                ('금', ownerForce.gold),
                                ('군량', ownerForce.food),
                                ('병력', province.soldiers),
                                ('민심', province.publicLoyalty),
                              ]
                            : const [
                                ('금', '????'),
                                ('군량', '????'),
                                ('병력', '????'),
                                ('민심', '????'),
                              ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 93,
                      color: const Color(0xff5e4b32),
                    ),
                    Expanded(
                      child: _ProvinceStatColumn(
                        values: informationRevealed
                            ? [
                                ('개발', province.land),
                                ('치수', province.food ~/ 10),
                                ('성벽', 35),
                              ]
                            : const [
                                ('개발', '????'),
                                ('치수', '????'),
                                ('성벽', '????'),
                              ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvinceStatColumn extends StatelessWidget {
  const _ProvinceStatColumn({required this.values});
  final List<(String, Object)> values;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: values
        .map(
          (value) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Icon(
                  _statIcon(value.$1),
                  size: 15,
                  color: const Color(0xffc49b57),
                ),
                const SizedBox(width: 5),
                Text(
                  value.$1,
                  style: const TextStyle(
                    color: Color(0xffb9a47c),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  '${value.$2}',
                  style: const TextStyle(
                    color: Color(0xfff0d9a4),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );

  static IconData _statIcon(String label) => switch (label) {
    '금' => Icons.monetization_on_outlined,
    '군량' => Icons.grass,
    '병력' => Icons.shield_outlined,
    '민심' => Icons.people_alt_outlined,
    '개발' => Icons.construction_outlined,
    '치수' => Icons.water_drop_outlined,
    _ => Icons.fort,
  };
}

// Retained for the detailed officer-management layout.
// ignore: unused_element
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

class _CommandLabel extends StatelessWidget {
  const _CommandLabel(this.label, this.iconIndex);
  final String label;
  final int iconIndex;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AssetSlice(
        asset: AssetRepository.commandIconStrip,
        index: iconIndex,
        segments: 4,
        size: 22,
      ),
      const SizedBox(width: 5),
      Text(label),
    ],
  );
}

// Kept as a full command palette for later desktop/debug layouts.
// ignore: unused_element
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
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    child: AssetPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xff1b1915)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AssetSlice(
                  asset: AssetRepository.commandIconStrip,
                  index: 0,
                  segments: 4,
                  size: 34,
                ),
                AssetSlice(
                  asset: AssetRepository.commandIconStrip,
                  index: 1,
                  segments: 4,
                  size: 34,
                ),
                AssetSlice(
                  asset: AssetRepository.commandIconStrip,
                  index: 2,
                  segments: 4,
                  size: 34,
                ),
                AssetSlice(
                  asset: AssetRepository.commandIconStrip,
                  index: 3,
                  segments: 4,
                  size: 34,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
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
                child: const _CommandLabel('개발', 0),
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
                child: const _CommandLabel('징병', 1),
              ),
              FilledButton.tonal(
                onPressed: playerOwned && officerId != null ? onMove : null,
                child: const _CommandLabel('장수 이동', 1),
              ),
              FilledButton.tonal(
                onPressed: playerOwned && officerId != null
                    ? onDiplomacy
                    : null,
                child: const _CommandLabel('외교', 2),
              ),
              FilledButton.tonal(
                onPressed: playerOwned && officerId != null
                    ? onEspionage
                    : null,
                child: const _CommandLabel('첩보', 3),
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
        ],
      ),
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
      body: _RealmBackdrop(
        child: SafeArea(
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
              const Text(
                '출전 장수',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
      body: _RealmBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/battle_background.png',
                      fit: BoxFit.cover,
                    ),
                    Container(color: Colors.black.withValues(alpha: .28)),
                    GameWidget(game: battleGame),
                  ],
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
                        ' / ${battle.defenderMorale}'
                        '${battle.informationRevealed ? ' · 정보 확보' : ''}'
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: battle.finished
                                ? null
                                : () => _act(BattleAction.cooperate),
                            child: const Text('협공'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: battle.finished
                                ? null
                                : () => _act(BattleAction.information),
                            child: const Text('정보'),
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                leading: _GeneratedPortrait(seed: o.id, size: 52),
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

String _portraitAsset(String seed) {
  return AssetRepository.officerPortrait(seed);
}

int _eventArtIndex(String event) {
  if (event.contains('홍수')) return 1;
  if (event.contains('질병')) return 2;
  if (event.contains('상인')) return 3;
  return 0;
}

class _GeneratedPortrait extends StatelessWidget {
  const _GeneratedPortrait({required this.seed, this.size = 56});
  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _portraitAsset(seed),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xff40372a),
          child: Icon(Icons.person, color: Color(0xffd3b477)),
        ),
      ),
    ),
  );
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
        _GeneratedPortrait(seed: officer.id, size: 190),
        const SizedBox(height: 10),
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

class AiBattleReplayScreen extends StatefulWidget {
  const AiBattleReplayScreen({super.key, required this.report});
  final AiBattleReport report;

  @override
  State<AiBattleReplayScreen> createState() => _AiBattleReplayScreenState();
}

class _AiBattleReplayScreenState extends State<AiBattleReplayScreen> {
  late final BattleEngine battle;
  late final BattleGame battleGame;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    final attacker = widget.report.attackerSoldiers.clamp(1, 999999).toInt();
    final defender = widget.report.defenderSoldiers.clamp(1, 999999).toInt();
    final state = BattleState(
      sourceProvinceId: 'replay_source',
      targetProvinceId: 'replay_target',
      attackerName: widget.report.attackerName,
      defenderName: widget.report.defenderName,
      attackerSoldiers: attacker,
      defenderSoldiers: defender,
      attackerFood: 99999,
      dailySupplyCost: 1,
      attackerUnits: [
        BattleUnit(
          officerId: 'replay_attacker',
          name: widget.report.attackerName,
          soldiers: attacker,
          war: 75,
          intelligence: 65,
          row: 3,
          column: 1,
        ),
      ],
      defenderUnits: [
        BattleUnit(
          officerId: 'replay_defender',
          name: widget.report.defenderName,
          soldiers: defender,
          war: 70,
          intelligence: 60,
          row: 1,
          column: 4,
        ),
      ],
    );
    battle = BattleEngine(state);
    battleGame = BattleGame(state);
    timer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      if (!mounted || battle.state.finished) {
        timer?.cancel();
        return;
      }
      battle.attack();
      setState(() {});
      battleGame.refreshBoard();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = battle.state;
    return Scaffold(
      appBar: AppBar(title: Text('AI 전투 관전 · ${state.day}일째')),
      body: _RealmBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/battle_background.png',
                      fit: BoxFit.cover,
                    ),
                    Container(color: Colors.black.withValues(alpha: .28)),
                    GameWidget(game: battleGame),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${state.attackerName} ${state.attackerSoldiers} · ${state.defenderName} ${state.defenderSoldiers}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.finished
                          ? (state.attackerWon
                                ? '관전 결과 · 공격군 승리'
                                : '관전 결과 · 방어군 승리')
                          : '월말 보고의 전투 결과를 재현하고 있습니다.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
