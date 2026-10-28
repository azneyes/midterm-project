// 화면 R: 선수 랭킹 (GET /players?_sort=rank)
//
// ┌──────── 디자인 가이드 대응표: R 선수 랭킹 ──────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)   │
// │ R-1  │ AppBar                            │ 선수 랭킹 제목줄      │ P04 일관성    │
// │ R-2  │ SegmentedButton (남자 | 여자)      │ 부문 선택             │ P06 재인      │
// │ R-3  │ ListView + Card (PlayerRankTile)  │ 랭킹 목록             │ P08 미니멀    │
// │ R-4  │ GridView (넓은 화면 ≥600dp)        │ 랭킹 2열 격자         │ 적응형        │
// │ R-5  │ Text(rankChange ▲▼)               │ 순위 변동 표시        │ P01 가시성    │
// │ R-6  │ LoadingView · ErrorView · EmptyView│ 3상태                │ P01 · P09     │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환: R → P 는 쌓기(Navigator.push).  순위는 db.json의 rank 값 그대로 (계산 없음).
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'player_screen.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({
    super.key,
    this.load = fetchPlayers,
    this.loadMatches = fetchMatches,
  });

  final Loader<Player> load;
  final LoaderById<MatchRecord> loadMatches;

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  late Future<List<Player>> _future = widget.load();

  // 부문 선택 = 화면 안 표시 변화 → setState (허용)
  // STATE: 선수 검색어 · 지역 필터 → R-3 목록 — v2 이후 상태관리로 구현 (지금은 표시만)
  String _division = '남자';

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  void _open(Player p) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PlayerScreen(player: p, loadMatches: widget.loadMatches),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('선수 랭킹')), // R-1 P04
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: RebuildOnFontLoad(
              child: SegmentedButton<String>(
                // R-2 P06
                segments: const [
                  ButtonSegment(value: '남자', label: Text('남자')),
                  ButtonSegment(value: '여자', label: Text('여자')),
                ],
                selected: {_division},
                onSelectionChanged: (s) => setState(() {
                  _division = s.first;
                }),
              ),
            ),
          ),
          Expanded(
            child: AsyncListView<Player>(
              // R-6 P01 · P09
              future: _future,
              onRetry: _retry,
              loadingLabel: '랭킹을 불러오는 중…',
              errorTitle: '랭킹을 불러오지 못했습니다.',
              emptyMessage: '아직 발표된 랭킹이 없습니다.',
              builder: (context, all) {
                final players = all
                    .where((p) => p.division == _division)
                    .toList();
                if (players.isEmpty) {
                  return EmptyView(message: '$_division 부문 랭킹이 없습니다.');
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= wideBreakpoint) {
                      return GridView.builder(
                        // R-4 넓은 화면: 2열 이상 격자
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 420,
                              mainAxisExtent: 84,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: players.length,
                        itemBuilder: (context, i) => PlayerRankTile(
                          players[i],
                          margin: EdgeInsets.zero,
                          onTap: () => _open(players[i]),
                        ),
                      );
                    }
                    return ListView.builder(
                      // R-3 폰: 목록
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: players.length,
                      itemBuilder: (context, i) => PlayerRankTile(
                        players[i],
                        onTap: () => _open(players[i]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 랭킹 한 줄 — 순위 · 이름 · 소속 · 포인트 · 순위 변동
class PlayerRankTile extends StatelessWidget {
  const PlayerRankTile(
    this.player, {
    super.key,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  final Player player;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final scheme = Theme.of(context).colorScheme;
    final changeColor = switch (p.rankChange) {
      final c when c.startsWith('▲') => scheme.primary,
      final c when c.startsWith('▼') => scheme.error,
      _ => scheme.outline,
    };
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: p.rank <= 3
              ? scheme.primary
              : scheme.surfaceContainerHighest,
          foregroundColor: p.rank <= 3 ? scheme.onPrimary : scheme.onSurface,
          child: Text('${p.rank}'),
        ),
        title: Text(p.name),
        subtitle: Text('${p.club} · 승률 ${p.winRate}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${p.points}P', style: Theme.of(context).textTheme.titleSmall),
            Text(
              p.rankChange,
              style: TextStyle(color: changeColor, fontSize: 12),
            ), // R-5 P01
          ],
        ),
      ),
    );
  }
}
