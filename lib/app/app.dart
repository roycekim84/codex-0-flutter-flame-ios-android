import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../battle/battle_engine.dart';
import '../battle/battle_command.dart';
import '../battle/battle_state.dart';
import '../battle/terrain.dart';
import '../core/game_command.dart';
import '../core/game_engine.dart';
import '../data/demo_scenario.dart';
import '../flame/battle_game.dart';
import '../models/game_state.dart';
import '../repositories/save_repository.dart';
import '../core/asset_repository.dart';
import '../core/asset_precache.dart';
import '../ui/widgets/asset_widgets.dart';
import '../ui/battle/battle_hud.dart';

String _formatNumber(Object value) {
  final text = '$value';
  final sign = text.startsWith('-') ? '-' : '';
  final digits = sign.isEmpty ? text : text.substring(1);
  final buffer = StringBuffer(sign);
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String _seasonForMonth(int month) => switch (month) {
  12 || 1 || 2 => '겨울',
  3 || 4 || 5 => '봄',
  6 || 7 || 8 => '여름',
  _ => '가을',
};

String _settlementLabel(String type) => switch (type) {
  'large' => '대성',
  'small' => '소성',
  _ => '중성',
};

class CodexStrategyApp extends StatelessWidget {
  const CodexStrategyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Realm Ledger',
    locale: const Locale('ko', 'KR'),
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
    home: Uri.base.queryParameters['capture'] == 'battle'
        ? const BattleCaptureScreen()
        : const HomeScreen(),
  );
}

/// Deterministic entry point used by the automated portrait screenshot job.
/// It keeps capture tests independent from tap coordinates and menu timing.
class BattleCaptureScreen extends StatefulWidget {
  const BattleCaptureScreen({super.key});

  @override
  State<BattleCaptureScreen> createState() => _BattleCaptureScreenState();
}

class _BattleCaptureScreenState extends State<BattleCaptureScreen> {
  late final GameEngine engine;
  late final BattleEngine battle;

  @override
  void initState() {
    super.initState();
    engine = GameEngine(
      GameState.fromScenario(
        DemoScenario.create(),
        selectedForceId: 'force_green',
      ),
    );
    battle =
        engine.beginBattlePrepared(
          sourceProvinceId: 'p_ash',
          targetProvinceId: 'p_ford',
          committedSoldiers: 600,
          participantOfficerIds: const ['officer_1', 'officer_5'],
          commanderOfficerId: 'officer_1',
        ) ??
        (throw StateError('Battle capture fixture could not be created'));
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BattleScreen(engine: engine, battle: battle);
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SaveLoadScreen(
          state: engine.state,
          repository: saveRepository,
          onSave: (slot) async {
            await saveRepository.save(engine.state, slot);
          },
          onLoad: (data) {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    GameScreen(initialState: GameState.fromSaveMap(data)),
              ),
            );
          },
        ),
      ),
    );
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OfficerListScreen(state: engine.state),
      ),
    );
  }

  void _showPersonnelScreen() {
    if (selectedOfficerId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PersonnelCommandScreen(
          state: engine.state,
          officerId: selectedOfficerId!,
          provinceId: selectedProvinceId!,
          onSearch: () async {
            if (!mounted) return;
            Navigator.pop(context);
            await _dispatch(
              GameCommand(
                type: GameCommandType.search,
                officerId: selectedOfficerId,
                provinceId: selectedProvinceId,
              ),
            );
            if (!mounted) return;
            final candidate = engine.firstFreeOfficer;
            if (candidate != null) {
              ScaffoldMessenger.of(context).clearSnackBars();
              _showRecruitOfficerScreen(candidate);
            }
          },
          onCommand: (command) async {
            if (!mounted) return;
            Navigator.pop(context);
            await _dispatch(command);
          },
        ),
      ),
    );
  }

  void _showRecruitOfficerScreen(OfficerState candidate) {
    final province = engine.state.provinces.firstWhere(
      (p) => p.id == selectedProvinceId,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OfficerRecruitScreen(
          candidate: candidate,
          provinceName: province.name,
          onRecruit: () async {
            if (!mounted) return;
            Navigator.pop(context);
            await _dispatch(
              GameCommand(
                type: GameCommandType.recruitOfficer,
                officerId: selectedOfficerId,
                provinceId: selectedProvinceId,
                targetOfficerId: candidate.id,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MonthlyEventReportScreen(state: engine.state),
      ),
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
    GameCommandType.rewardOfficer => '포상',
    GameCommandType.appointGovernor => '태수 임명',
    GameCommandType.moveOfficer => '장수 이동',
    GameCommandType.giftForce => '외교 · 선물',
    GameCommandType.formAlliance => '외교 · 동맹',
    GameCommandType.threatenForce => '외교 · 협박',
    GameCommandType.infiltrate => '첩보 · 잠입',
    GameCommandType.inciteOfficer => '첩보 · 이간',
    GameCommandType.spreadRumor => '첩보 · 유언비어',
    GameCommandType.buyFood => '내정 · 군량 구매',
    GameCommandType.sellFood => '내정 · 군량 판매',
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
    GameCommandType.rewardOfficer => '장수의 충성도를 높입니다. 금 100을 사용합니다.',
    GameCommandType.appointGovernor => '선택한 장수를 이 지역의 태수로 임명합니다.',
    GameCommandType.moveOfficer => '인접한 아군 지역으로 장수를 이동합니다.',
    GameCommandType.giftForce => '금 100으로 관계를 개선합니다.',
    GameCommandType.formAlliance => '관계 20 이상인 세력과 동맹을 맺습니다.',
    GameCommandType.threatenForce => '관계를 악화시키고 동맹을 파기합니다.',
    GameCommandType.infiltrate => '적 영지 정보를 공개합니다. 금 80을 사용합니다.',
    GameCommandType.inciteOfficer => '적 장수의 충성도를 낮춥니다. 금 100을 사용합니다.',
    GameCommandType.spreadRumor => '적 영지의 민심을 낮춥니다. 금 80을 사용합니다.',
    GameCommandType.buyFood => '시장 가격으로 군량을 구매합니다.',
    GameCommandType.sellFood => '시장 가격으로 군량을 판매합니다.',
    GameCommandType.endMonth => '모든 세력의 명령을 처리하고 다음 달로 넘어갑니다.',
  };

  void _showMilitaryCommandScreen() {
    final province = engine.state.provinces.firstWhere(
      (p) => p.id == selectedProvinceId,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MilitaryCommandScreen(
          province: province,
          force: engine.state.playerForce,
          onCommand: (type) async {
            if (!mounted) return;
            Navigator.pop(context);
            await _dispatch(
              GameCommand(
                type: type,
                officerId: selectedOfficerId,
                provinceId: province.id,
              ),
            );
          },
          onMove: () {
            Navigator.pop(context);
            _showMoveDialog();
          },
        ),
      ),
    );
  }

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
    final officer = engine.state.officers.firstWhere(
      (o) => o.id == selectedOfficerId,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MilitaryMoveScreen(
          officer: officer,
          source: selected,
          destinations: destinations,
          onMove: (destination, soldiers) async {
            if (!mounted) return;
            Navigator.pop(context);
            await _dispatch(
              GameCommand(
                type: GameCommandType.moveOfficer,
                officerId: selectedOfficerId,
                provinceId: selected.id,
                destinationProvinceId: destination.id,
                soldiers: soldiers,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showDiplomacyDialog() async {
    final targets = engine.state.forces
        .where((f) => f.id != engine.state.playerForceId)
        .toList();
    if (targets.isEmpty || selectedOfficerId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DiplomacyScreen(
          state: engine.state,
          targets: targets,
          officerId: selectedOfficerId!,
          provinceId: selectedProvinceId,
          onAction: (type, targetId) async {
            if (!mounted) return;
            Navigator.pop(context);
            await _dispatch(
              GameCommand(
                type: type,
                officerId: selectedOfficerId,
                provinceId: selectedProvinceId,
                targetForceId: targetId,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showEspionageDialog() async {
    final enemyOfficers = engine.state.officers
        .where(
          (o) => o.forceId != engine.state.playerForceId && o.status != 'DEAD',
        )
        .toList();
    if (enemyOfficers.isEmpty || selectedOfficerId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EspionageScreen(
          state: engine.state,
          targets: enemyOfficers,
          officerId: selectedOfficerId!,
          onAction: (command) async {
            if (!mounted) return;
            Navigator.pop(context);
            final wasRevealed =
                command.provinceId != null &&
                engine.state.revealedProvinceIds.contains(command.provinceId);
            await _dispatch(command);
            if (!mounted || command.type != GameCommandType.infiltrate) return;
            final provinceId = command.provinceId;
            if (provinceId == null ||
                wasRevealed ||
                !engine.state.revealedProvinceIds.contains(provinceId)) {
              return;
            }
            final province = engine.state.provinces.firstWhere(
              (p) => p.id == provinceId,
            );
            final force = engine.state.forces.firstWhere(
              (f) => f.id == province.ownerForceId,
            );
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    _EnemyForceInfoScreen(state: engine.state, force: force),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _endMonth() async {
    final beforeGold = engine.state.playerForce.gold;
    final beforeFood = engine.state.playerForce.food;
    final beforeSoldiers = engine.state.playerSoldiers;
    final beforeLoyalty = engine.state.officers
        .where((o) => o.forceId == engine.state.playerForceId)
        .fold<int>(0, (sum, o) => sum + o.loyalty);
    final beforeOfficerCount = engine.state.officers
        .where((o) => o.forceId == engine.state.playerForceId)
        .length;
    final beforeYear = engine.state.year;
    engine.dispatch(const GameCommand(type: GameCommandType.endMonth));
    await _saveAuto();
    if (!mounted) return;
    final state = engine.state;
    final afterOfficerCount = state.officers
        .where((o) => o.forceId == state.playerForceId)
        .length;
    final afterLoyalty = state.officers
        .where((o) => o.forceId == state.playerForceId)
        .fold<int>(0, (sum, o) => sum + o.loyalty);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _YearSummaryScreen(
          year: beforeYear,
          nextMonth: state.month,
          forceName: state.playerForce.name,
          goldDelta: state.playerForce.gold - beforeGold,
          foodDelta: state.playerForce.food - beforeFood,
          soldierDelta: state.playerSoldiers - beforeSoldiers,
          loyaltyDelta: afterOfficerCount == 0 || beforeOfficerCount == 0
              ? 0
              : (afterLoyalty / afterOfficerCount -
                        beforeLoyalty / beforeOfficerCount)
                    .round(),
          event: state.lastEvent,
          battleReports: state.lastTurnReports,
          gameOver: state.gameOver,
          outcome: state.outcome,
          onReplay: _watchAiReport,
        ),
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
    final province = engine.state.provinces.firstWhere(
      (p) => p.id == selectedProvinceId,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DomesticTradeScreen(
          force: engine.state.playerForce,
          province: province,
          onTax: () async {
            if (!mounted) return;
            Navigator.pop(context);
            await _dispatch(
              GameCommand(
                type: GameCommandType.tax,
                officerId: selectedOfficerId,
                provinceId: selectedProvinceId,
              ),
            );
          },
          onCommand: (type) async {
            if (!mounted) return;
            Navigator.pop(context);
            await _dispatch(
              GameCommand(
                type: type,
                officerId: selectedOfficerId,
                provinceId: selectedProvinceId,
              ),
            );
          },
          onTrade: (type, amount) async {
            if (!mounted) return;
            Navigator.pop(context);
            await _dispatch(
              GameCommand(
                type: type,
                provinceId: selectedProvinceId,
                soldiers: amount,
              ),
            );
          },
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showProvinceInfo(ProvinceState province, GameState state) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ProvinceDetailScreen(province: province, state: state),
      ),
    );
  }

  void _showForceInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ForceInfoScreen(state: engine.state)),
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
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .08,
            ),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xffb38343), width: 2),
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
                  forces: state.forces,
                  playerForceId: state.playerForceId,
                  revealedProvinceIds: state.revealedProvinceIds,
                  selectedId: selectedProvinceId,
                  onSelect: _selectProvince,
                ),
              ),
              _ProvinceDetailPanel(
                province: selected,
                state: state,
                ownerForce: state.forces.firstWhere(
                  (force) => force.id == selected.ownerForceId,
                ),
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
                onPersonnel: _showPersonnelScreen,
                onMilitary: () {
                  if (state.isPlayerProvince(selected)) {
                    _showMilitaryCommandScreen();
                  } else {
                    _startBattle();
                  }
                },
                onDiplomacy: _showDiplomacyDialog,
                onEspionage: _showEspionageDialog,
                onInfo: _showForceInfo,
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
        top: BorderSide(color: Color(0xffd09b4d), width: 1),
        bottom: BorderSide(color: Color(0xffc08b43), width: 1.6),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(9, 5, 8, 9),
    child: Column(
      children: [
        SizedBox(
          height: 43,
          child: Row(
            children: [
              IconButton(
                onPressed: onOfficers,
                tooltip: '장수 목록',
                icon: const Icon(Icons.groups, size: 21),
                color: const Color(0xffd9af65),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xffd9af65),
                        size: 19,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        '세계 지도',
                        style: TextStyle(
                          color: Color(0xffffdfa1),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff5c4528),
                  border: Border.all(
                    color: const Color(0xffd2a35b),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 21),
                  color: const Color(0xffffe2a5),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 42,
                    height: 42,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 68,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AssetSlice(
                      asset: AssetRepository.forceBannerStrip,
                      index: force.bannerIndex,
                      segments: 3,
                      width: 23,
                      height: 28,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.year}년 ${state.month}월 · ${_seasonForMonth(state.month)}',
                            style: const TextStyle(
                              color: Color(0xfff0d9a7),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
        _formatNumber(value),
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
    decoration: BoxDecoration(
      color: const Color(0xff171411),
      image: const DecorationImage(
        image: AssetImage(AssetRepository.panelTexture),
        fit: BoxFit.cover,
        opacity: .16,
      ),
      border: const Border(
        top: BorderSide(color: Color(0xffbf8a43), width: 1.6),
        bottom: BorderSide(color: Color(0xff6d4d2b), width: 1),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(6, 7, 6, 8),
    child: Row(
      children: [
        _MapCommand(
          label: '내정',
          iconIndex: 0,
          onTap: playerOwned ? onDomestic : null,
        ),
        _MapCommand(
          label: '인사',
          iconIndex: 1,
          onTap: playerOwned ? onPersonnel : null,
        ),
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
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: onTap == null
                  ? const [Color(0xff28241e), Color(0xff1c1a17)]
                  : accent
                  ? const [Color(0xff806037), Color(0xff4f3921)]
                  : const [Color(0xff3b3022), Color(0xff211d18)],
            ),
            borderRadius: BorderRadius.circular(5),
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
                  width: 31,
                  height: 31,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onTap == null
                      ? const Color(0xff796d5a)
                      : const Color(0xffe2cea3),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Retained for compact command sheets used by legacy layouts.
// ignore: unused_element
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
    required this.forces,
    required this.playerForceId,
    required this.revealedProvinceIds,
    required this.selectedId,
    required this.onSelect,
  });
  final List<ProvinceState> provinces;
  final List<ForceState> forces;
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
                        forces,
                        selectedId: selectedId,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: .16),
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
                          force: forces.firstWhere(
                            (force) => force.id == p.ownerForceId,
                          ),
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
  _TerritoryOverlayPainter(this.provinces, this.forces, {this.selectedId});
  final List<ProvinceState> provinces;
  final List<ForceState> forces;
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final province in provinces)
        Offset(province.mapX * size.width, province.mapY * size.height),
    ];
    // The Voronoi partition is watertight: every point on the map belongs to
    // one province only. This prevents overlapping ownership colors and keeps
    // the map stable when a castle changes owner.
    final polygons = [
      for (var i = 0; i < provinces.length; i++)
        _voronoiPolygon(i, points, size),
    ];
    for (var i = 0; i < provinces.length; i++) {
      // Scenario territory geometry is data-driven. A scenario can provide
      // terrain-aware polygons; older scenarios still fall back to a clipped
      // Voronoi partition so the renderer remains backwards compatible.
      final polygon = polygons[i];
      if (polygon.length < 3) continue;
      final color = _forceColor(provinces[i].ownerForceId);
      final path = _territoryPath(polygon);
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .22)
          ..style = PaintingStyle.fill,
      );
      if (provinces[i].id == selectedId) {
        const selectionColor = Color(0xffffd36a);
        canvas.drawPath(
          path,
          Paint()
            ..color = selectionColor.withValues(alpha: .95)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xffffe3a0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
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

  Path _territoryPath(List<Offset> polygon) {
    final path = Path();
    if (polygon.length < 3) return path;
    path.moveTo(polygon.first.dx, polygon.first.dy);
    for (final vertex in polygon.skip(1)) {
      path.lineTo(vertex.dx, vertex.dy);
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

  Color _forceColor(String forceId) => Color(
    forces.where((force) => force.id == forceId).firstOrNull?.mapColorValue ??
        0xff9c7a3d,
  );

  @override
  bool shouldRepaint(covariant _TerritoryOverlayPainter oldDelegate) => true;
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
    required this.force,
    required this.selected,
  });
  final ProvinceState province;
  final ForceState force;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final (asset, markerSize) = switch (province.settlementType) {
      'large' => (AssetRepository.fortressLarge, 55.0),
      'small' => (AssetRepository.fortressSmall, 33.0),
      _ => (AssetRepository.fortressMedium, 42.0),
    };
    final labelTop = switch (province.settlementType) {
      'large' => 70.0,
      'small' => 48.0,
      _ => 59.0,
    };
    return SizedBox(
      width: 88,
      height: 98,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: selected ? -10 : -5,
            child: AssetSlice(
              asset: AssetRepository.forceBannerStrip,
              index: force.bannerIndex,
              segments: 3,
              width: selected ? 24 : 19,
              height: selected ? 28 : 23,
            ),
          ),
          Positioned(
            top: 7,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: selected
                  ? const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x55f6c95b),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: Image.asset(asset, width: markerSize, height: markerSize),
            ),
          ),
          Positioned(
            top: labelTop,
            child: Column(
              children: [
                Text(
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
              ],
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
    required this.ownerForce,
    required this.playerOwned,
    required this.governorName,
    required this.informationRevealed,
  });
  final ProvinceState province;
  final GameState state;
  final ForceState ownerForce;
  final bool playerOwned;
  final String governorName;
  final bool informationRevealed;
  @override
  Widget build(BuildContext context) {
    final governor = province.governorId == null
        ? null
        : state.officers.firstWhere((o) => o.id == province.governorId);
    final leader =
        governor ??
        state.officers.firstWhere((o) => o.id == ownerForce.rulerId);
    final roleText = governor == null
        ? '태수 미임명 · 군주 ${leader.name}'
        : '태수 ${governor.name}';
    final assignmentText = '$roleText · 주둔 ${province.officerIds.length}명';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff171612),
        image: const DecorationImage(
          image: AssetImage(AssetRepository.panelTexture),
          fit: BoxFit.cover,
          opacity: .18,
        ),
        border: Border(
          top: BorderSide(color: Color(ownerForce.mapColorValue), width: 2),
          bottom: const BorderSide(color: Color(0xff634723)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AssetSlice(
                asset: AssetRepository.forceBannerStrip,
                index: ownerForce.bannerIndex,
                segments: 3,
                width: 24,
                height: 30,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      province.name,
                      style: const TextStyle(
                        color: Color(0xffffdfa0),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 128,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xff211b13),
                      border: Border.all(
                        color: const Color(0xff94703b),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(1, 2),
                        ),
                      ],
                    ),
                    child: _GeneratedPortrait(seed: leader.id, size: 114),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        assignmentText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xffd4ba88),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!playerOwned)
                      Row(
                        children: [
                          Icon(
                            informationRevealed ? Icons.visibility : Icons.lock,
                            size: 13,
                            color: Color(ownerForce.mapColorValue),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            informationRevealed
                                ? '적 세력 · 첩보로 확인된 정보'
                                : '적 세력 · 공개된 정보만 표시',
                            style: const TextStyle(
                              color: Color(0xffbda77b),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 5),
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      padding: const EdgeInsets.fromLTRB(2, 3, 2, 2),
                      decoration: BoxDecoration(
                        color: const Color(0x24110e0a),
                        border: Border.all(color: const Color(0xff5f492b)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ProvinceStatColumn(
                              values: informationRevealed
                                  ? [
                                      ('지역 금', province.gold),
                                      ('지역 군량', province.food),
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
                            color: const Color(0xff6e5633),
                          ),
                          Expanded(
                            child: _ProvinceStatColumn(
                              values: informationRevealed
                                  ? [
                                      ('개발', province.land),
                                      ('치수', province.floodControl),
                                      ('성벽', 35),
                                      (
                                        '성 규모',
                                        _settlementLabel(
                                          province.settlementType,
                                        ),
                                      ),
                                    ]
                                  : const [
                                      ('개발', '????'),
                                      ('치수', '????'),
                                      ('성벽', '????'),
                                      ('주둔 장수', '????'),
                                    ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilitaryCommandScreen extends StatefulWidget {
  const _MilitaryCommandScreen({
    required this.province,
    required this.force,
    required this.onCommand,
    required this.onMove,
  });
  final ProvinceState province;
  final ForceState force;
  final Future<void> Function(GameCommandType type) onCommand;
  final VoidCallback onMove;
  @override
  State<_MilitaryCommandScreen> createState() => _MilitaryCommandScreenState();
}

class _MilitaryCommandScreenState extends State<_MilitaryCommandScreen> {
  double recruitCount = 3000;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090807),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff171612),
          image: const DecorationImage(
            image: AssetImage(AssetRepository.panelTexture),
            fit: BoxFit.cover,
            opacity: .12,
          ),
          border: Border.all(color: const Color(0xffb38343), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                children: [
                  _provinceCard(),
                  const SizedBox(height: 12),
                  _recruitCard(),
                  const SizedBox(height: 12),
                  _trainCard(),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _MilitaryEquipmentScreen(
                          province: widget.province,
                          force: widget.force,
                          onFortify: widget.onCommand,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.construction),
                    label: const Text('무기 · 군마 · 축성'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffe3c480),
                      side: const BorderSide(color: Color(0xff8b6937)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    onPressed: widget.onMove,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('장수·병력 이동'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffe3c480),
                      side: const BorderSide(color: Color(0xff8b6937)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 7),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.shield, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '군사 · 징병 / 훈련',
            style: TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _provinceCard() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0x453d2b17),
      border: Border.all(color: const Color(0xffa1763c)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        const Icon(Icons.castle, color: Color(0xffd6a85d), size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.province.name,
                style: const TextStyle(
                  color: Color(0xffffdfa0),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.force.name} · 금 ${_formatNumber(widget.force.gold)}',
                style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
              ),
            ],
          ),
        ),
        _CostMetric(
          '현재 병력',
          '${_formatNumber(widget.province.soldiers)}명',
          const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _recruitCard() => _panel(
    '징병',
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '모집 병사 수',
          style: TextStyle(color: Color(0xffc1ab82), fontSize: 12),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatNumber(recruitCount.round()),
              style: const TextStyle(
                color: Color(0xffffdfa0),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              '0 / 10,000',
              style: TextStyle(color: Color(0xffa8906b), fontSize: 11),
            ),
          ],
        ),
        Slider(
          value: recruitCount,
          min: 0,
          max: 10000,
          divisions: 100,
          activeColor: const Color(0xffb88645),
          onChanged: (value) => setState(() => recruitCount = value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CostMetric('예상 비용', '금 80', const Color(0xffe4a172)),
            _CostMetric(
              '민심 효율',
              '${widget.province.publicLoyalty}%',
              const Color(0xff73d18b),
            ),
            _CostMetric(
              '예상 증가',
              '+${_formatNumber((recruitCount * (widget.province.publicLoyalty / 100)).round())}',
              const Color(0xff73d18b),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: recruitCount > 0
              ? () => widget.onCommand(GameCommandType.recruit)
              : null,
          style: _militaryButton(),
          child: const Text('징병 실행'),
        ),
      ],
    ),
  );

  Widget _trainCard() => _panel(
    '훈련',
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '현재 훈련도',
              style: TextStyle(color: Color(0xffc1ab82), fontSize: 12),
            ),
            Text(
              'Lv. ${((widget.province.training / 20).floor() + 1).clamp(1, 5)} (${widget.province.training})',
              style: const TextStyle(
                color: Color(0xffffdfa0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: widget.province.training / 100,
          minHeight: 8,
          backgroundColor: const Color(0xff49342a),
          color: const Color(0xffc1944e),
        ),
        const SizedBox(height: 8),
        const Text(
          '훈련 효과  ·  전투 준비도 상승',
          style: TextStyle(color: Color(0xffc1ab82), fontSize: 12),
        ),
        const SizedBox(height: 8),
        _CostMetric('훈련 비용', '금 60', const Color(0xffe4a172)),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => widget.onCommand(GameCommandType.train),
          style: _militaryButton(),
          child: const Text('훈련 실행'),
        ),
      ],
    ),
  );

  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xffd6a85d),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
  ButtonStyle _militaryButton() => FilledButton.styleFrom(
    backgroundColor: const Color(0xff76572f),
    foregroundColor: const Color(0xffffdfa0),
    side: const BorderSide(color: Color(0xffc09351)),
    minimumSize: const Size.fromHeight(48),
  );
}

class _MilitaryEquipmentScreen extends StatefulWidget {
  const _MilitaryEquipmentScreen({
    required this.province,
    required this.force,
    required this.onFortify,
  });
  final ProvinceState province;
  final ForceState force;
  final Future<void> Function(GameCommandType type) onFortify;
  @override
  State<_MilitaryEquipmentScreen> createState() =>
      _MilitaryEquipmentScreenState();
}

class _MilitaryEquipmentScreenState extends State<_MilitaryEquipmentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 3, vsync: this);
  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090807),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff171612),
          image: const DecorationImage(
            image: AssetImage(AssetRepository.panelTexture),
            fit: BoxFit.cover,
            opacity: .12,
          ),
          border: Border.all(color: const Color(0xffb38343), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _header(context),
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xff6d5230))),
              ),
              child: TabBar(
                controller: tabs,
                labelColor: const Color(0xffffdfa0),
                unselectedLabelColor: const Color(0xff9f8967),
                indicatorColor: const Color(0xffc09351),
                tabs: const [
                  Tab(text: '무기'),
                  Tab(text: '군마'),
                  Tab(text: '축성'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: tabs,
                children: [
                  _equipmentTab(
                    context,
                    '무기',
                    Icons.gavel,
                    '공격력 +5',
                    '금 1,200',
                    '무기 레벨 1',
                  ),
                  _equipmentTab(
                    context,
                    '군마',
                    Icons.directions_run,
                    '기동력 +8',
                    '금 1,600',
                    '군마 보유 0',
                  ),
                  _fortificationTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.construction, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '군사 · 무기 / 군마 / 축성',
            style: const TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _equipmentTab(
    BuildContext context,
    String title,
    IconData icon,
    String effect,
    String cost,
    String level,
  ) => ListView(
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
    children: [
      _panel(
        title,
        Column(
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xffd6a85d), size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.province.name} · $level',
                    style: const TextStyle(
                      color: Color(0xffffdfa0),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  effect,
                  style: const TextStyle(
                    color: Color(0xff73d18b),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _itemRow('기본 보급', '공격 효율 상승', cost),
            _itemRow('정예 보급', '공격력 +8', '금 1,600'),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('장비 구매 시스템은 다음 군사 확장에서 연결됩니다.')),
              ),
              style: _button(),
              child: Text('$title 구매'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _panel(
        '현재 효과',
        Text(
          '$title 효과는 전투 시 $effect로 적용됩니다. 보유 금 ${_formatNumber(widget.force.gold)}',
          style: const TextStyle(color: Color(0xffc1ab82), height: 1.4),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('닫기'),
      ),
    ],
  );

  Widget _fortificationTab(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
    children: [
      _panel(
        '성벽 강화',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.province.name,
                  style: const TextStyle(
                    color: Color(0xffffdfa0),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Lv. ${widget.province.land}',
                  style: const TextStyle(
                    color: Color(0xffe3c480),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: widget.province.land / 100,
              minHeight: 8,
              backgroundColor: const Color(0xff49342a),
              color: const Color(0xffc1944e),
            ),
            const SizedBox(height: 10),
            const Text(
              '축성 효과 · 지역 방어 기반 상승',
              style: TextStyle(color: Color(0xffc1ab82)),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => widget.onFortify(GameCommandType.fortify),
              style: _button(),
              child: const Text('축성 실행 · 금 120'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _panel(
        '성 규모',
        Text(
          _settlementLabel(widget.province.settlementType),
          style: const TextStyle(
            color: Color(0xffffdfa0),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('닫기'),
      ),
    ],
  );

  Widget _itemRow(String label, String effect, String cost) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        const Icon(Icons.chevron_right, color: Color(0xffbd8b45), size: 18),
        Expanded(
          child: Text(
            '$label · $effect',
            style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
          ),
        ),
        Text(
          cost,
          style: const TextStyle(
            color: Color(0xffffdfa0),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xffd6a85d),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
  ButtonStyle _button() => FilledButton.styleFrom(
    backgroundColor: const Color(0xff76572f),
    foregroundColor: const Color(0xffffdfa0),
    side: const BorderSide(color: Color(0xffc09351)),
    minimumSize: const Size.fromHeight(48),
  );
}

class _YearSummaryScreen extends StatelessWidget {
  const _YearSummaryScreen({
    required this.year,
    required this.nextMonth,
    required this.forceName,
    required this.goldDelta,
    required this.foodDelta,
    required this.soldierDelta,
    required this.loyaltyDelta,
    required this.event,
    required this.battleReports,
    required this.gameOver,
    required this.outcome,
    required this.onReplay,
  });
  final int year, nextMonth, goldDelta, foodDelta, soldierDelta, loyaltyDelta;
  final String forceName;
  final String? event;
  final List<AiBattleReport> battleReports;
  final bool gameOver;
  final String? outcome;
  final ValueChanged<AiBattleReport> onReplay;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090807),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff171612),
          image: const DecorationImage(
            image: AssetImage(AssetRepository.panelTexture),
            fit: BoxFit.cover,
            opacity: .12,
          ),
          border: Border.all(color: const Color(0xffb38343), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _summaryHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 17, 14, 20),
                children: [
                  Center(
                    child: Text(
                      '$year년 결산',
                      style: const TextStyle(
                        color: Color(0xffffdfa0),
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '$forceName · 다음 달 $nextMonth월',
                      style: const TextStyle(
                        color: Color(0xffbda783),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _summarySection(
                    title: '수입',
                    color: const Color(0xff73d18b),
                    rows: [
                      _SummaryRow('금', goldDelta >= 0 ? goldDelta : 0),
                      _SummaryRow('군량', foodDelta >= 0 ? foodDelta : 0),
                      _SummaryRow('병력', soldierDelta >= 0 ? soldierDelta : 0),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _summarySection(
                    title: '지출·변화',
                    color: const Color(0xffdf8d73),
                    rows: [
                      _SummaryRow('금', goldDelta < 0 ? goldDelta : 0),
                      _SummaryRow('군량', foodDelta < 0 ? foodDelta : 0),
                      _SummaryRow('병력', soldierDelta < 0 ? soldierDelta : 0),
                      _SummaryRow('민심 변화', loyaltyDelta),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _eventCard(),
                  if (battleReports.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _battleCard(context),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: gameOver
                        ? () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => _GameOverScreen(
                                victory: outcome == 'VICTORY',
                                year: year,
                                forceName: forceName,
                              ),
                            ),
                          )
                        : () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xff76572f),
                      foregroundColor: const Color(0xffffdfa0),
                      side: const BorderSide(color: Color(0xffc09351)),
                    ),
                    child: Text(gameOver ? '결산 확인 · 메인으로' : '확인'),
                  ),
                  if (gameOver) ...[
                    const SizedBox(height: 7),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                      child: const Text('메인 메뉴'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _summaryHeader(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.menu_book, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '연도 말 요약',
            style: TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _summarySection({
    required String title,
    required Color color,
    required List<_SummaryRow> rows,
  }) => Container(
    padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(
                    color: Color(0xffc1ab82),
                    fontSize: 13,
                  ),
                ),
                Text(
                  row.value == 0
                      ? '—'
                      : '${row.value > 0 ? '+' : ''}${_formatNumber(row.value)}',
                  style: TextStyle(
                    color: row.value < 0
                        ? const Color(0xffdf8d73)
                        : const Color(0xffffdfa0),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _eventCard() => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0x25231b11),
      border: Border.all(color: const Color(0xff5d472c)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      children: [
        AssetSlice(
          asset: AssetRepository.eventArtStrip,
          index: _eventArtIndex(event ?? ''),
          segments: 4,
          size: 58,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '특이 사항',
                style: TextStyle(
                  color: Color(0xffd6a85d),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event ?? '이번 달에는 특별한 사건이 없었습니다.',
                style: const TextStyle(
                  color: Color(0xffc1ab82),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _battleCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0x25231b11),
      border: Border.all(color: const Color(0xff5d472c)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '전쟁 보고',
          style: TextStyle(
            color: Color(0xffd6a85d),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        ...battleReports.map(
          (report) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              '${report.attackerName} → ${report.targetProvinceName}',
              style: const TextStyle(color: Color(0xffffdfa0), fontSize: 12),
            ),
            subtitle: Text(
              report.attackerWon
                  ? '공격군 승리 · ${report.day}일'
                  : '공격군 패배 · ${report.day}일',
              style: const TextStyle(color: Color(0xffc1ab82), fontSize: 11),
            ),
            trailing: TextButton(
              onPressed: () => onReplay(report),
              child: const Text('관전'),
            ),
          ),
        ),
      ],
    ),
  );
}

class _GameOverScreen extends StatelessWidget {
  const _GameOverScreen({
    required this.victory,
    required this.year,
    required this.forceName,
  });
  final bool victory;
  final int year;
  final String forceName;

  @override
  Widget build(BuildContext context) {
    final accent = victory ? const Color(0xffd6a85d) : const Color(0xffc66f5d);
    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .16,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff382818), Color(0xff181612)],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
                ),
                child: Row(
                  children: [
                    Icon(
                      victory ? Icons.emoji_events : Icons.warning_amber,
                      color: accent,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        victory ? '천하통일' : '게임 오버',
                        style: TextStyle(
                          color: accent,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                  children: [
                    Container(
                      height: 185,
                      decoration: BoxDecoration(
                        border: Border.all(color: accent),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/title_background.png',
                            fit: BoxFit.cover,
                          ),
                          ColoredBox(
                            color: Colors.black.withValues(alpha: .52),
                          ),
                          Center(
                            child: Icon(
                              victory ? Icons.emoji_events : Icons.castle,
                              color: accent,
                              size: 78,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        victory ? '천하를 통일하였습니다!' : '세력이 멸망하였습니다.',
                        style: TextStyle(
                          color: accent,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        victory
                            ? '모든 지역을 하나의 깃발 아래 거두었습니다.'
                            : '더 이상 지배할 영지와 후계 세력이 없습니다.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xffc1ab82),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0x35231b11),
                        border: Border.all(color: const Color(0xff6d5230)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          _line('종료 연도', '$year년'),
                          _line('통치 세력', forceName),
                          _line('결과', victory ? '승리' : '패배'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff76572f),
                        foregroundColor: const Color(0xffffdfa0),
                        side: const BorderSide(color: Color(0xffc09351)),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('메인 메뉴로'),
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

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xffc1ab82))),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xffffdfa0),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _SummaryRow {
  const _SummaryRow(this.label, this.value);
  final String label;
  final int value;
}

class _DiplomacyScreen extends StatefulWidget {
  const _DiplomacyScreen({
    required this.state,
    required this.targets,
    required this.officerId,
    required this.provinceId,
    required this.onAction,
  });
  final GameState state;
  final List<ForceState> targets;
  final String officerId;
  final String? provinceId;
  final Future<void> Function(GameCommandType type, String targetId) onAction;
  @override
  State<_DiplomacyScreen> createState() => _DiplomacyScreenState();
}

class _DiplomacyScreenState extends State<_DiplomacyScreen> {
  late String targetId = widget.targets.first.id;

  ForceState get target => widget.targets.firstWhere((f) => f.id == targetId);
  OfficerState get officer =>
      widget.state.officers.firstWhere((o) => o.id == widget.officerId);
  int get targetSoldiers => widget.state.provinces
      .where((p) => p.ownerForceId == target.id)
      .fold(0, (sum, p) => sum + p.soldiers);
  int get playerSoldiers => widget.state.playerSoldiers;

  @override
  Widget build(BuildContext context) {
    final relation = widget.state.relationTo(target.id);
    final allied = widget.state.alliedForceIds.contains(target.id);
    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff382818), Color(0xff181612)],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.handshake,
                      color: Color(0xffd9af65),
                      size: 25,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '외교',
                        style: TextStyle(
                          color: Color(0xffffdfa0),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: const Color(0xffffdfa0),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                  children: [
                    const Text(
                      '외교 대상',
                      style: TextStyle(
                        color: Color(0xffd6a85d),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    DropdownButtonFormField<String>(
                      initialValue: targetId,
                      dropdownColor: const Color(0xff2b2117),
                      style: const TextStyle(color: Color(0xffffdfa0)),
                      decoration: _moveDecoration('세력 선택'),
                      items: widget.targets
                          .map(
                            (force) => DropdownMenuItem(
                              value: force.id,
                              child: Text(force.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        if (id != null) setState(() => targetId = id);
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0x453d2b17),
                        border: Border.all(color: const Color(0xffa1763c)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          AssetSlice(
                            asset: AssetRepository.forceBannerStrip,
                            index: target.bannerIndex,
                            segments: 3,
                            size: 58,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  target.name,
                                  style: const TextStyle(
                                    color: Color(0xffffdfa0),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '영토 ${target.provinceIds.length}곳 · 장수 ${target.officerIds.length}명',
                                  style: const TextStyle(
                                    color: Color(0xffc1ab82),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '$relation',
                                style: TextStyle(
                                  color: relation >= 20
                                      ? const Color(0xff73d18b)
                                      : const Color(0xffe2bd72),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                '관계',
                                style: TextStyle(
                                  color: Color(0xffa8906b),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0x35231b11),
                        border: Border.all(color: const Color(0xff6d5230)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _CostMetric(
                                widget.state.playerForce.name,
                                '${_formatNumber(playerSoldiers)}명',
                                const Color(0xff73d18b),
                              ),
                              const Text(
                                'VS',
                                style: TextStyle(
                                  color: Color(0xffa8906b),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              _CostMetric(
                                target.name,
                                '${_formatNumber(targetSoldiers)}명',
                                const Color(0xffe17a5d),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value:
                                (playerSoldiers /
                                        (playerSoldiers + targetSoldiers))
                                    .clamp(.02, .98),
                            backgroundColor: const Color(0xff6a3e35),
                            color: const Color(0xff668b6c),
                            minHeight: 7,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            allied ? '현재 동맹 상태' : '군사력과 관계를 바탕으로 외교를 선택하십시오',
                            style: const TextStyle(
                              color: Color(0xffc1ab82),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x25231b11),
                        border: Border.all(color: const Color(0xff5d472c)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          _GeneratedPortrait(seed: officer.id, size: 48),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '수행 장수  ${officer.name}\nCHA ${officer.charisma} · INT ${officer.intelligence}',
                              style: const TextStyle(
                                color: Color(0xffc1ab82),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          widget.onAction(GameCommandType.giftForce, target.id),
                      icon: const Icon(Icons.card_giftcard),
                      label: const Text('선물 보내기 · 금 100'),
                      style: _diplomacyButton(),
                    ),
                    const SizedBox(height: 7),
                    FilledButton.icon(
                      onPressed: () => widget.onAction(
                        GameCommandType.formAlliance,
                        target.id,
                      ),
                      icon: const Icon(Icons.link),
                      label: Text(allied ? '동맹 유지 중' : '동맹 제안'),
                      style: _diplomacyButton(),
                    ),
                    const SizedBox(height: 7),
                    FilledButton.icon(
                      onPressed: () => widget.onAction(
                        GameCommandType.threatenForce,
                        target.id,
                      ),
                      icon: const Icon(Icons.warning_amber),
                      label: const Text('협박'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff6b3025),
                        foregroundColor: const Color(0xffffd2c4),
                        side: const BorderSide(color: Color(0xffa84f3c)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('중지'),
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

  ButtonStyle _diplomacyButton() => FilledButton.styleFrom(
    backgroundColor: const Color(0xff76572f),
    foregroundColor: const Color(0xffffdfa0),
    side: const BorderSide(color: Color(0xffc09351)),
    minimumSize: const Size.fromHeight(50),
  );
}

class _EspionageScreen extends StatefulWidget {
  const _EspionageScreen({
    required this.state,
    required this.targets,
    required this.officerId,
    required this.onAction,
  });
  final GameState state;
  final List<OfficerState> targets;
  final String officerId;
  final Future<void> Function(GameCommand command) onAction;

  @override
  State<_EspionageScreen> createState() => _EspionageScreenState();
}

class _EspionageScreenState extends State<_EspionageScreen> {
  late String targetId = widget.targets.first.id;

  OfficerState get target =>
      widget.targets.firstWhere((officer) => officer.id == targetId);
  OfficerState get performer => widget.state.officers.firstWhere(
    (officer) => officer.id == widget.officerId,
  );
  ProvinceState get province =>
      widget.state.provinces.firstWhere((item) => item.id == target.provinceId);
  ForceState get force =>
      widget.state.forces.firstWhere((item) => item.id == target.forceId);

  int get successChance =>
      (35 +
              performer.intelligence ~/ 2 +
              performer.charisma ~/ 8 -
              target.loyalty ~/ 3)
          .clamp(18, 86);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090807),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff171612),
          image: const DecorationImage(
            image: AssetImage(AssetRepository.panelTexture),
            fit: BoxFit.cover,
            opacity: .12,
          ),
          border: Border.all(color: const Color(0xffb38343), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _espionageHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 15, 14, 20),
                children: [
                  const Text(
                    '이간 대상 장수',
                    style: TextStyle(
                      color: Color(0xffd6a85d),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    initialValue: targetId,
                    dropdownColor: const Color(0xff2b2117),
                    style: const TextStyle(color: Color(0xffffdfa0)),
                    decoration: _moveDecoration('대상 선택'),
                    items: widget.targets.map((officer) {
                      final location = widget.state.provinces
                          .where((item) => item.id == officer.provinceId)
                          .firstOrNull;
                      return DropdownMenuItem(
                        value: officer.id,
                        child: Text(
                          '${officer.name} · ${location?.name ?? '재야'} · 충성 ${officer.loyalty}',
                        ),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) setState(() => targetId = id);
                    },
                  ),
                  const SizedBox(height: 12),
                  _targetCard(),
                  const SizedBox(height: 12),
                  _operationCard(),
                  const SizedBox(height: 12),
                  _performerCard(),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => widget.onAction(
                      GameCommand(
                        type: GameCommandType.inciteOfficer,
                        officerId: performer.id,
                        provinceId: province.id,
                        targetOfficerId: target.id,
                      ),
                    ),
                    icon: const Icon(Icons.psychology_alt),
                    label: const Text('이간 실행 · 금 100'),
                    style: _espionageButton(),
                  ),
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    onPressed: () => widget.onAction(
                      GameCommand(
                        type: GameCommandType.infiltrate,
                        officerId: performer.id,
                        provinceId: province.id,
                      ),
                    ),
                    icon: const Icon(Icons.visibility),
                    label: const Text('잠입 · 금 80'),
                    style: _secondaryEspionageButton(),
                  ),
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    onPressed: () => widget.onAction(
                      GameCommand(
                        type: GameCommandType.spreadRumor,
                        officerId: performer.id,
                        provinceId: province.id,
                      ),
                    ),
                    icon: const Icon(Icons.record_voice_over),
                    label: const Text('유언비어 · 금 80'),
                    style: _secondaryEspionageButton(),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('중지'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _espionageHeader() => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.visibility, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '첩보 · 이간',
            style: TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _targetCard() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0x453d2b17),
      border: Border.all(color: const Color(0xffa1763c)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        _GeneratedPortrait(seed: target.id, size: 74),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                target.name,
                style: const TextStyle(
                  color: Color(0xffffdfa0),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${force.name} · ${province.name}',
                style: const TextStyle(color: Color(0xffc1ab82)),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Color(0xffd6a85d),
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '충성도  ${target.loyalty}',
                    style: const TextStyle(color: Color(0xffe4c783)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _operationCard() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '이간 작전',
              style: TextStyle(
                color: Color(0xffffdfa0),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$successChance%',
              style: const TextStyle(
                color: Color(0xff73d18b),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: successChance / 100,
          minHeight: 7,
          backgroundColor: const Color(0xff49342a),
          color: const Color(0xffc1944e),
        ),
        const SizedBox(height: 8),
        const Text(
          '대상 장수의 충성도를 낮춰 등용 가능성을 높입니다. 작전은 금 100을 사용합니다.',
          style: TextStyle(color: Color(0xffc1ab82), fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );

  Widget _performerCard() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0x25231b11),
      border: Border.all(color: const Color(0xff5d472c)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      children: [
        _GeneratedPortrait(seed: performer.id, size: 52),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '실행 장수  ${performer.name}\nINT ${performer.intelligence} · CHA ${performer.charisma}',
            style: const TextStyle(
              color: Color(0xffc1ab82),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        _CostMetric(
          '보유 금',
          _formatNumber(widget.state.playerForce.gold),
          const Color(0xffe4c783),
        ),
      ],
    ),
  );

  ButtonStyle _espionageButton() => FilledButton.styleFrom(
    backgroundColor: const Color(0xff76572f),
    foregroundColor: const Color(0xffffdfa0),
    side: const BorderSide(color: Color(0xffc09351)),
    minimumSize: const Size.fromHeight(50),
  );

  ButtonStyle _secondaryEspionageButton() => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xffe3c480),
    side: const BorderSide(color: Color(0xff8b6937)),
    minimumSize: const Size.fromHeight(47),
  );
}

class _PersonnelCommandScreen extends StatefulWidget {
  const _PersonnelCommandScreen({
    required this.state,
    required this.officerId,
    required this.provinceId,
    required this.onSearch,
    required this.onCommand,
  });
  final GameState state;
  final String officerId;
  final String provinceId;
  final VoidCallback onSearch;
  final Future<void> Function(GameCommand command) onCommand;
  @override
  State<_PersonnelCommandScreen> createState() =>
      _PersonnelCommandScreenState();
}

class _PersonnelCommandScreenState extends State<_PersonnelCommandScreen> {
  late String targetOfficerId = widget.officerId;
  late String targetProvinceId = widget.provinceId;
  OfficerState get target =>
      widget.state.officers.firstWhere((o) => o.id == targetOfficerId);
  List<OfficerState> get localOfficers => widget.state.officers
      .where(
        (o) =>
            o.forceId == widget.state.playerForceId &&
            o.provinceId == targetProvinceId,
      )
      .toList();
  @override
  Widget build(BuildContext context) {
    final province = widget.state.provinces.firstWhere(
      (p) => p.id == targetProvinceId,
    );
    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                  children: [
                    _rewardCard(),
                    const SizedBox(height: 12),
                    _governorCard(province),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: widget.onSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('탐색 · 재야 인재 찾기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffe3c480),
                        side: const BorderSide(color: Color(0xff8b6937)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 7),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
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

  Widget _header(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.assignment_ind, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '인사 · 포상 / 태수 임명',
            style: TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );
  Widget _rewardCard() => _panel(
    '포상 (충성 상승)',
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: targetOfficerId,
          dropdownColor: const Color(0xff2b2117),
          style: const TextStyle(color: Color(0xffffdfa0)),
          decoration: _moveDecoration('대상 장수'),
          items: widget.state.officers
              .where((o) => o.forceId == widget.state.playerForceId)
              .map(
                (o) => DropdownMenuItem(
                  value: o.id,
                  child: Text('${o.name} · 충성 ${o.loyalty}'),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id != null) setState(() => targetOfficerId = id);
          },
        ),
        const SizedBox(height: 10),
        _rewardRow('공적 하사', '+5', '금 100'),
        _rewardRow('포상 지급', '+10', '금 200'),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => widget.onCommand(
            GameCommand(
              type: GameCommandType.rewardOfficer,
              officerId: target.id,
              targetOfficerId: target.id,
              provinceId: target.provinceId,
            ),
          ),
          style: _button(),
          child: const Text('포상 실행'),
        ),
      ],
    ),
  );
  Widget _governorCard(ProvinceState province) => _panel(
    '태수 임명',
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: targetProvinceId,
          dropdownColor: const Color(0xff2b2117),
          style: const TextStyle(color: Color(0xffffdfa0)),
          decoration: _moveDecoration('임명할 도시'),
          items: widget.state.provinces
              .where((p) => widget.state.isPlayerProvince(p))
              .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
              .toList(),
          onChanged: (id) {
            if (id != null) {
              setState(() {
                targetProvinceId = id;
                final candidates = localOfficers;
                if (candidates.isNotEmpty) {
                  targetOfficerId = candidates.first.id;
                }
              });
            }
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: localOfficers.any((o) => o.id == targetOfficerId)
              ? targetOfficerId
              : null,
          dropdownColor: const Color(0xff2b2117),
          style: const TextStyle(color: Color(0xffffdfa0)),
          decoration: _moveDecoration('후보 장수'),
          items: localOfficers
              .map(
                (o) => DropdownMenuItem(
                  value: o.id,
                  child: Text('${o.name} · INT ${o.intelligence}'),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id != null) setState(() => targetOfficerId = id);
          },
        ),
        const SizedBox(height: 10),
        Text(
          '${province.name}의 관리자를 변경합니다.',
          style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: localOfficers.any((o) => o.id == targetOfficerId)
              ? () => widget.onCommand(
                  GameCommand(
                    type: GameCommandType.appointGovernor,
                    officerId: targetOfficerId,
                    provinceId: targetProvinceId,
                  ),
                )
              : null,
          style: _button(),
          child: const Text('임명 실행'),
        ),
      ],
    ),
  );
  Widget _rewardRow(String label, String effect, String cost) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
          ),
        ),
        Text(
          effect,
          style: const TextStyle(
            color: Color(0xff73d18b),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          cost,
          style: const TextStyle(color: Color(0xffffdfa0), fontSize: 12),
        ),
      ],
    ),
  );
  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xffd6a85d),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
  ButtonStyle _button() => FilledButton.styleFrom(
    backgroundColor: const Color(0xff76572f),
    foregroundColor: const Color(0xffffdfa0),
    side: const BorderSide(color: Color(0xffc09351)),
    minimumSize: const Size.fromHeight(48),
  );
}

// Legacy search-only screen retained for the original personnel flow.
// ignore: unused_element
class _PersonnelSearchScreen extends StatelessWidget {
  const _PersonnelSearchScreen({
    required this.provinceName,
    required this.freeOfficerCount,
    required this.onSearch,
  });
  final String provinceName;
  final int freeOfficerCount;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090807),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff171612),
          image: const DecorationImage(
            image: AssetImage(AssetRepository.panelTexture),
            fit: BoxFit.cover,
            opacity: .12,
          ),
          border: Border.all(color: const Color(0xffb38343), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff382818), Color(0xff181612)],
                ),
                border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: Color(0xffd9af65), size: 25),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '인사 · 탐색',
                      style: TextStyle(
                        color: Color(0xffffdfa0),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: const Color(0xffffdfa0),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: SizedBox(
                        width: double.infinity,
                        height: 210,
                        child: Image.asset(
                          'assets/images/personnel_search_art.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$provinceName 주변을 탐색합니다',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xffffdfa0),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '재야 장수와 뜻밖의 발견을 찾아 인재를 확보하십시오.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xffc1ab82), fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x351c1812),
                        border: Border.all(color: const Color(0xff6d5230)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_search,
                            color: Color(0xffd2a25a),
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              '현재 재야 장수',
                              style: TextStyle(
                                color: Color(0xffc8af7b),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '$freeOfficerCount명',
                            style: const TextStyle(
                              color: Color(0xffffdfa0),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('탐색 실행'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: const Color(0xff76572f),
                        foregroundColor: const Color(0xffffdfa0),
                        side: const BorderSide(color: Color(0xffc09351)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('중지'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OfficerRecruitScreen extends StatelessWidget {
  const _OfficerRecruitScreen({
    required this.candidate,
    required this.provinceName,
    required this.onRecruit,
  });

  final OfficerState candidate;
  final String provinceName;
  final Future<void> Function() onRecruit;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090807),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff171612),
          image: const DecorationImage(
            image: AssetImage(AssetRepository.panelTexture),
            fit: BoxFit.cover,
            opacity: .12,
          ),
          border: Border.all(color: const Color(0xffb38343), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff382818), Color(0xff181612)],
                ),
                border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    color: Color(0xffd9af65),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '인사 · 등용',
                      style: TextStyle(
                        color: Color(0xffffdfa0),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: const Color(0xffffdfa0),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '재야 장수',
                      style: TextStyle(
                        color: Color(0xffd6a85d),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x35231b11),
                        border: Border.all(color: const Color(0xff8c6735)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GeneratedPortrait(seed: candidate.id, size: 104),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  candidate.name,
                                  style: const TextStyle(
                                    color: Color(0xffffdfa0),
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _RecruitStat('WAR', candidate.war),
                                _RecruitStat('INT', candidate.intelligence),
                                _RecruitStat('CHA', candidate.charisma),
                                _RecruitStat('관계', '중립'),
                                _RecruitStat('충성도', candidate.loyalty),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '$provinceName에서 등용을 제안합니다',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xffffdfa0),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x35231b11),
                        border: Border.all(color: const Color(0xff6d5230)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '등용 확률',
                            style: TextStyle(
                              color: Color(0xffc7ae83),
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '72%',
                            style: TextStyle(
                              color: Color(0xff6fce8a),
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: onRecruit,
                      icon: const Icon(Icons.handshake_outlined),
                      label: const Text('등용 실행 · 금 200'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: const Color(0xff76572f),
                        foregroundColor: const Color(0xffffdfa0),
                        side: const BorderSide(color: Color(0xffc09351)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('중지'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecruitStat extends StatelessWidget {
  const _RecruitStat(this.label, this.value);
  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
        ),
        Text(
          '$value',
          style: const TextStyle(color: Color(0xffffdfa0), fontSize: 13),
        ),
      ],
    ),
  );
}

class _MilitaryMoveScreen extends StatefulWidget {
  const _MilitaryMoveScreen({
    required this.officer,
    required this.source,
    required this.destinations,
    required this.onMove,
  });

  final OfficerState officer;
  final ProvinceState source;
  final List<ProvinceState> destinations;
  final Future<void> Function(ProvinceState destination, int soldiers) onMove;

  @override
  State<_MilitaryMoveScreen> createState() => _MilitaryMoveScreenState();
}

class _MilitaryMoveScreenState extends State<_MilitaryMoveScreen> {
  late ProvinceState destination = widget.destinations.first;
  late double soldiers = (widget.source.soldiers / 2).roundToDouble();

  @override
  Widget build(BuildContext context) {
    final total = widget.source.soldiers;
    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff382818), Color(0xff181612)],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      color: Color(0xffd9af65),
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '군사 · 병력 이동',
                        style: TextStyle(
                          color: Color(0xffffdfa0),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: const Color(0xffffdfa0),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '출발지',
                        style: TextStyle(
                          color: Color(0xffd6a85d),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MoveProvinceCard(
                        name: widget.source.name,
                        subtitle: '현재 병력 ${_formatNumber(total)}명',
                        selected: true,
                      ),
                      const SizedBox(height: 14),
                      const Center(
                        child: Icon(
                          Icons.arrow_downward,
                          color: Color(0xffd6a85d),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '도착지',
                        style: TextStyle(
                          color: Color(0xffd6a85d),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ProvinceState>(
                        initialValue: destination,
                        dropdownColor: const Color(0xff2b2117),
                        style: const TextStyle(color: Color(0xffffdfa0)),
                        decoration: _moveDecoration('인접 아군 지역 선택'),
                        items: widget.destinations
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  '${p.name} · 주둔 ${_formatNumber(p.soldiers)}명',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          if (value != null) destination = value;
                        }),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x35231b11),
                          border: Border.all(color: const Color(0xff8c6735)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _GeneratedPortrait(
                                  seed: widget.officer.id,
                                  size: 58,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.officer.name,
                                    style: const TextStyle(
                                      color: Color(0xffffdfa0),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_formatNumber(soldiers.round())}명',
                                  style: const TextStyle(
                                    color: Color(0xff73d18b),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '이동 병력  ${_formatNumber(soldiers.round())} / ${_formatNumber(total)}명',
                              style: const TextStyle(
                                color: Color(0xffc9b184),
                                fontSize: 13,
                              ),
                            ),
                            Slider(
                              value: soldiers,
                              min: 0,
                              max: total.toDouble().clamp(1, double.infinity),
                              divisions: total > 0 ? total : 1,
                              activeColor: const Color(0xffb88645),
                              onChanged: (value) =>
                                  setState(() => soldiers = value),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _MoveQuick(
                                  '절반',
                                  total / 2,
                                  () => setState(
                                    () =>
                                        soldiers = (total / 2).roundToDouble(),
                                  ),
                                ),
                                _MoveQuick(
                                  '전군',
                                  total.toDouble(),
                                  () => setState(
                                    () => soldiers = total.toDouble(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: soldiers.round() > 0
                            ? () => widget.onMove(destination, soldiers.round())
                            : null,
                        icon: const Icon(Icons.directions_walk),
                        label: const Text('이동 실행'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: const Color(0xff76572f),
                          foregroundColor: const Color(0xffffdfa0),
                          side: const BorderSide(color: Color(0xffc09351)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('중지'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _moveDecoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: Color(0xffc1ab82)),
  enabledBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xff6d5230)),
  ),
  focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xffd0a25b)),
  ),
);

class _MoveProvinceCard extends StatelessWidget {
  const _MoveProvinceCard({
    required this.name,
    required this.subtitle,
    required this.selected,
  });
  final String name, subtitle;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: selected ? const Color(0x454c3920) : const Color(0x30231b11),
      border: Border.all(
        color: selected ? const Color(0xffd0a25b) : const Color(0xff6d5230),
      ),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        const Icon(Icons.fort, color: Color(0xffd3a55d), size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
        ),
      ],
    ),
  );
}

class _MoveQuick extends StatelessWidget {
  const _MoveQuick(this.label, this.value, this.onTap);
  final String label;
  final double value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: onTap, child: Text(label));
}

class _DomesticTradeScreen extends StatefulWidget {
  const _DomesticTradeScreen({
    required this.force,
    required this.province,
    required this.onTax,
    required this.onTrade,
    required this.onCommand,
  });
  final ForceState force;
  final ProvinceState province;
  final VoidCallback onTax;
  final Future<void> Function(GameCommandType type, int amount) onTrade;
  final Future<void> Function(GameCommandType type) onCommand;
  @override
  State<_DomesticTradeScreen> createState() => _DomesticTradeScreenState();
}

class _DomesticTradeScreenState extends State<_DomesticTradeScreen> {
  double buy = 5000;
  double sell = 3000;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090807),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff171612),
          image: const DecorationImage(
            image: AssetImage(AssetRepository.panelTexture),
            fit: BoxFit.cover,
            opacity: .12,
          ),
          border: Border.all(color: const Color(0xffb38343), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                children: [
                  _resourceCard(),
                  const SizedBox(height: 12),
                  _tradeCard(),
                  const SizedBox(height: 12),
                  _taxCard(),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _header(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.storefront, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '내정 · 군량 거래 / 징세',
            style: TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );
  Widget _resourceCard() => _panel(
    '현재 자원',
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _CostMetric(
          '금',
          _formatNumber(widget.force.gold),
          const Color(0xffffdfa0),
        ),
        _CostMetric(
          '군량',
          _formatNumber(widget.province.food),
          const Color(0xffe3c480),
        ),
        _CostMetric('시장 시세', '1 : 0.9', const Color(0xff73d18b)),
      ],
    ),
  );
  Widget _tradeCard() => _panel(
    '군량 거래',
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '구매',
          style: TextStyle(
            color: Color(0xffd6a85d),
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatNumber(buy.round()),
              style: const TextStyle(
                color: Color(0xffffdfa0),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '지불 금액 ${_formatNumber((buy * .9).round())}',
              style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
            ),
          ],
        ),
        Slider(
          value: buy,
          min: 0,
          max: 10000,
          divisions: 100,
          activeColor: const Color(0xffb88645),
          onChanged: (v) => setState(() => buy = v),
        ),
        FilledButton(
          onPressed: buy.round() <= 0
              ? null
              : () => widget.onTrade(GameCommandType.buyFood, buy.round()),
          style: _button(),
          child: const Text('구매'),
        ),
        const Divider(color: Color(0xff6d5230), height: 25),
        const Text(
          '판매',
          style: TextStyle(
            color: Color(0xffd6a85d),
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatNumber(sell.round()),
              style: const TextStyle(
                color: Color(0xffffdfa0),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '획득 금액 ${_formatNumber((sell * .9).round())}',
              style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
            ),
          ],
        ),
        Slider(
          value: sell,
          min: 0,
          max: widget.province.food.toDouble().clamp(1, 10000),
          divisions: 100,
          activeColor: const Color(0xffb88645),
          onChanged: (v) => setState(() => sell = v),
        ),
        FilledButton(
          onPressed: sell.round() <= 0
              ? null
              : () => widget.onTrade(GameCommandType.sellFood, sell.round()),
          style: _button(),
          child: const Text('판매'),
        ),
      ],
    ),
  );
  Widget _taxCard() => _panel(
    '징세',
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('징세 강도', style: TextStyle(color: Color(0xffc1ab82))),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Text('약함', style: TextStyle(color: Color(0xff73d18b))),
            const Text(
              '보통',
              style: TextStyle(
                color: Color(0xffffdfa0),
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text('강함', style: TextStyle(color: Color(0xffdf8d73))),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '금 +90   ·   군량 +500   ·   민심 -3',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xffc1ab82)),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: widget.onTax,
          style: _button(),
          child: const Text('징세 실행'),
        ),
      ],
    ),
  );
  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xffd6a85d),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
  ButtonStyle _button() => FilledButton.styleFrom(
    backgroundColor: const Color(0xff76572f),
    foregroundColor: const Color(0xffffdfa0),
    side: const BorderSide(color: Color(0xffc09351)),
    minimumSize: const Size.fromHeight(45),
  );
}

// Legacy domestic command list retained for alternate layouts.
// ignore: unused_element
class _DomesticScreen extends StatelessWidget {
  const _DomesticScreen({required this.province, required this.onCommand});
  final ProvinceState province;
  final Future<void> Function(GameCommandType type) onCommand;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (0, '개발', '토지 개발을 실시합니다', '금 100', GameCommandType.develop),
      (2, '치수', '홍수 피해를 줄이고 치수를 높입니다', '금 80', GameCommandType.fortify),
      (3, '징세', '금 100을 얻지만 민심이 하락합니다', '금 0', GameCommandType.tax),
      (4, '시혜', '금 80을 사용해 민심을 높입니다', '금 80', GameCommandType.relief),
      (5, '군량 거래', '시장 가격으로 군량을 거래합니다', '시세 적용', GameCommandType.tax),
      (2, '훈련 · 축성', '군대의 준비도와 성벽을 높입니다', '금 60', GameCommandType.train),
    ];
    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff382818), Color(0xff181612)],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance,
                      color: Color(0xffd9af65),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '내정 · ${province.name}',
                        style: const TextStyle(
                          color: Color(0xffffdfa0),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: const Color(0xffffdfa0),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DomesticMetric('금', province.gold),
                    _DomesticMetric('군량', province.food),
                    _DomesticMetric('민심', province.publicLoyalty),
                    _DomesticMetric('개발', province.land),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: actions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    return InkWell(
                      onTap: () => onCommand(action.$5),
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff34291d), Color(0xff211b16)],
                          ),
                          border: Border.all(color: const Color(0xff755735)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              AssetRepository.commandIcon(action.$1),
                              width: 42,
                              height: 42,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.$2,
                                    style: const TextStyle(
                                      color: Color(0xffffdfa0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    action.$3,
                                    style: const TextStyle(
                                      color: Color(0xffc4ac83),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              action.$4,
                              style: const TextStyle(
                                color: Color(0xffe2bd72),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xffb48a50),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DomesticMetric extends StatelessWidget {
  const _DomesticMetric(this.label, this.value);
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xffb9a47c), fontSize: 11),
      ),
      const SizedBox(height: 2),
      Text(
        _formatNumber(value),
        style: const TextStyle(
          color: Color(0xfff0d9a4),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _ForceInfoScreen extends StatelessWidget {
  const _ForceInfoScreen({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final force = state.playerForce;
    final ruler = state.officers.firstWhere((o) => o.id == force.rulerId);
    final provinces = state.provinces
        .where((p) => p.ownerForceId == force.id)
        .toList();
    final officers = state.officers
        .where((o) => o.forceId == force.id)
        .toList();
    final totalSoldiers = provinces.fold<int>(0, (sum, p) => sum + p.soldiers);
    final relationRows = state.forces.where((f) => f.id != force.id).map((
      other,
    ) {
      final relation = state.relationTo(other.id);
      final color = relation >= 30
          ? const Color(0xff73d18b)
          : relation <= -30
          ? const Color(0xffd37b5d)
          : const Color(0xffd6a85d);
      return _forceRelationRow(other, relation, color);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                  children: [
                    _identity(force, ruler, provinces.length, officers.length),
                    const SizedBox(height: 10),
                    _panel(
                      '기본 정보',
                      Column(
                        children: [
                          _infoLine('영지 수', '${provinces.length}개'),
                          _infoLine('총 병력', _formatNumber(totalSoldiers)),
                          _infoLine('장수 수', '${officers.length}명'),
                          _infoLine('군주', ruler.name),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _panel(
                      '외교 관계',
                      relationRows.isEmpty
                          ? const Text(
                              '확인된 세력이 없습니다.',
                              style: TextStyle(color: Color(0xffc1ab82)),
                            )
                          : Column(children: relationRows),
                    ),
                    const SizedBox(height: 10),
                    _panel(
                      '주요 장수',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: officers
                            .take(6)
                            .map((o) => _officerChip(o))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _panel(
                      '최근 기록',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: state.gameLog.reversed
                            .take(4)
                            .map(
                              (log) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Text(
                                  log,
                                  style: const TextStyle(
                                    color: Color(0xffc1ab82),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () {
                        final enemy = state.forces.firstWhere(
                          (f) => f.id != force.id,
                          orElse: () => force,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _EnemyForceInfoScreen(
                              state: state,
                              force: enemy,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('적 세력 정보 보기'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff76572f),
                        foregroundColor: const Color(0xffffdfa0),
                        side: const BorderSide(color: Color(0xffc09351)),
                        minimumSize: const Size.fromHeight(45),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
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

  Widget _header(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.menu_book, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '정보 · 세력 정보',
            style: TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _identity(
    ForceState force,
    OfficerState ruler,
    int provinceCount,
    int officerCount,
  ) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0x453d2b17),
      border: Border.all(color: const Color(0xffa1763c)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        AssetSlice(
          asset: AssetRepository.forceBannerStrip,
          index: force.bannerIndex,
          segments: 3,
          width: 34,
          height: 43,
        ),
        const SizedBox(width: 9),
        _GeneratedPortrait(seed: ruler.id, size: 72),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                force.name,
                style: const TextStyle(
                  color: Color(0xffffdfa0),
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '군주 ${ruler.name}',
                style: const TextStyle(color: Color(0xffd6a85d), fontSize: 13),
              ),
              const SizedBox(height: 5),
              Text(
                '$provinceCount개 영지 · 장수 $officerCount명',
                style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _infoLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xffc1ab82))),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xffffdfa0),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _forceRelationRow(ForceState other, int relation, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AssetSlice(
              asset: AssetRepository.forceBannerStrip,
              index: other.bannerIndex,
              segments: 3,
              width: 19,
              height: 25,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                other.name,
                style: const TextStyle(color: Color(0xffe3c480)),
              ),
            ),
            Text(
              relation >= 30
                  ? '우호'
                  : relation <= -30
                  ? '적대'
                  : '중립',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text('$relation', style: TextStyle(color: color)),
          ],
        ),
      );

  Widget _officerChip(OfficerState officer) => Container(
    width: 86,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0x332c2115),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      children: [
        _GeneratedPortrait(seed: officer.id, size: 48),
        const SizedBox(height: 3),
        Text(
          officer.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xffe3c480), fontSize: 11),
        ),
        Text(
          '충성 ${officer.loyalty}',
          style: const TextStyle(color: Color(0xffaa9670), fontSize: 10),
        ),
      ],
    ),
  );

  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xffd6a85d),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
}

class _EnemyForceInfoScreen extends StatelessWidget {
  const _EnemyForceInfoScreen({required this.state, required this.force});
  final GameState state;
  final ForceState force;

  @override
  Widget build(BuildContext context) {
    final ruler = state.officers.firstWhere((o) => o.id == force.rulerId);
    final provinces = state.provinces
        .where((p) => p.ownerForceId == force.id)
        .toList();
    final officers = state.officers
        .where((o) => o.forceId == force.id)
        .toList();
    final soldiers = provinces.fold<int>(0, (sum, p) => sum + p.soldiers);
    final food = provinces.fold<int>(0, (sum, p) => sum + p.food);
    final averageLoyalty = officers.isEmpty
        ? 0
        : (officers.fold<int>(0, (sum, o) => sum + o.loyalty) / officers.length)
              .round();
    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff382818), Color(0xff181612)],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility,
                      color: Color(0xffd9af65),
                      size: 25,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '첩보 · 적 정보 결과',
                        style: TextStyle(
                          color: Color(0xffffdfa0),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: const Color(0xffffdfa0),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0x453d2b17),
                        border: Border.all(color: Color(force.mapColorValue)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          AssetSlice(
                            asset: AssetRepository.forceBannerStrip,
                            index: force.bannerIndex,
                            segments: 3,
                            width: 34,
                            height: 43,
                          ),
                          const SizedBox(width: 9),
                          _GeneratedPortrait(seed: ruler.id, size: 72),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  force.name,
                                  style: const TextStyle(
                                    color: Color(0xffffdfa0),
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '군주 ${ruler.name}',
                                  style: const TextStyle(
                                    color: Color(0xffd6a85d),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '첩보로 확인된 정보',
                                  style: TextStyle(
                                    color: Color(0xff73d18b),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _panel(
                      '기본 정보',
                      Column(
                        children: [
                          _line('총 병력', _formatNumber(soldiers)),
                          _line('군량', _formatNumber(food)),
                          _line('장수 수', '${officers.length}명'),
                          _line('평균 충성', '$averageLoyalty'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _panel(
                      '주요 장수',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: officers
                            .take(6)
                            .map(
                              (o) => Container(
                                width: 82,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0x332c2115),
                                  border: Border.all(
                                    color: const Color(0xff6d5230),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  children: [
                                    _GeneratedPortrait(seed: o.id, size: 48),
                                    const SizedBox(height: 3),
                                    Text(
                                      o.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xffe3c480),
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '충성 ${o.loyalty}',
                                      style: const TextStyle(
                                        color: Color(0xffaa9670),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _panel(
                      '영지 목록',
                      Column(
                        children: provinces
                            .map(
                              (p) => _line(
                                p.name,
                                '${_formatNumber(p.soldiers)}명',
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
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

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xffc1ab82))),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xffffdfa0),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xffd6a85d),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
}

class _ProvinceDetailScreen extends StatelessWidget {
  const _ProvinceDetailScreen({required this.province, required this.state});
  final ProvinceState province;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final force = state.forces.firstWhere((f) => f.id == province.ownerForceId);
    final governor = province.governorId == null
        ? null
        : state.officers.firstWhere((o) => o.id == province.governorId);
    final leader =
        governor ?? state.officers.firstWhere((o) => o.id == force.rulerId);
    final officers = state.officers
        .where((o) => province.officerIds.contains(o.id))
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff382818), Color(0xff181612)],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
                ),
                child: Row(
                  children: [
                    AssetSlice(
                      asset: AssetRepository.forceBannerStrip,
                      index: force.bannerIndex,
                      segments: 3,
                      width: 24,
                      height: 29,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        province.name,
                        style: const TextStyle(
                          color: Color(0xffffdfa0),
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: const Color(0xffffdfa0),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xff211b13),
                              border: Border.all(
                                color: const Color(0xff94703b),
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: _GeneratedPortrait(
                              seed: leader.id,
                              size: 112,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '태수 ${governor?.name ?? '미임명'} · 주둔 ${province.officerIds.length}명',
                                  style: const TextStyle(
                                    color: Color(0xffe5c98d),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xff6d5230),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _ProvinceStatColumn(
                                    values: [
                                      ('금', province.gold),
                                      ('군량', province.food),
                                      ('병력', province.soldiers),
                                      ('민심', province.publicLoyalty),
                                      ('개발', province.land),
                                      ('치수', province.floodControl),
                                      ('성벽', 35),
                                      (
                                        '성 규모',
                                        _settlementLabel(
                                          province.settlementType,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '지역 장수',
                        style: TextStyle(
                          color: Color(0xffffdfa0),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...officers.map(
                        (officer) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x441c1812),
                            border: Border.all(color: const Color(0xff5d472c)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              _GeneratedPortrait(seed: officer.id, size: 42),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  officer.name,
                                  style: const TextStyle(
                                    color: Color(0xfff0d9a4),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '충성 ${officer.loyalty}',
                                style: const TextStyle(
                                  color: Color(0xffc9ad78),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 62,
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xff1c1914),
                  border: Border(top: BorderSide(color: Color(0xff9b7138))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('세계 지도로 돌아가기'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff624826),
                      foregroundColor: const Color(0xffffdfa0),
                      side: const BorderSide(color: Color(0xffb98b4d)),
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
                  size: 16,
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
                  value.$2 is int ? _formatNumber(value.$2) : '${value.$2}',
                  style: const TextStyle(
                    color: Color(0xfff0d9a4),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 2)],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );

  static IconData _statIcon(String label) => switch (label) {
    '금' || '지역 금' => Icons.monetization_on_outlined,
    '군량' || '지역 군량' => Icons.grass,
    '병력' => Icons.shield_outlined,
    '민심' => Icons.people_alt_outlined,
    '개발' => Icons.construction_outlined,
    '치수' => Icons.water_drop_outlined,
    '성벽' => Icons.fort,
    '주둔 장수' => Icons.person_outline,
    '성 규모' => Icons.account_balance,
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
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff382818), Color(0xff181612)],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: Color(0xffd9af65), size: 25),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '출병 준비',
                        style: TextStyle(
                          color: Color(0xffffdfa0),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: const Color(0xffffdfa0),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xffc39450),
                      surface: Color(0xff231c15),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
                    children: [
                      _WarTargetCard(target: target),
                      const SizedBox(height: 16),
                      const Text(
                        '출발지',
                        style: TextStyle(
                          color: Color(0xffd6a85d),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      DropdownButtonFormField<String>(
                        initialValue: sourceId,
                        isExpanded: true,
                        decoration: _moveDecoration('출발 지역 선택'),
                        items: sources
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '${p.name} · 병력 ${_formatNumber(p.soldiers)}명',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (id) {
                          if (id != null) {
                            setState(() {
                              sourceId = id;
                              committed = (source!.soldiers * .65)
                                  .roundToDouble();
                              selectedOfficerIds
                                ..clear()
                                ..addAll(source!.officerIds);
                              commanderId = source!.officerIds.firstOrNull;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '출전 장수',
                        style: TextStyle(
                          color: Color(0xffd6a85d),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      if (current != null)
                        ...current.officerIds.map((id) {
                          final officer = widget.engine.state.officers
                              .firstWhere((o) => o.id == id);
                          return _WarOfficerTile(
                            officer: officer,
                            selected: selectedOfficerIds.contains(id),
                            commander: commanderId == id,
                            onChanged: (value) {
                              if (value == false &&
                                  selectedOfficerIds.length == 1) {
                                return;
                              }
                              setState(() {
                                if (value) {
                                  selectedOfficerIds.add(id);
                                  commanderId ??= id;
                                } else {
                                  selectedOfficerIds.remove(id);
                                  if (commanderId == id) {
                                    commanderId =
                                        selectedOfficerIds.firstOrNull;
                                  }
                                }
                              });
                            },
                          );
                        }),
                      if (selectedOfficerIds.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: commanderId,
                          isExpanded: true,
                          decoration: _moveDecoration('총대장 선택'),
                          items: selectedOfficerIds.map((id) {
                            final o = widget.engine.state.officers.firstWhere(
                              (x) => x.id == id,
                            );
                            return DropdownMenuItem(
                              value: id,
                              child: Text('${o.name} · WAR ${o.war}'),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) setState(() => commanderId = id);
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      _WarArmyCard(
                        current: current,
                        committed: committed,
                        max: max,
                        onChanged: (value) => setState(() => committed = value),
                      ),
                      const SizedBox(height: 14),
                      _WarCostCard(
                        committed: committed.round(),
                        remaining: (current?.soldiers ?? 0) - committed.round(),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: current == null || selectedOfficerIds.isEmpty
                            ? null
                            : _launch,
                        icon: const Icon(Icons.flag),
                        label: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('출병 확정'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff76572f),
                          foregroundColor: const Color(0xffffdfa0),
                          side: const BorderSide(color: Color(0xffc09351)),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarTargetCard extends StatelessWidget {
  const _WarTargetCard({required this.target});
  final ProvinceState target;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0x453d2118),
      border: Border.all(color: const Color(0xffa55d43)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        const Icon(Icons.gps_fixed, color: Color(0xffe17a5d), size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '목표 지역',
                style: TextStyle(color: Color(0xffc1ab82), fontSize: 12),
              ),
              Text(
                target.name,
                style: const TextStyle(
                  color: Color(0xffffdfa0),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '방어 ${_formatNumber(target.soldiers)}명',
              style: const TextStyle(color: Color(0xffffb08d), fontSize: 13),
            ),
            Text(
              target.ownerName,
              style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

class _WarOfficerTile extends StatelessWidget {
  const _WarOfficerTile({
    required this.officer,
    required this.selected,
    required this.commander,
    required this.onChanged,
  });
  final OfficerState officer;
  final bool selected, commander;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      color: selected ? const Color(0x453f2c18) : const Color(0x25231b11),
      border: Border.all(
        color: selected ? const Color(0xffb38343) : const Color(0xff5d472c),
      ),
      borderRadius: BorderRadius.circular(5),
    ),
    child: CheckboxListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      secondary: _GeneratedPortrait(seed: officer.id, size: 42),
      value: selected,
      activeColor: const Color(0xffb38343),
      title: Text(
        officer.name,
        style: const TextStyle(
          color: Color(0xffffdfa0),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        commander ? '총대장 · WAR ${officer.war}' : '출전 가능 · WAR ${officer.war}',
        style: TextStyle(
          color: commander ? const Color(0xffe2bd72) : const Color(0xffc1ab82),
          fontSize: 11,
        ),
      ),
      onChanged: (value) => onChanged(value ?? false),
    ),
  );
}

class _WarArmyCard extends StatelessWidget {
  const _WarArmyCard({
    required this.current,
    required this.committed,
    required this.max,
    required this.onChanged,
  });
  final ProvinceState? current;
  final double committed, max;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 5),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff8c6735)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '출전 병력',
              style: TextStyle(color: Color(0xffc1ab82), fontSize: 13),
            ),
            Text(
              '${_formatNumber(committed.round())}명',
              style: const TextStyle(
                color: Color(0xff73d18b),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Slider(
          min: 100,
          max: max < 100 ? 100 : max,
          divisions: max <= 100 ? 1 : (max - 100).round(),
          value: committed.clamp(100, max < 100 ? 100 : max),
          activeColor: const Color(0xffb88645),
          onChanged: current == null ? null : onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '최소 100명',
              style: const TextStyle(color: Color(0xff9e8969), fontSize: 11),
            ),
            Text(
              '가용 ${_formatNumber(current?.soldiers ?? 0)}명',
              style: const TextStyle(color: Color(0xff9e8969), fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

class _WarCostCard extends StatelessWidget {
  const _WarCostCard({required this.committed, required this.remaining});
  final int committed, remaining;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _CostMetric('군량', '-150', const Color(0xffe4a172)),
        _CostMetric(
          '출전',
          '${_formatNumber(committed)}명',
          const Color(0xffffdfa0),
        ),
        _CostMetric(
          '잔여',
          '${_formatNumber(remaining)}명',
          const Color(0xff73d18b),
        ),
      ],
    ),
  );
}

class _CostMetric extends StatelessWidget {
  const _CostMetric(this.label, this.value, this.color);
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xffa8906b), fontSize: 11),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class BattleResultScreen extends StatefulWidget {
  const BattleResultScreen({
    super.key,
    required this.engine,
    required this.battle,
    required this.outcomes,
  });
  final GameEngine engine;
  final BattleEngine battle;
  final List<BattleOfficerOutcome> outcomes;

  @override
  State<BattleResultScreen> createState() => _BattleResultScreenState();
}

class _BattleResultScreenState extends State<BattleResultScreen> {
  late final List<BattleOfficerOutcome> remainingPrisoners = widget.outcomes
      .where((o) => o.result == BattleOfficerResult.captured)
      .toList();

  String _resultLabel(BattleOfficerResult result) => switch (result) {
    BattleOfficerResult.escaped => '귀환',
    BattleOfficerResult.captured => '포로',
    BattleOfficerResult.dead => '전사',
  };

  Color _resultColor(BattleOfficerResult result) => switch (result) {
    BattleOfficerResult.escaped => const Color(0xff73d18b),
    BattleOfficerResult.captured => const Color(0xffe2bd72),
    BattleOfficerResult.dead => const Color(0xffe17a5d),
  };

  @override
  Widget build(BuildContext context) {
    final battle = widget.battle.state;
    final won = battle.attackerWon;
    final targetProvince = widget.engine.state.provinces.firstWhere(
      (p) => p.id == battle.targetProvinceId,
    );
    final prisoners = widget.outcomes
        .where((o) => o.result == BattleOfficerResult.captured)
        .length;
    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff382818), Color(0xff181612)],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
                ),
                child: Row(
                  children: [
                    Icon(
                      won ? Icons.emoji_events : Icons.warning_amber,
                      color: won
                          ? const Color(0xffe2bd72)
                          : const Color(0xffe17a5d),
                      size: 25,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '전투 결과',
                        style: const TextStyle(
                          color: Color(0xffffdfa0),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                  children: [
                    Center(
                      child: Text(
                        won ? '승리' : '패배',
                        style: TextStyle(
                          color: won
                              ? const Color(0xffe2bd72)
                              : const Color(0xffe17a5d),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text(
                        won
                            ? '${targetProvince.name}을 점령했습니다.'
                            : '공격군이 후퇴했습니다.',
                        style: const TextStyle(
                          color: Color(0xffc1ab82),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Center(
                      child: Text(
                        '종료 원인 · ${battle.finishReason ?? '전투 종료'}',
                        style: const TextStyle(
                          color: Color(0xffd6a85d),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0x35231b11),
                        border: Border.all(color: const Color(0xff8c6735)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _CostMetric(
                            '전투일',
                            '${battle.day}일',
                            const Color(0xffffdfa0),
                          ),
                          _CostMetric(
                            '잔여 병력',
                            '${_formatNumber(battle.returnedSoldiers)}명',
                            const Color(0xff73d18b),
                          ),
                          _CostMetric(
                            '포로',
                            '$prisoners명',
                            const Color(0xffe2bd72),
                          ),
                          _CostMetric(
                            '군량 잔량',
                            _formatNumber(battle.attackerFood),
                            const Color(0xffc1ab82),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (battle.battleLog.isNotEmpty) ...[
                      const Text(
                        '전투 기록',
                        style: TextStyle(
                          color: Color(0xffd6a85d),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x25231b11),
                          border: Border.all(color: const Color(0xff5d472c)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: battle.battleLog.reversed
                              .take(5)
                              .map(
                                (log) => Text(
                                  log,
                                  style: const TextStyle(
                                    color: Color(0xffc1ab82),
                                    fontSize: 11,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      '장수 결과',
                      style: TextStyle(
                        color: Color(0xffd6a85d),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ...widget.outcomes.map(
                      (outcome) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x25231b11),
                          border: Border.all(color: const Color(0xff5d472c)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            _GeneratedPortrait(
                              seed: outcome.officerId,
                              size: 38,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                outcome.name,
                                style: const TextStyle(
                                  color: Color(0xffffdfa0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${outcome.soldiers}명 · ${_resultLabel(outcome.result)}',
                              style: TextStyle(
                                color: _resultColor(outcome.result),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (remainingPrisoners.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '포로 처리',
                        style: TextStyle(
                          color: Color(0xffd6a85d),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      FilledButton.icon(
                        onPressed: () async {
                          final completed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => PrisonerManagementScreen(
                                    engine: widget.engine,
                                    provinceId:
                                        widget.battle.state.targetProvinceId,
                                    prisoners: remainingPrisoners,
                                  ),
                                ),
                              );
                          if (completed == true && mounted) {
                            setState(() => remainingPrisoners.clear());
                          }
                        },
                        icon: const Icon(Icons.gavel),
                        label: Text(
                          '${remainingPrisoners.length}명 포로 처리 화면 열기',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff76572f),
                          foregroundColor: const Color(0xffffdfa0),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ...remainingPrisoners.map(
                        (prisoner) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(10, 8, 5, 8),
                          decoration: BoxDecoration(
                            color: const Color(0x453d2b17),
                            border: Border.all(color: const Color(0xff8c6735)),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  prisoner.name,
                                  style: const TextStyle(
                                    color: Color(0xffffdfa0),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _handle(prisoner, PrisonerAction.recruit),
                                child: const Text('등용'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _handle(prisoner, PrisonerAction.release),
                                child: const Text('석방'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _handle(prisoner, PrisonerAction.execute),
                                child: const Text(
                                  '처형',
                                  style: TextStyle(color: Color(0xffe17a5d)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: remainingPrisoners.isEmpty
                          ? () => Navigator.pop(context)
                          : null,
                      icon: const Icon(Icons.check),
                      label: const Text('확인'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff76572f),
                        foregroundColor: const Color(0xffffdfa0),
                        side: const BorderSide(color: Color(0xffc09351)),
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

  void _handle(BattleOfficerOutcome prisoner, PrisonerAction action) {
    final handled = widget.engine.handlePrisoner(
      prisoner.officerId,
      action,
      widget.battle.state.targetProvinceId,
    );
    if (handled) setState(() => remainingPrisoners.remove(prisoner));
  }
}

class PrisonerManagementScreen extends StatefulWidget {
  const PrisonerManagementScreen({
    super.key,
    required this.engine,
    required this.provinceId,
    required this.prisoners,
  });
  final GameEngine engine;
  final String provinceId;
  final List<BattleOfficerOutcome> prisoners;

  @override
  State<PrisonerManagementScreen> createState() =>
      _PrisonerManagementScreenState();
}

class _PrisonerManagementScreenState extends State<PrisonerManagementScreen> {
  late final List<BattleOfficerOutcome> remaining = [...widget.prisoners];

  OfficerState _officer(BattleOfficerOutcome outcome) =>
      widget.engine.state.officers.firstWhere((o) => o.id == outcome.officerId);

  void _handle(BattleOfficerOutcome prisoner, PrisonerAction action) {
    final handled = widget.engine.handlePrisoner(
      prisoner.officerId,
      action,
      widget.provinceId,
    );
    if (handled) {
      setState(() => remaining.remove(prisoner));
    } else if (action == PrisonerAction.recruit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('등용에 필요한 금 500이 부족합니다.')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('포로 처리를 완료할 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090807),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff171612),
          image: const DecorationImage(
            image: AssetImage(AssetRepository.panelTexture),
            fit: BoxFit.cover,
            opacity: .12,
          ),
          border: Border.all(color: const Color(0xffb38343), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff382818), Color(0xff181612)],
                ),
                border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel, color: Color(0xffd9af65), size: 25),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '포로 처리',
                      style: TextStyle(
                        color: Color(0xffffdfa0),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: remaining.isEmpty
                        ? () => Navigator.pop(context, true)
                        : null,
                    icon: const Icon(Icons.close),
                    color: const Color(0xffffdfa0),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                children: [
                  const Center(
                    child: Text(
                      '포로로 잡힌 장수',
                      style: TextStyle(
                        color: Color(0xffffdfa0),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      '${remaining.length}명에 대한 처리를 결정하십시오',
                      style: const TextStyle(
                        color: Color(0xffc1ab82),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...remaining.map((prisoner) {
                    final officer = _officer(prisoner);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0x453d2b17),
                        border: Border.all(color: const Color(0xffa1763c)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _GeneratedPortrait(seed: officer.id, size: 78),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      officer.name,
                                      style: const TextStyle(
                                        color: Color(0xffffdfa0),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      'WAR ${officer.war}  ·  INT ${officer.intelligence}',
                                      style: const TextStyle(
                                        color: Color(0xffc1ab82),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'CHA ${officer.charisma}  ·  충성 ${officer.loyalty}',
                                      style: const TextStyle(
                                        color: Color(0xffc1ab82),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () =>
                                      _handle(prisoner, PrisonerAction.recruit),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xff76572f),
                                    foregroundColor: const Color(0xffffdfa0),
                                  ),
                                  child: const Text('등용 · 금 500'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _handle(prisoner, PrisonerAction.release),
                                  child: const Text('석방'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () =>
                                      _handle(prisoner, PrisonerAction.execute),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xff6b3025),
                                    foregroundColor: const Color(0xffffd2c4),
                                  ),
                                  child: const Text('처형'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: remaining.isEmpty
                        ? () => Navigator.pop(context, true)
                        : null,
                    icon: const Icon(Icons.check),
                    label: Text(remaining.isEmpty ? '처리 완료' : '모든 포로를 처리하십시오'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff76572f),
                      foregroundColor: const Color(0xffffdfa0),
                      side: const BorderSide(color: Color(0xffc09351)),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: remaining.isEmpty
                        ? () => Navigator.pop(context, true)
                        : null,
                    child: const Text('확인'),
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
  bool _resultOpened = false;
  bool _actionLocked = false;
  bool _autoBattleRunning = false;
  int _autoBattleSpeed = 1;

  @override
  void initState() {
    super.initState();
    selectedAttackerId =
        widget.battle.state.attackerUnits.firstOrNull?.officerId;
    selectedDefenderId =
        widget.battle.state.defenderUnits.firstOrNull?.officerId;
    widget.battle.state.selectedAttackerId = selectedAttackerId;
    widget.battle.state.selectedDefenderId = selectedDefenderId;
    battleGame = BattleGame(widget.battle.state, onCellTap: _onBattleCellTap);
  }

  @override
  void dispose() {
    _autoBattleRunning = false;
    super.dispose();
  }

  void _onBattleCellTap(BattleCell cell) {
    final battle = widget.battle.state;
    if (battle.finished || _actionLocked) return;
    final attacker = battle.attackerUnits
        .where((unit) => unit.row == cell.row && unit.column == cell.column)
        .firstOrNull;
    final defender = battle.defenderUnits
        .where((unit) => unit.row == cell.row && unit.column == cell.column)
        .firstOrNull;
    final selected = battle.selectedAttacker;
    if (attacker != null) {
      widget.battle.execute(BattleCommand.selectAttacker(attacker.officerId));
      setState(() {
        selectedAttackerId = attacker.officerId;
        selectedDefenderId = null;
      });
    } else if (defender != null) {
      final event = widget.battle.execute(
        BattleCommand.selectDefender(defender.officerId),
      );
      if (event.logMessage.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(event.logMessage)));
      }
      setState(() => selectedDefenderId = defender.officerId);
    } else if (selected != null && battle.movementCells.contains(cell)) {
      final event = widget.battle.execute(
        BattleCommand.move(
          unitId: selected.officerId,
          row: cell.row,
          column: cell.column,
        ),
      );
      if (event.logMessage.contains('없')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(event.logMessage)));
      }
      setState(() {});
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선택한 부대가 이동할 수 없는 칸입니다.')));
    }
    battleGame.refreshBoard();
  }

  Future<void> _act(BattleAction action) async {
    if (_actionLocked || widget.battle.state.finished) return;
    setState(() => _actionLocked = true);
    late final BattleResultEvent event;
    event = widget.battle.execute(
      BattleCommand.action(
        type: switch (action) {
          BattleAction.attack => BattleCommandType.attack,
          BattleAction.fire => BattleCommandType.fire,
          BattleAction.charge => BattleCommandType.charge,
          BattleAction.cooperate => BattleCommandType.cooperate,
          BattleAction.information => BattleCommandType.information,
          BattleAction.wait => BattleCommandType.wait,
        },
        attackerId: selectedAttackerId ?? '',
        defenderId: selectedDefenderId ?? '',
      ),
    );
    setState(() {});
    battleGame.refreshBoard();
    await battleGame.playEvent(event);
    if (!mounted) return;
    setState(() => _actionLocked = false);
    await _finishIfNeeded();
  }

  Future<void> _moveSelected() async {
    final unit = widget.battle.state.attackerUnits
        .where((u) => u.officerId == selectedAttackerId)
        .firstOrNull;
    if (unit == null) return;
    final cells = <List<int>>[];
    for (var row = 0; row < BattleState.boardRows; row++) {
      for (var column = 0; column < BattleState.boardColumns; column++) {
        if (!widget.battle.state.isAdjacent(unit, row, column)) continue;
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

  Future<void> _endBattleTurn() async {
    if (_actionLocked || widget.battle.state.finished) return;
    setState(() => _actionLocked = true);
    final event = widget.battle.execute(const BattleCommand.endTurn());
    setState(() {});
    battleGame.refreshBoard();
    await battleGame.playEvent(event);
    if (!mounted) return;
    setState(() => _actionLocked = false);
    await _finishIfNeeded();
  }

  void _toggleAutoBattle() {
    if (_autoBattleRunning) {
      setState(() => _autoBattleRunning = false);
      return;
    }
    if (widget.battle.state.finished) return;
    setState(() => _autoBattleRunning = true);
    _runAutoBattle();
  }

  void _cycleAutoBattleSpeed() {
    setState(() {
      _autoBattleSpeed = switch (_autoBattleSpeed) {
        1 => 2,
        2 => 4,
        _ => 1,
      };
    });
  }

  Duration get _autoStepDelay => Duration(
    milliseconds: switch (_autoBattleSpeed) {
      1 => 260,
      2 => 130,
      _ => 55,
    },
  );

  Duration get _autoTurnDelay => Duration(
    milliseconds: switch (_autoBattleSpeed) {
      1 => 420,
      2 => 210,
      _ => 90,
    },
  );

  Future<void> _runAutoBattle() async {
    while (mounted && _autoBattleRunning && !widget.battle.state.finished) {
      if (!widget.battle.state.isAttackerTurn) {
        await Future<void>.delayed(_autoStepDelay);
        continue;
      }

      final attacker = widget.battle.state.attackerUnits
          .where(
            (unit) =>
                unit.soldiers > 0 &&
                !widget.battle.state.actedUnitIds.contains(unit.officerId),
          )
          .firstOrNull;
      if (attacker == null) {
        await _autoEndTurn();
        continue;
      }
      final defender = _nearestDefender(attacker);
      if (defender == null) break;

      widget.battle.execute(BattleCommand.selectAttacker(attacker.officerId));
      final adjacent = widget.battle.state.isAdjacent(
        attacker,
        defender.row,
        defender.column,
      );
      late final BattleResultEvent event;
      if (adjacent) {
        widget.battle.execute(BattleCommand.selectDefender(defender.officerId));
        event = widget.battle.execute(
          BattleCommand.action(
            type: BattleCommandType.attack,
            attackerId: attacker.officerId,
            defenderId: defender.officerId,
          ),
        );
      } else {
        final movementCells = widget.battle.state.movementCells.toList()
          ..sort(
            (a, b) => _cellDistance(
              a,
              defender,
            ).compareTo(_cellDistance(b, defender)),
          );
        final destination = movementCells.firstOrNull;
        if (destination == null) {
          event = widget.battle.execute(
            BattleCommand.action(
              type: BattleCommandType.wait,
              attackerId: attacker.officerId,
              defenderId: defender.officerId,
            ),
          );
        } else {
          event = widget.battle.execute(
            BattleCommand.move(
              unitId: attacker.officerId,
              row: destination.row,
              column: destination.column,
            ),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        selectedAttackerId = attacker.officerId;
        selectedDefenderId = defender.officerId;
      });
      battleGame.refreshBoard();
      await battleGame.playEvent(event);
      await _finishIfNeeded();
      await Future<void>.delayed(_autoStepDelay);
    }

    if (mounted && _autoBattleRunning && widget.battle.state.finished) {
      setState(() => _autoBattleRunning = false);
    }
  }

  BattleUnit? _nearestDefender(BattleUnit attacker) {
    final defenders = widget.battle.state.defenderUnits.where(
      (unit) => unit.soldiers > 0,
    );
    return defenders.isEmpty
        ? null
        : defenders.reduce(
            (a, b) => _distance(attacker, a) <= _distance(attacker, b) ? a : b,
          );
  }

  int _distance(BattleUnit a, BattleUnit b) =>
      (a.row - b.row).abs() + (a.column - b.column).abs();

  int _cellDistance(BattleCell cell, BattleUnit unit) =>
      (cell.row - unit.row).abs() + (cell.column - unit.column).abs();

  Future<void> _autoEndTurn() async {
    if (!mounted || !_autoBattleRunning || widget.battle.state.finished) return;
    final event = widget.battle.execute(const BattleCommand.endTurn());
    setState(() {});
    battleGame.refreshBoard();
    await battleGame.playEvent(event);
    await _finishIfNeeded();
    await Future<void>.delayed(_autoTurnDelay);
  }

  Future<void> _finishIfNeeded() async {
    if (!widget.battle.state.finished) return;
    if (_resultOpened) return;
    _resultOpened = true;
    final outcomes = widget.engine.resolveBattle(widget.battle);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BattleResultScreen(
          engine: widget.engine,
          battle: widget.battle,
          outcomes: outcomes,
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
    return;

    // Legacy dialog flow retained below for reference during battle UI migration.
    // ignore: dead_code
    final remainingPrisoners = outcomes
        .where((o) => o.result == BattleOfficerResult.captured)
        .toList();
    await showDialog<void>(
      // ignore: use_build_context_synchronously
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
              BattleTopHud(battle: battle),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      AssetRepository.battleFieldBackground,
                      fit: BoxFit.cover,
                    ),
                    Container(color: Colors.black.withValues(alpha: .28)),
                    GameWidget(game: battleGame),
                  ],
                ),
              ),
              Offstage(
                offstage: true,
                child: Padding(
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
                                    : (id) => setState(
                                        () => selectedAttackerId = id,
                                      ),
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
                                    : (id) => setState(
                                        () => selectedDefenderId = id,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      if (battle.attackerUnits.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: battle.finished
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => _BattleUnitDetailScreen(
                                        battle: battle,
                                        unit: battle.attackerUnits.firstWhere(
                                          (u) =>
                                              u.officerId == selectedAttackerId,
                                          orElse: () =>
                                              battle.attackerUnits.first,
                                        ),
                                        onAction: (action) {
                                          Navigator.pop(context);
                                          _act(action);
                                        },
                                      ),
                                    ),
                                  ),
                            icon: const Icon(Icons.shield),
                            label: const Text('부대 상세 / 특수명령'),
                          ),
                        ),
                      ],
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
              ),
              BattleInfoPanel(battle: battle),
              BattleLogPanel(battle: battle),
              if (battle.attackerUnits.isNotEmpty &&
                  battle.defenderUnits.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                  padding: const EdgeInsets.fromLTRB(6, 0, 2, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xff15120e),
                    border: Border.all(color: const Color(0xff5e4728)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedAttackerId,
                            items: battle.attackerUnits
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u.officerId,
                                    child: Text(
                                      '아군 · ${u.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: battle.finished
                                ? null
                                : (id) {
                                    setState(() => selectedAttackerId = id);
                                    if (id != null) {
                                      widget.battle.execute(
                                        BattleCommand.selectAttacker(id),
                                      );
                                    }
                                    battleGame.refreshBoard();
                                  },
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('→'),
                      ),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedDefenderId,
                            items: battle.defenderUnits
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u.officerId,
                                    child: Text(
                                      '적군 · ${u.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: battle.finished
                                ? null
                                : (id) {
                                    setState(() => selectedDefenderId = id);
                                    if (id != null) {
                                      widget.battle.execute(
                                        BattleCommand.selectDefender(id),
                                      );
                                    }
                                    battleGame.refreshBoard();
                                  },
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '선택 해제',
                        onPressed: battle.finished
                            ? null
                            : () {
                                widget.battle.execute(
                                  const BattleCommand.clearSelection(),
                                );
                                setState(() {
                                  selectedAttackerId = null;
                                  selectedDefenderId = null;
                                });
                                battleGame.refreshBoard();
                              },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              BattleCommandBar(
                disabled:
                    battle.finished ||
                    !battle.isAttackerTurn ||
                    _autoBattleRunning,
                turnLabel: battle.phaseLabel,
                onMove: _moveSelected,
                onAction: _act,
                onInfo: () => _act(BattleAction.information),
                onEndTurn: _endBattleTurn,
                onAutoToggle: _toggleAutoBattle,
                autoRunning: _autoBattleRunning,
                onAutoSpeedCycle: _cycleAutoBattleSpeed,
                autoSpeed: _autoBattleSpeed,
                onRetreat: () {
                  widget.battle.retreat();
                  _finishIfNeeded();
                },
              ),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  color: Color(0xff100e0b),
                  border: Border(top: BorderSide(color: Color(0xff4f402a))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: battle.finished
                          ? null
                          : () => _act(BattleAction.charge),
                      icon: const BattleSpriteIcon(
                        asset: AssetRepository.battleIconCharge,
                        semanticLabel: '돌격',
                        size: 15,
                      ),
                      label: const Text('돌격'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xffffd995),
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: battle.finished
                          ? null
                          : () => _act(BattleAction.cooperate),
                      icon: const BattleSpriteIcon(
                        asset: AssetRepository.battleIconCooperate,
                        semanticLabel: '협공',
                        size: 15,
                      ),
                      label: const Text('협공'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xffffd995),
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        textStyle: const TextStyle(fontSize: 11),
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
}

class _BattleUnitDetailScreen extends StatelessWidget {
  const _BattleUnitDetailScreen({
    required this.battle,
    required this.unit,
    required this.onAction,
  });
  final BattleState battle;
  final BattleUnit unit;
  final void Function(BattleAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                  children: [
                    _identity(),
                    const SizedBox(height: 10),
                    _panel(
                      '부대 능력',
                      Column(
                        children: [
                          _line('병력', _formatNumber(unit.soldiers)),
                          _line('사기', '${unit.morale}'),
                          _line('무력 WAR', '${unit.war}'),
                          _line('지력 INT', '${unit.intelligence}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _panel(
                      '장비 / 상태',
                      Column(
                        children: [
                          _line('무기', '기본 무기'),
                          _line('군마', '보유'),
                          _line('방어', '기본 갑옷'),
                          _line('지형', _terrainLabel(battle.terrain)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _panel(
                      '특수명령',
                      Column(
                        children: [
                          _command(
                            '화공',
                            Icons.local_fire_department,
                            BattleAction.fire,
                          ),
                          _command('돌격', Icons.bolt, BattleAction.charge),
                          _command(
                            '협공',
                            Icons.group_work,
                            BattleAction.cooperate,
                          ),
                          _command('대기', Icons.pause, BattleAction.wait),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => onAction(BattleAction.information),
                      icon: const Icon(Icons.visibility),
                      label: const Text('정보'),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => onAction(BattleAction.wait),
                      icon: const Icon(Icons.undo),
                      label: const Text('퇴각'),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
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

  Widget _header(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.shield, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '전투 · 부대 상세',
            style: TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _identity() => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0x453d2b17),
      border: Border.all(color: const Color(0xffa1763c)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        _GeneratedPortrait(seed: unit.officerId, size: 82),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unit.name,
                style: const TextStyle(
                  color: Color(0xffffdfa0),
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${battle.attackerName} · ${battle.commanderName.isEmpty ? '출전 부대' : '총대장 ${battle.commanderName}'}',
                style: const TextStyle(color: Color(0xffd6a85d), fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                '전투 ${battle.day}일째',
                style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _command(String label, IconData icon, BattleAction action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => onAction(action),
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xff76572f),
          foregroundColor: const Color(0xffffdfa0),
          side: const BorderSide(color: Color(0xffc09351)),
          minimumSize: const Size.fromHeight(42),
        ),
      ),
    ),
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xffc1ab82))),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xffffdfa0),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xffd6a85d),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );

  String _terrainLabel(TerrainType terrain) => switch (terrain) {
    TerrainType.plain => '평원',
    TerrainType.forest => '숲',
    TerrainType.mountain => '산지',
    TerrainType.river => '강',
    TerrainType.fort => '성',
  };
}

class _OfficerListScreen extends StatefulWidget {
  const _OfficerListScreen({required this.state});
  final GameState state;

  @override
  State<_OfficerListScreen> createState() => _OfficerListScreenState();
}

class _OfficerListScreenState extends State<_OfficerListScreen> {
  String? provinceId;

  List<OfficerState> get officers => widget.state.officers.where((officer) {
    if (officer.forceId != widget.state.playerForceId) return false;
    if (provinceId == null) return true;
    return officer.provinceId == provinceId;
  }).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090807),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff171612),
          image: const DecorationImage(
            image: AssetImage(AssetRepository.panelTexture),
            fit: BoxFit.cover,
            opacity: .12,
          ),
          border: Border.all(color: const Color(0xffb38343), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _officerHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: provinceId,
                      dropdownColor: const Color(0xff2b2117),
                      style: const TextStyle(color: Color(0xffffdfa0)),
                      decoration: _moveDecoration('소속 도시'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('전체 도시'),
                        ),
                        ...widget.state.provinces
                            .where((p) => widget.state.isPlayerProvince(p))
                            .map(
                              (p) => DropdownMenuItem<String?>(
                                value: p.id,
                                child: Text(p.name),
                              ),
                            ),
                      ],
                      onChanged: (id) => setState(() => provinceId = id),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${officers.length}명',
                    style: const TextStyle(
                      color: Color(0xffe3c480),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: officers.isEmpty
                  ? const Center(
                      child: Text(
                        '등록된 장수가 없습니다.',
                        style: TextStyle(color: Color(0xffc1ab82)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
                      itemCount: officers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) =>
                          _officerCard(context, officers[index]),
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _officerHeader(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.groups, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '장수 목록',
            style: const TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          widget.state.playerForce.name,
          style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _officerCard(BuildContext context, OfficerState officer) {
    final province = widget.state.provinces
        .where((p) => p.id == officer.provinceId)
        .firstOrNull;
    final isGovernor = province?.governorId == officer.id;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              _OfficerDetailScreen(state: widget.state, officer: officer),
        ),
      ),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x453d2b17),
          border: Border.all(color: const Color(0xff805e34)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            _GeneratedPortrait(seed: officer.id, size: 58),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          officer.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xffffdfa0),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isGovernor) ...[
                        const SizedBox(width: 6),
                        const Text(
                          '태수',
                          style: TextStyle(
                            color: Color(0xffe3b967),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${province?.name ?? '재야'} · ${officer.status}',
                    style: const TextStyle(
                      color: Color(0xffbda783),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'WAR ${officer.war}   INT ${officer.intelligence}   CHA ${officer.charisma}',
                    style: const TextStyle(
                      color: Color(0xffd7bc87),
                      fontSize: 11,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.favorite, color: Color(0xffbd8b45), size: 16),
                const SizedBox(height: 2),
                Text(
                  '${officer.loyalty}',
                  style: const TextStyle(
                    color: Color(0xffffdfa0),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 3),
            const Icon(Icons.chevron_right, color: Color(0xffa98451)),
          ],
        ),
      ),
    );
  }
}

class _OfficerDetailScreen extends StatelessWidget {
  const _OfficerDetailScreen({required this.state, required this.officer});
  final GameState state;
  final OfficerState officer;

  @override
  Widget build(BuildContext context) {
    final province = state.provinces
        .where((p) => p.id == officer.provinceId)
        .firstOrNull;
    final force = state.forces.firstWhere((f) => f.id == officer.forceId);
    final isGovernor = province?.governorId == officer.id;
    return Scaffold(
      backgroundColor: const Color(0xff090807),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xff171612),
            image: const DecorationImage(
              image: AssetImage(AssetRepository.panelTexture),
              fit: BoxFit.cover,
              opacity: .12,
            ),
            border: Border.all(color: const Color(0xffb38343), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                  children: [
                    _identity(force, province, isGovernor),
                    const SizedBox(height: 12),
                    _panel(
                      '능력치',
                      Column(
                        children: [
                          _ability(
                            '무력 WAR',
                            officer.war,
                            Icons.shield,
                            const Color(0xffd37b5d),
                          ),
                          _ability(
                            '지력 INT',
                            officer.intelligence,
                            Icons.auto_awesome,
                            const Color(0xff74b4bd),
                          ),
                          _ability(
                            '매력 CHA',
                            officer.charisma,
                            Icons.people,
                            const Color(0xffd6a85d),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _panel(
                      '현재 상태',
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _CostMetric(
                            '병력',
                            _formatNumber(
                              state.provinces
                                      .where((p) => p.id == officer.provinceId)
                                      .firstOrNull
                                      ?.soldiers ??
                                  0,
                            ),
                            const Color(0xffffdfa0),
                          ),
                          _CostMetric(
                            '소속',
                            province?.name ?? '재야',
                            const Color(0xffd6a85d),
                          ),
                          _CostMetric(
                            '임무',
                            isGovernor ? '태수' : '대기',
                            const Color(0xff73d18b),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _panel(
                      '인연 관계',
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _relation('동료', Icons.people),
                          _relation('군주', Icons.account_balance),
                          _relation('세력', Icons.flag),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('포상·추방 명령은 인사 시스템에서 이어집니다.'),
                            ),
                          ),
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text('인사 명령 열기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffe3c480),
                        side: const BorderSide(color: Color(0xff8b6937)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 7),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
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

  Widget _header(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.person_search, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '장수 상세',
            style: TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _identity(
    ForceState force,
    ProvinceState? province,
    bool governor,
  ) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0x453d2b17),
      border: Border.all(color: const Color(0xffa1763c)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        _GeneratedPortrait(seed: officer.id, size: 118),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                officer.name,
                style: const TextStyle(
                  color: Color(0xffffdfa0),
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                force.name,
                style: const TextStyle(color: Color(0xffd6a85d), fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '${province?.name ?? '재야'} · ${governor ? '태수' : officer.status}',
                style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Color(0xffd6a85d),
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '충성도 ${officer.loyalty}',
                    style: const TextStyle(
                      color: Color(0xffffdfa0),
                      fontWeight: FontWeight.w700,
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

  Widget _ability(String label, int value, IconData icon, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: const TextStyle(color: Color(0xffc1ab82), fontSize: 13),
              ),
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 7,
                backgroundColor: const Color(0xff49342a),
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 28,
              child: Text(
                '$value',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xffffdfa0),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _relation(String label, IconData icon) => Column(
    children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xff4b3925),
        child: Icon(icon, color: const Color(0xffd6a85d), size: 20),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(color: Color(0xffc1ab82), fontSize: 11),
      ),
    ],
  );

  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
    decoration: BoxDecoration(
      color: const Color(0x35231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xffd6a85d),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    ),
  );
}

// Legacy compact officer sheet retained for alternate layouts.
// ignore: unused_element
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

// ignore: unused_element
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

class _SaveLoadScreen extends StatefulWidget {
  const _SaveLoadScreen({
    required this.state,
    required this.repository,
    required this.onSave,
    required this.onLoad,
  });
  final GameState state;
  final SaveRepository repository;
  final Future<void> Function(String slot) onSave;
  final void Function(Map<String, dynamic> data) onLoad;

  @override
  State<_SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<_SaveLoadScreen> {
  static const slots = ['AUTO', '1', '2', '3', '4', '5'];
  final Map<String, Map<String, dynamic>?> saves = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final loaded = <String, Map<String, dynamic>?>{};
    for (final slot in slots) {
      loaded[slot] = await widget.repository.load(slot);
    }
    if (!mounted) return;
    setState(() {
      saves
        ..clear()
        ..addAll(loaded);
      loading = false;
    });
  }

  Future<void> _save(String slot) async {
    await widget.onSave(slot);
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$slot 슬롯에 저장했습니다.')));
  }

  Future<void> _delete(String slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$slot 슬롯 삭제'),
        content: const Text('이 저장 데이터를 삭제하시겠습니까? 삭제 후 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.delete(slot);
    await _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090807),
    body: SafeArea(
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xff171612),
          image: const DecorationImage(
            image: AssetImage(AssetRepository.panelTexture),
            fit: BoxFit.cover,
            opacity: .12,
          ),
          border: Border.all(color: const Color(0xffb38343), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xffd6a85d),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                      children: [
                        _currentState(),
                        const SizedBox(height: 10),
                        ...slots.map(_slotCard),
                        const SizedBox(height: 7),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('닫기'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.save, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '저장 / 불러오기',
            style: TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _currentState() => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0x453d2b17),
      border: Border.all(color: const Color(0xffa1763c)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        const Icon(Icons.bookmark, color: Color(0xffd6a85d), size: 25),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '현재 진행 상태',
                style: TextStyle(color: Color(0xffc1ab82), fontSize: 12),
              ),
              Text(
                '${widget.state.year}년 ${widget.state.month}월 · ${widget.state.playerForce.name}',
                style: const TextStyle(
                  color: Color(0xffffdfa0),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Text(
          '자동 저장 가능',
          style: const TextStyle(color: Color(0xff73d18b), fontSize: 11),
        ),
      ],
    ),
  );

  Widget _slotCard(String slot) {
    final data = saves[slot];
    final savedData = data;
    final exists = savedData != null;
    final forceName = exists ? _forceName(savedData) : '비어 있음';
    final date = exists
        ? '${savedData['year']}년 ${savedData['month']}월'
        : '저장 데이터 없음';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
      decoration: BoxDecoration(
        color: const Color(0x35231b11),
        border: Border.all(
          color: slot == 'AUTO'
              ? const Color(0xffa1763c)
              : const Color(0xff6d5230),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xff3b2a19),
              border: Border.all(color: const Color(0xff8c6735)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              slot,
              style: const TextStyle(
                color: Color(0xffffdfa0),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exists ? forceName : '빈 슬롯',
                  style: const TextStyle(
                    color: Color(0xffffdfa0),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xffc1ab82),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (exists) ...[
            IconButton(
              tooltip: '불러오기',
              onPressed: () => widget.onLoad(savedData),
              icon: const Icon(Icons.folder_open),
              color: const Color(0xffd6a85d),
            ),
            IconButton(
              tooltip: '삭제',
              onPressed: () => _delete(slot),
              icon: const Icon(Icons.delete_outline),
              color: const Color(0xffd37b5d),
            ),
          ],
          IconButton(
            tooltip: '저장',
            onPressed: () => _save(slot),
            icon: const Icon(Icons.save),
            color: const Color(0xff73d18b),
          ),
        ],
      ),
    );
  }

  String _forceName(Map<String, dynamic> data) {
    final forces = data['forces'];
    if (forces is List) {
      for (final raw in forces) {
        if (raw is Map && raw['id'] == data['playerForceId']) {
          return '${raw['name'] ?? '세력'}';
        }
      }
    }
    return '세력 정보 없음';
  }
}

class _MonthlyEventReportScreen extends StatelessWidget {
  const _MonthlyEventReportScreen({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xff090807),
        body: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xff171612),
              image: const DecorationImage(
                image: AssetImage(AssetRepository.panelTexture),
                fit: BoxFit.cover,
                opacity: .12,
              ),
              border: Border.all(color: const Color(0xffb38343), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _header(context),
                Container(
                  color: const Color(0x332c2115),
                  child: const TabBar(
                    indicatorColor: Color(0xffd6a85d),
                    labelColor: Color(0xffffdfa0),
                    unselectedLabelColor: Color(0xff9d8967),
                    tabs: [
                      Tab(text: '월간 이벤트'),
                      Tab(text: 'AI 보고'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(children: [_events(), _aiReports(context)]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xff382818), Color(0xff181612)]),
      border: Border(bottom: BorderSide(color: Color(0xffbd8b45))),
    ),
    child: Row(
      children: [
        const Icon(Icons.event_note, color: Color(0xffd9af65), size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '월간 이벤트 · AI 보고',
            style: TextStyle(
              color: Color(0xffffdfa0),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: const Color(0xffffdfa0),
        ),
      ],
    ),
  );

  Widget _events() {
    final logs = state.gameLog.reversed.take(12).toList();
    final event = state.lastEvent;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      children: [
        _periodCard(
          '현재 월',
          '${state.year}년 ${state.month}월',
          Icons.calendar_month,
        ),
        const SizedBox(height: 10),
        if (event != null)
          _eventTile(
            '월말 사건',
            event,
            Icons.auto_awesome,
            const Color(0xffd6a85d),
          ),
        if (event != null) const SizedBox(height: 8),
        if (logs.isEmpty)
          _empty('아직 기록된 월간 사건이 없습니다.')
        else
          ...logs.map(
            (log) => _eventTile(
              '게임 기록',
              log,
              Icons.article,
              const Color(0xff9eb8a0),
            ),
          ),
      ],
    );
  }

  Widget _aiReports(BuildContext context) {
    if (state.lastTurnReports.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
        children: [_empty('이번 달 AI 전투 보고가 없습니다.')],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      children: [
        _periodCard(
          'AI 세력 동향',
          '${state.lastTurnReports.length}건의 전투 보고',
          Icons.account_tree,
        ),
        const SizedBox(height: 10),
        ...state.lastTurnReports.map(
          (report) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0x35231b11),
              border: Border.all(color: const Color(0xff6d5230)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      report.attackerWon ? Icons.flag : Icons.shield,
                      color: report.attackerWon
                          ? const Color(0xffd6a85d)
                          : const Color(0xff9eb8a0),
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${report.attackerName} · ${report.targetProvinceName}',
                        style: const TextStyle(
                          color: Color(0xffffdfa0),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      report.attackerWon ? '공격 승리' : '방어 성공',
                      style: TextStyle(
                        color: report.attackerWon
                            ? const Color(0xff73d18b)
                            : const Color(0xffd37b5d),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '방어: ${report.defenderName} · ${report.day}일째 종료',
                  style: const TextStyle(
                    color: Color(0xffc1ab82),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '병력 ${_formatNumber(report.attackerSoldiers)} : ${_formatNumber(report.defenderSoldiers)}',
                  style: const TextStyle(
                    color: Color(0xffc1ab82),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AiBattleReplayScreen(report: report),
                    ),
                  ),
                  child: const Text('전투 관전'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _periodCard(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x453d2b17),
      border: Border.all(color: const Color(0xffa1763c)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xffd6a85d), size: 25),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xffc1ab82), fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xffffdfa0),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _eventTile(String title, String body, IconData icon, Color color) =>
      Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x35231b11),
          border: Border.all(color: const Color(0xff6d5230)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xffc1ab82),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _empty(String text) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0x25231b11),
      border: Border.all(color: const Color(0xff6d5230)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xffc1ab82)),
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
                      AssetRepository.battleFieldBackground,
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
