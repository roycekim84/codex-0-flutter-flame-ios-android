import 'package:flutter/material.dart';

import '../core/game_engine.dart';
import '../data/demo_scenario.dart';
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
    home: const GameScreen(),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameEngine engine;
  String? selectedProvinceId;
  @override
  void initState() {
    super.initState();
    engine = GameEngine(GameState.fromScenario(DemoScenario.create()));
    selectedProvinceId = engine.state.playerProvinceIds.first;
    engine.addListener(_refresh);
  }

  void _refresh() => setState(() {});
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
                selectedId: selectedProvinceId,
                onSelect: (id) => setState(() => selectedProvinceId = id),
              ),
            ),
            _ProvincePanel(province: selected),
            _ActionBar(engine: engine, province: selected),
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
    required this.selectedId,
    required this.onSelect,
  });
  final List<ProvinceState> provinces;
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
  const _ProvinceNode({required this.province, required this.selected});
  final ProvinceState province;
  final bool selected;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: province.isPlayerOwned
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
  const _ProvincePanel({required this.province});
  final ProvinceState province;
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
          province.isPlayerOwned ? '내 영지' : '타 세력',
          style: TextStyle(
            color: province.isPlayerOwned ? Colors.green : Colors.red,
          ),
        ),
      ],
    ),
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.engine, required this.province});
  final GameEngine engine;
  final ProvinceState province;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.tonal(
          onPressed: province.isPlayerOwned
              ? () => engine.develop(province.id)
              : null,
          child: const Text('개발'),
        ),
        FilledButton.tonal(
          onPressed: province.isPlayerOwned
              ? () => engine.recruit(province.id)
              : null,
          child: const Text('징병'),
        ),
        FilledButton.tonal(
          onPressed: province.isPlayerOwned
              ? () => engine.moveFirstOfficerTo(province.id)
              : null,
          child: const Text('장수 이동'),
        ),
        FilledButton(onPressed: engine.endTurn, child: const Text('턴 종료')),
      ],
    ),
  );
}
