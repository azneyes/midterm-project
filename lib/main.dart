// KPA NOW v2 — GAI3008 중간고사 (UI만 구현)
//
// ┌──────── 디자인 가이드 대응표: 앱 뼈대 ──────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명               │ 비즈니스 명칭(한글)  │ 원칙(P번호)        │
// │ S-1  │ MaterialApp                  │ KPA NOW              │ —                  │
// │ S-2  │ ThemeData(seedColor 그린)    │ 당구대 그린 브랜드 색│ P04 일관성         │
// │ S-3  │ NavigationBar (<840dp)       │ 하단 메뉴 5개        │ P06 재인 · P04     │
// │ S-4  │ NavigationRail (≥840dp)      │ 측면 메뉴 5개        │ 적응형 · P06       │
// │ S-5  │ IndexedStack                 │ 메뉴별 화면 유지     │ P03 통제·자유      │
// │ S-6  │ AppBar(primary) + PoolBall×3 │ KPA NOW 브랜드 바    │ P04 일관성         │
// └────────────────────────────────────────────────────────────────────────────┘
// 화면 흐름(docs/디자인가이드.md 1장과 같게):
//   [옆으로(tab)] 대회 · 랭킹 · 동호회 · 소식 · AI 코치
//   T 대회 일정 ──쌓기(push)──▶ D 대회 상세 [옆으로(tab): 정보 | 대진표 | 결과] ──덮기(modal)──▶ E 참가 신청(예시)
//   R 선수 랭킹 ──쌓기(push)──▶ P 선수 프로필 ──덮기(modal)──▶ A AI 경기력 분석 카드
//   K 내 동호회 (동호회 정보 + 회원 목록)
//   N 협회 소식 (화면 안 펼치기 — setState)
//   C AI 코치  ──쌓기(push)──▶ V 영상 분석 결과
// 기획 문서에 없는 화면은 만들지 않는다(감점). 화면을 늘리면 이 주석·가이드도 같이 고친다.
import 'package:flutter/material.dart';

import 'screens/club_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/news_screen.dart';
import 'screens/rankings_screen.dart';
import 'screens/tournaments_screen.dart';
import 'widgets.dart';

void main() => runApp(const KpaNowApp());

/// 이 너비 이상이면 측면 메뉴(NavigationRail) — Material 3 window size class: expanded ≥ 840dp
const railBreakpoint = 840.0;

class KpaNowApp extends StatelessWidget {
  const KpaNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KPA NOW', // S-1
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0B6E4F),
      ), // S-2 P04 당구대 그린
      home: const KpaShell(),
    );
  }
}

/// 메뉴 5개 — 순서·아이콘·이름은 디자인 가이드 S-3 표와 같다
const _destinations = [
  (
    icon: Icons.emoji_events_outlined,
    selected: Icons.emoji_events,
    label: '대회',
  ),
  (icon: Icons.leaderboard_outlined, selected: Icons.leaderboard, label: '랭킹'),
  (icon: Icons.groups_outlined, selected: Icons.groups, label: '동호회'),
  (icon: Icons.campaign_outlined, selected: Icons.campaign, label: '소식'),
  (
    icon: Icons.smart_display_outlined,
    selected: Icons.smart_display,
    label: 'AI 코치',
  ),
];

class KpaShell extends StatefulWidget {
  const KpaShell({super.key});

  @override
  State<KpaShell> createState() => _KpaShellState();
}

class _KpaShellState extends State<KpaShell> {
  // 메뉴 선택 = 화면 안 표시 변화 → setState (허용)
  int _index = 0;

  static const _pages = [
    TournamentsScreen(),
    RankingsScreen(),
    ClubScreen(),
    NewsScreen(),
    CoachScreen(),
  ];

  void _select(int i) {
    setState(() {
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    // S-5 P03: IndexedStack이라 메뉴를 바꿔도 보던 목록 위치가 남는다
    final body = IndexedStack(index: _index, children: _pages);
    return LayoutBuilder(
      // 적응형: 기기 종류가 아니라 창 너비로 나눈다
      builder: (context, constraints) {
        if (constraints.maxWidth >= railBreakpoint) {
          return Scaffold(
            appBar: const BrandBar(), // S-6 P04
            body: Row(
              children: [
                NavigationRail(
                  // S-4 넓은 화면: 측면 메뉴
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: const BrandBar(), // S-6 P04
          body: body,
          bottomNavigationBar: NavigationBar(
            // S-3 P06 폰: 하단 메뉴 (아이콘 + 글자)
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// S-6 브랜드 바: 모든 메뉴 화면 맨 위에 앱 이름을 같은 모양으로 보여 준다 (P04 일관성)
/// 메뉴 화면 각자의 제목줄(T-1 · R-1 …)은 이 바 아래에 그대로 남는다.
/// 쌓기(push)로 들어간 상세 화면은 전체 화면이라 이 바를 덮는다 — 상세는 뒤로 버튼 + 제목이 우선.
class BrandBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      toolbarHeight: 48,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      centerTitle: true, // 로고를 가운데에
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 8볼 · 9볼 · 10볼 — KPA가 여는 세 종목. 이미지 파일 없이 위젯으로 그린다
          PoolBall(number: 8, color: Colors.black),
          SizedBox(width: 4),
          PoolBall(number: 9, color: Color(0xFFF7C600), striped: true),
          SizedBox(width: 4),
          PoolBall(number: 10, color: Color(0xFF1E4FBF), striped: true),
          SizedBox(width: 10),
          Text(
            'KPA NOW',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }
}
