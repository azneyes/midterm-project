// 화면 P: 선수 프로필 — 기본 기록 + 경기 기록 (GET /matches?playerId=)
//
// ┌──────── 디자인 가이드 대응표: P 선수 프로필 ────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)    │
// │ P-1  │ AppBar + BackButton               │ 선수 프로필 제목줄    │ P03 통제·자유  │
// │ P-2  │ Card(CircleAvatar + Text)         │ 선수 정보 카드        │ P08 미니멀     │
// │ P-3  │ Row(_StatBox × 3)                 │ 승 · 패 · 승률        │ P01 가시성     │
// │ P-4  │ FilledButton.tonal → 모달 시트    │ AI 경기력 분석 버튼   │ P07 효율성     │
// │ P-5  │ FutureBuilder(GET /matches)       │ 최근 경기 기록        │ P01 · P09      │
// │ P-6  │ LayoutBuilder (≥600dp 2단)        │ 정보 | 기록 나란히    │ 적응형         │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환: R → P 쌓기(push) · P → A 덮기(modal)
// ※ 모든 선수는 가상 인물입니다 (실제 개인정보 사용 금지 — 안내 5장).
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'analysis_sheet.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.player,
    this.loadMatches = fetchMatches,
  });

  final Player player;
  final LoaderById<MatchRecord> loadMatches;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late Future<List<MatchRecord>> _future = widget.loadMatches(widget.player.id);

  // STATE: 선수 팔로우 여부 → P-1 팔로우 아이콘 · 경기 알림 — v2 이후 상태관리로 구현 (지금은 표시만)

  void _retry() {
    setState(() {
      _future = widget.loadMatches(widget.player.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final profile = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileCard(player: p), // P-2 P08
        const SizedBox(height: 12),
        Row(
          // P-3 P01
          children: [
            _StatBox(label: '승', value: '${p.wins}'),
            const SizedBox(width: 8),
            _StatBox(label: '패', value: '${p.losses}'),
            const SizedBox(width: 8),
            _StatBox(label: '승률', value: p.winRate),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          // P-4 P07: 기록을 읽고 해석하는 대신 한 번에 강점·약점 확인
          onPressed: () => AnalysisSheet.show(context, p),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('AI 경기력 분석 카드'),
        ), // P-4 P07
      ],
    );
    final records = AsyncListView<MatchRecord>(
      // P-5 P01 · P09
      future: _future,
      onRetry: _retry,
      loadingLabel: '경기 기록을 불러오는 중…',
      errorTitle: '경기 기록을 불러오지 못했습니다.',
      emptyMessage: '아직 경기 기록이 없습니다.',
      builder: (context, matches) =>
          Column(children: [for (final m in matches) _MatchTile(m)]),
    );
    return Scaffold(
      appBar: AppBar(title: Text(p.name)), // P-1 P03
      body: LayoutBuilder(
        // P-6 적응형: 넓으면 정보 | 기록 2단, 좁으면 위아래
        builder: (context, constraints) {
          if (constraints.maxWidth >= wideBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: profile,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionTitle('최근 경기 기록', icon: Icons.history),
                        records,
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              profile,
              const SectionTitle('최근 경기 기록', icon: Icons.history),
              records,
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 28, child: Text(p.name.characters.first)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: text.titleLarge),
                  Text('${p.club} · ${p.region}', style: text.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    '${p.division} 랭킹 ${p.rank}위 · ${p.points}P (${p.rankChange})',
                    style: text.labelLarge,
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

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: text.titleLarge),
            Text(label, style: text.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile(this.match);

  final MatchRecord match;

  @override
  Widget build(BuildContext context) {
    final m = match;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: StatusBadge(m.result), // P01: 승 · 패 · 진행중
      title: Text('vs ${m.opponent}  ${m.score}'),
      subtitle: Text('${m.date} · ${m.tournament} ${m.round}'),
    );
  }
}
