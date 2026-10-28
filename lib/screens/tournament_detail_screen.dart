// 화면 D: 대회 상세 — 대회 정보 · 대진표 · 결과를 한 화면의 탭으로
//
// ┌──────── 디자인 가이드 대응표: D 대회 상세 ──────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)    │
// │ D-1  │ AppBar + BackButton               │ 대회 상세 제목줄      │ P03 통제·자유  │
// │ D-2  │ TabBar + TabBarView (3탭)         │ 정보 | 대진표 | 결과  │ P06 재인       │
// │ D-3  │ ListTile × 6                      │ 대회 개요             │ P02 실세계     │
// │ D-4  │ Wrap(Chip …)                      │ 참가 부문 칩          │ P08 미니멀     │
// │ D-5  │ FilledButton → 모달 시트          │ 참가 신청 버튼        │ P05 오류 예방  │
// │ D-6  │ FutureBuilder(GET /brackets)      │ 라운드별 대진표       │ P01 가시성     │
// │ D-7  │ Card + DemoNotice                 │ AI 경기 요약 카드     │ P10 도움말     │
// │ D-8  │ FutureBuilder(GET /results)       │ 최종 순위표           │ P01 · P09      │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환: T → D 쌓기(push) · D 안에서 옆으로(tab) · D → E 덮기(modal)
// 처음 열리는 탭: 접수중 → 정보 · 진행중 → 대진표 · 종료 → 결과 (D-2 P07 — 상태에 맞는 탭을 먼저)
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'entry_sheet.dart';

class TournamentDetailScreen extends StatelessWidget {
  const TournamentDetailScreen({
    super.key,
    required this.tournament,
    this.loadBrackets = fetchBrackets,
    this.loadResults = fetchResults,
  });

  final Tournament tournament;
  final LoaderById<BracketMatch> loadBrackets;
  final LoaderById<Standing> loadResults;

  @override
  Widget build(BuildContext context) {
    // 옆으로(tab): DefaultTabController가 탭 선택을 화면 안에서만 처리한다 (허용)
    return DefaultTabController(
      length: 3,
      initialIndex: switch (tournament.status) {
        '진행중' => 1,
        '종료' => 2,
        _ => 0,
      }, // D-2 P07
      child: Scaffold(
        appBar: AppBar(
          title: Text(tournament.name), // D-1 P03 (뒤로 버튼 자동)
          bottom: const TabBar(
            // D-2 P06
            tabs: [
              Tab(text: '정보'),
              Tab(text: '대진표'),
              Tab(text: '결과'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _InfoTab(tournament: tournament),
            _BracketTab(tournament: tournament, load: loadBrackets),
            _ResultTab(tournament: tournament, load: loadResults),
          ],
        ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final open = t.status == '접수중';
    final rows = [
      (Icons.event, '일정', '${t.startDate} ~ ${t.endDate}'),
      (Icons.place_outlined, '장소', t.venue),
      (Icons.sports_baseball_outlined, '종목', t.game),
      (Icons.rule, '경기 방식', t.raceTo),
      (Icons.payments_outlined, '참가비', t.entryFee),
      (Icons.emoji_events_outlined, '상금', t.prize),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            StatusBadge(t.status),
            const SizedBox(width: 8),
            Text(t.dDay, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        for (final (icon, label, value) in rows)
          if (value.isNotEmpty)
            ListTile(
              // D-3 P02: 협회 요강과 같은 용어(참가비 · 경기 방식 · 상금)
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(icon),
              title: Text(label),
              subtitle: Text(value),
            ),
        if (t.divisions.isNotEmpty) ...[
          const SectionTitle('참가 부문'),
          Wrap(
            // D-4 P08
            spacing: 6,
            runSpacing: 6,
            children: [for (final d in t.divisions) Chip(label: Text(d))],
          ),
        ],
        const SizedBox(height: 24),
        // D-5 P05: 접수 중이 아니면 버튼을 끄고 이유를 같이 보여 준다 (누른 뒤 실패하지 않게)
        FilledButton.icon(
          onPressed: open ? () => EntrySheet.show(context, t) : null,
          icon: const Icon(Icons.how_to_reg),
          label: const Text('참가 신청'),
        ), // D-5 P05
        if (!open) ...[
          const SizedBox(height: 6),
          DemoNotice('접수 기간이 아닙니다 (${t.status}).'),
        ],
      ],
    );
  }
}

/// '대진표' 탭 — GET /brackets?tournamentId=
class _BracketTab extends StatefulWidget {
  const _BracketTab({required this.tournament, required this.load});

  final Tournament tournament;
  final LoaderById<BracketMatch> load;

  @override
  State<_BracketTab> createState() => _BracketTabState();
}

class _BracketTabState extends State<_BracketTab> {
  late Future<List<BracketMatch>> _future = widget.load(widget.tournament.id);

  // STATE: 응원 선수(즐겨찾기) → D-6 해당 경기 강조 · 경기 시작 알림 — v2 이후 상태관리로 구현 (지금은 표시만)

  void _retry() {
    setState(() {
      _future = widget.load(widget.tournament.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AsyncListView<BracketMatch>(
      // D-6 P01 · P09
      future: _future,
      onRetry: _retry,
      loadingLabel: '대진표를 불러오는 중…',
      errorTitle: '대진표를 불러오지 못했습니다.',
      emptyMessage: widget.tournament.status == '접수중'
          ? '대진표는 접수 마감 후 공개됩니다.'
          : '등록된 대진표가 없습니다.',
      builder: (context, matches) {
        // db.json 순서 그대로 라운드 제목만 끼워 넣는다 (정렬·계산 없음)
        final children = <Widget>[];
        String? round;
        for (final m in matches) {
          if (m.round != round) {
            round = m.round;
            children.add(SectionTitle(m.round));
          }
          children.add(_BracketTile(m));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        );
      },
    );
  }
}

/// 대진표 한 경기: 테이블 · 시간 · 상태를 위에, 두 선수와 점수를 아래에
class _BracketTile extends StatelessWidget {
  const _BracketTile(this.match);

  final BracketMatch match;

  @override
  Widget build(BuildContext context) {
    final m = match;
    final text = Theme.of(context).textTheme;
    Widget line(String name, int? score, bool winner) => Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: text.bodyLarge?.copyWith(
              fontWeight: winner ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
        Text(score?.toString() ?? '-', style: text.titleMedium),
      ],
    );
    // 이긴 쪽 굵게: 종료된 경기에서 db.json 점수가 더 큰 쪽 (비교만 — 계산 아님)
    final done = m.status == '종료' && m.scoreA != null && m.scoreB != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('${m.table} · ${m.time}', style: text.labelMedium),
                const Spacer(),
                StatusBadge(m.status), // D-6 P01
              ],
            ),
            const SizedBox(height: 8),
            line(m.playerA, m.scoreA, done && m.scoreA! > m.scoreB!),
            const SizedBox(height: 4),
            line(m.playerB, m.scoreB, done && m.scoreB! > m.scoreA!),
          ],
        ),
      ),
    );
  }
}

/// '결과' 탭 — AI 경기 요약(미리 작성) + GET /results?tournamentId=
class _ResultTab extends StatefulWidget {
  const _ResultTab({required this.tournament, required this.load});

  final Tournament tournament;
  final LoaderById<Standing> load;

  @override
  State<_ResultTab> createState() => _ResultTabState();
}

class _ResultTabState extends State<_ResultTab> {
  late Future<List<Standing>> _future = widget.load(widget.tournament.id);

  void _retry() {
    setState(() {
      _future = widget.load(widget.tournament.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.tournament.aiSummary;
    return AsyncListView<Standing>(
      // D-8 P01 · P09
      future: _future,
      onRetry: _retry,
      loadingLabel: '결과를 불러오는 중…',
      errorTitle: '결과를 불러오지 못했습니다.',
      emptyMessage: '대회가 끝나면 최종 순위가 표시됩니다.',
      builder: (context, standings) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          if (summary.isNotEmpty)
            Card(
              // D-7 P10: AI 경기 요약 — 미리 작성한 문장, 실제 AI 호출 없음
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 20),
                        SizedBox(width: 6),
                        Text('AI 경기 요약'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(summary),
                  ],
                ),
              ),
            ), // D-7 P10
          const SectionTitle('최종 순위', icon: Icons.format_list_numbered),
          for (final s in standings)
            ListTile(
              // D-8
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text('${s.place}')),
              title: Text(s.playerName),
              subtitle: Text(s.club),
              trailing: Text('+${s.points}P'),
            ),
        ],
      ),
    );
  }
}
