// 3상태(로딩·오류·빈) + 화면 흐름(push · tab · modal) + 적응형(600dp · 840dp) 위젯 테스트.
// 네트워크를 쓰지 않도록 화면에 가짜 loader를 넣는다 → json-server 없이 `flutter test`가 돈다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mid_project_template/main.dart';
import 'package:mid_project_template/models.dart';
import 'package:mid_project_template/screens/club_screen.dart';
import 'package:mid_project_template/screens/tournaments_screen.dart';

const _open = Tournament(
  id: 1,
  name: '테스트 9볼 오픈',
  status: '접수중',
  dDay: '접수 마감 D-5',
  startDate: '2026-11-14',
  endDate: '2026-11-16',
  venue: '테스트 아레나',
  region: '서울',
  game: '9볼',
  divisions: ['남자 오픈', '아마추어'],
  entryFee: '50,000원',
);

const _live = Tournament(
  id: 2,
  name: '테스트 10볼 챔피언십',
  status: '진행중',
  dDay: '오늘 8강 진행',
  startDate: '2026-10-28',
  endDate: '2026-10-30',
  venue: '테스트 센터',
  region: '부산',
  game: '10볼',
);

const _doubles = Tournament(
  id: 5,
  name: '테스트 스카치 더블',
  status: '접수중',
  dDay: '접수 마감 D-9',
  startDate: '2026-11-22',
  endDate: '2026-11-22',
  venue: '테스트 큐스테이션',
  region: '서울',
  game: '9볼',
  divisions: ['오픈 페어'],
  entryFee: '팀당 40,000원',
  format: '스카치 더블',
);

const _members = [
  ClubMember(
    id: 2,
    clubId: 1,
    name: '회원 가',
    role: '회장',
    level: 'A급',
    joined: '2019-05',
  ),
  ClubMember(
    id: 3,
    clubId: 1,
    name: '회원 나',
    role: '회원',
    level: 'B급',
    joined: '2024-01',
  ),
];

const _club = Club(
  id: 1,
  name: '테스트 큐클럽',
  region: '서울',
  meeting: '매주 수 19:00',
  place: '테스트 아레나',
  founded: '2019',
  intro: '테스트 동호회',
);

const _bracket = [
  BracketMatch(
    id: 1,
    round: '8강',
    table: '1번 테이블',
    time: '14:00',
    playerA: '선수 가',
    playerB: '선수 나',
    status: '종료',
    scoreA: 9,
    scoreB: 6,
  ),
];

Future<List<BracketMatch>> _brackets(int _) async => _bracket;
Future<List<Standing>> _noResults(int _) async => const [];
Future<List<ClubMember>> _partners() async => _members;

Widget _app(Future<List<Tournament>> Function() load) => MaterialApp(
  home: TournamentsScreen(
    load: load,
    loadBrackets: _brackets,
    loadResults: _noResults,
    loadPartners: _partners,
  ),
);

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('3상태: 로딩 → 오류 → 다시 시도 → 성공', (tester) async {
    _setSize(tester, const Size(400, 800));

    final first = Completer<List<Tournament>>();
    var calls = 0;
    await tester.pumpWidget(
      _app(() => ++calls == 1 ? first.future : Future.value([_open, _live])),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('대회 일정을 불러오는 중…'), findsOneWidget);

    first.completeError(Exception('테스트 오류'));
    await tester.pumpAndSettle();
    expect(find.text('대회 일정을 불러오지 못했습니다.'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('테스트 9볼 오픈'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('3상태: 빈 상태', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(() async => const []));
    await tester.pumpAndSettle();
    expect(find.text('아직 등록된 대회가 없습니다.'), findsOneWidget);
  });

  testWidgets('필터: 고른 상태의 대회가 없으면 안내', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(() async => [_open]));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '종료'));
    await tester.pumpAndSettle();
    expect(find.text("'종료' 대회가 없습니다."), findsOneWidget);
  });

  testWidgets('흐름: 진행중 대회 → push 상세(대진표 탭부터)', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(() async => [_open, _live]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('테스트 10볼 챔피언십'));
    await tester.pumpAndSettle();
    expect(find.text('선수 가'), findsOneWidget); // 진행중 → 대진표 탭이 먼저
    expect(find.text('8강'), findsOneWidget);

    await tester.tap(find.text('결과'));
    await tester.pumpAndSettle();
    expect(find.text('대회가 끝나면 최종 순위가 표시됩니다.'), findsOneWidget);
  });

  testWidgets('흐름: 접수중 대회 → modal 참가 신청 → 예시 완료 안내', (tester) async {
    _setSize(tester, const Size(400, 900));
    await tester.pumpWidget(_app(() async => [_open]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('테스트 9볼 오픈'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '참가 신청'));
    await tester.pumpAndSettle();

    // 부문·확인 사항 전에는 신청하기가 꺼져 있다 (P05)
    final submit = find.widgetWithText(FilledButton, '신청하기');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.widgetWithText(ChoiceChip, '아마추어'));
    for (final box in find.byType(Checkbox).evaluate().toList()) {
      await tester.tap(find.byWidget(box.widget));
    }
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('신청 접수 완료 (예시)'), findsOneWidget);
  });

  testWidgets('적응형: 600dp 이상 격자 · 840dp 이상 측면 메뉴', (tester) async {
    _setSize(tester, const Size(1000, 800));
    await tester.pumpWidget(_app(() async => [_open, _live]));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);

    await tester.pumpWidget(const KpaNowApp());
    await tester.pump();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('KPA NOW'), findsOneWidget); // S-6 브랜드 바
  });

  testWidgets('스카치 더블: 배지 → 파트너를 골라야 신청 가능 → 팀 완료 안내', (tester) async {
    _setSize(tester, const Size(400, 1400));
    await tester.pumpWidget(_app(() async => [_doubles]));
    await tester.pumpAndSettle();
    expect(find.text('스카치 더블 · 2인 1팀'), findsOneWidget); // T-9

    await tester.tap(find.text('테스트 스카치 더블'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '참가 신청'));
    await tester.pumpAndSettle();
    expect(find.text('회원 가'), findsOneWidget); // E-7 GET 결과

    await tester.tap(find.widgetWithText(ChoiceChip, '오픈 페어'));
    for (final box in find.byType(Checkbox).evaluate().toList()) {
      await tester.tap(find.byWidget(box.widget));
    }
    await tester.pumpAndSettle();
    final submit = find.byType(FilledButton).last;
    expect(tester.widget<FilledButton>(submit).onPressed, isNull); // 파트너 없음

    await tester.tap(find.text('회원 나'));
    await tester.pumpAndSettle();
    expect(find.text('회원 나님과 신청하기'), findsOneWidget);
    await tester.tap(find.text('회원 나님과 신청하기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('팀: 나 (예시 사용자) + 회원 나'), findsOneWidget);
  });

  testWidgets('동호회: 정보 + 회원 목록 · 회원 빈 상태', (tester) async {
    _setSize(tester, const Size(400, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: ClubScreen(
          load: () async => [_club],
          loadMembers: (_) async => _members,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('테스트 큐클럽'), findsOneWidget);
    expect(find.text('회원 2명'), findsOneWidget);
    expect(find.text('회장'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: ClubScreen(
          key: UniqueKey(),
          load: () async => [_club],
          loadMembers: (_) async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('아직 회원이 없습니다.'), findsOneWidget);
  });
}
