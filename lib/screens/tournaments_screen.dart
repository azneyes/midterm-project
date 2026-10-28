// 화면 T: 대회 일정 (GET /tournaments) — 첫 화면
//
// ┌──────── 디자인 가이드 대응표: T 대회 일정 ──────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)   │
// │ T-1  │ AppBar                            │ 대회 일정 제목줄      │ P04 일관성    │
// │ T-2  │ ChoiceChip × 4 (가로 스크롤)      │ 대회 상태 필터        │ P07 효율성    │
// │ T-3  │ ListView + Card (TournamentCard)  │ 대회 카드 목록        │ P08 미니멀    │
// │ T-4  │ GridView (넓은 화면 ≥600dp)        │ 대회 카드 격자        │ 적응형        │
// │ T-5  │ StatusBadge + Text(dDay)          │ 접수 상태·마감 안내   │ P01 가시성    │
// │ T-6  │ LoadingView                       │ 불러오는 중 표시      │ P01 가시성    │
// │ T-7  │ ErrorView + FilledButton          │ 오류 안내·다시 시도   │ P09 오류 복구 │
// │ T-8  │ EmptyView                         │ 빈 목록 안내          │ P01 가시성    │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환: T → D 는 쌓기(Navigator.push).  적응형: LayoutBuilder 600dp 분기(T-3 ↔ T-4).
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'tournament_detail_screen.dart';

const _filters = ['전체', '접수중', '진행중', '종료'];

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({
    super.key,
    this.load = fetchTournaments,
    this.loadBrackets = fetchBrackets,
    this.loadResults = fetchResults,
  });

  /// 데이터를 가져오는 함수 — 앱은 기본값(GET), 테스트는 가짜 함수를 넣는다.
  final Loader<Tournament> load;
  final LoaderById<BracketMatch> loadBrackets;
  final LoaderById<Standing> loadResults;

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  late Future<List<Tournament>> _future = widget.load();

  // 필터 선택 = 화면 안 표시 변화 → setState (허용). 받은 목록 중 상태가 같은 것만 보여 준다.
  // STATE: 지역·종목 필터, 관심 대회 → T-2 · T-3 — v2 이후 상태관리로 구현 (지금은 표시만)
  String _filter = _filters.first;

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  void _open(Tournament t) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TournamentDetailScreen(
          tournament: t,
          loadBrackets: widget.loadBrackets,
          loadResults: widget.loadResults,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('대회 일정')), // T-1 P04
      body: Column(
        children: [
          SingleChildScrollView(
            // T-2 P07: 상태 필터 — 한 번 눌러 접수 중인 대회만
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (_) => setState(() {
                        _filter = f;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncListView<Tournament>(
              // T-6 P01 · T-7 P09 · T-8 P01
              future: _future,
              onRetry: _retry,
              loadingLabel: '대회 일정을 불러오는 중…',
              errorTitle: '대회 일정을 불러오지 못했습니다.',
              emptyMessage: '아직 등록된 대회가 없습니다.',
              builder: (context, all) {
                final items = _filter == '전체'
                    ? all
                    : all.where((t) => t.status == _filter).toList();
                if (items.isEmpty) {
                  return EmptyView(message: "'$_filter' 대회가 없습니다."); // T-8 P01
                }
                return LayoutBuilder(
                  // 적응형: 기기 종류가 아니라 "이 영역의 너비"로 나눈다
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= wideBreakpoint) {
                      return GridView.builder(
                        // T-4 넓은 화면: 카드 격자
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 380,
                              mainAxisExtent: 168,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, i) => TournamentCard(
                          items[i],
                          margin: EdgeInsets.zero,
                          onTap: () => _open(items[i]),
                        ),
                      );
                    }
                    return ListView.builder(
                      // T-3 폰: 카드 목록
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: items.length,
                      itemBuilder: (context, i) => TournamentCard(
                        items[i],
                        onTap: () => _open(items[i]),
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

/// 대회 카드 한 장 — 상태 · 마감 안내를 맨 위에, 이름을 가장 크게
class TournamentCard extends StatelessWidget {
  const TournamentCard(
    this.tournament, {
    super.key,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  final Tournament tournament;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  StatusBadge(t.status), // T-5 P01
                  const SizedBox(width: 8),
                  Text(
                    t.dDay,
                    style: text.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ), // T-5 P01
                  const Spacer(),
                  Text(t.game, style: text.labelMedium),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                t.name,
                style: text.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              _IconLine(Icons.event, '${t.startDate} ~ ${t.endDate}'),
              const SizedBox(height: 2),
              _IconLine(Icons.place_outlined, t.venue),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
