// 화면 K: 내 동호회 — 동호회 정보 (GET /clubs?mine=true) + 회원 목록 (GET /members?clubId=)
//
// ┌──────── 디자인 가이드 대응표: K 내 동호회 ──────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)   │
// │ K-1  │ AppBar                            │ 내 동호회 제목줄      │ P04 일관성    │
// │ K-2  │ Card(Text · _IconLine × 3)        │ 동호회 정보 카드      │ P08 미니멀    │
// │ K-3  │ SectionTitle("회원 n명")          │ 회원 수               │ P01 가시성    │
// │ K-4  │ ListView + Card (MemberTile)      │ 회원 목록             │ P06 재인      │
// │ K-5  │ StatusBadge(role) · Text(level)   │ 직책 배지 · 실력 등급 │ P02 실세계    │
// │ K-6  │ LayoutBuilder (≥600dp 2단)        │ 정보 | 회원 나란히    │ 적응형        │
// │ K-7  │ LoadingView · ErrorView · EmptyView│ 3상태 (정보 · 회원)  │ P01 · P09     │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환 없음 (옆으로(tab) '동호회' 메뉴로 들어옴). 회원은 모두 가상 인물.
// ⚠ 로그인 없음 (안내 5장: 감점). "내 동호회"는 db.json에서 mine: true로 고정한 예시 사용자의 동호회다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({
    super.key,
    this.load = fetchMyClubs,
    this.loadMembers = fetchClubMembers,
  });

  final Loader<Club> load;
  final LoaderById<ClubMember> loadMembers;

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  late Future<List<Club>> _future = widget.load();

  // STATE: 동호회 가입 · 탈퇴, 다른 동호회 둘러보기 → K-2 카드 버튼 — v2 이후 상태관리로 구현 (지금은 표시만)

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 동호회')), // K-1 P04
      body: AsyncListView<Club>(
        // K-7 P01 · P09 (동호회 정보)
        future: _future,
        onRetry: _retry,
        loadingLabel: '동호회 정보를 불러오는 중…',
        errorTitle: '동호회 정보를 불러오지 못했습니다.',
        emptyMessage: '아직 가입한 동호회가 없습니다.',
        builder: (context, clubs) {
          final club = clubs.first;
          final info = _ClubCard(club: club); // K-2 P08
          final members = _MemberList(
            clubId: club.id,
            load: widget.loadMembers,
          );
          return LayoutBuilder(
            // K-6 적응형: 넓으면 정보 | 회원 2단
            builder: (context, constraints) {
              if (constraints.maxWidth >= wideBreakpoint) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: info,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: members,
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [info, members],
              );
            },
          );
        },
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    final c = club;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(Icons.groups)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: text.titleLarge),
                      Text(
                        '${c.region} · ${c.founded}년 창단',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(c.intro),
            const SizedBox(height: 12),
            _IconLine(Icons.schedule, '정기 모임 ${c.meeting}'),
            const SizedBox(height: 4),
            _IconLine(Icons.place_outlined, c.place),
          ],
        ),
      ),
    );
  }
}

/// 회원 목록 — GET /members?clubId=
class _MemberList extends StatefulWidget {
  const _MemberList({required this.clubId, required this.load});

  final int clubId;
  final LoaderById<ClubMember> load;

  @override
  State<_MemberList> createState() => _MemberListState();
}

class _MemberListState extends State<_MemberList> {
  late Future<List<ClubMember>> _future = widget.load(widget.clubId);

  void _retry() {
    setState(() {
      _future = widget.load(widget.clubId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AsyncListView<ClubMember>(
      // K-7 P01 · P09 (회원)
      future: _future,
      onRetry: _retry,
      loadingLabel: '회원 목록을 불러오는 중…',
      errorTitle: '회원 목록을 불러오지 못했습니다.',
      emptyMessage: '아직 회원이 없습니다.',
      builder: (context, members) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            '회원 ${members.length}명',
            icon: Icons.people_outline,
          ), // K-3 P01
          for (final m in members) MemberTile(m), // K-4 P06
        ],
      ),
    );
  }
}

/// 회원 한 줄 — 이름 · 직책 배지 · 실력 등급 · 가입 시기. 본인은 강조.
class MemberTile extends StatelessWidget {
  const MemberTile(this.member, {super.key});

  final ClubMember member;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: m.me ? scheme.primaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(child: Text(m.name.characters.first)),
        title: Row(
          children: [
            Flexible(child: Text(m.name, overflow: TextOverflow.ellipsis)),
            if (m.role != '회원') ...[
              const SizedBox(width: 6),
              StatusBadge(m.role), // K-5 P02
            ],
          ],
        ),
        subtitle: Text('${m.level} · ${m.joined} 가입'), // K-5 P02
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
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
