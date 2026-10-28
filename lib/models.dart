// 데이터 모양 — db.json의 한 항목을 화면이 쓰기 좋은 객체로 바꾼다.
// 형식이 틀린 항목은 null을 돌려준다 → 목록에서 빠질 뿐 앱이 멈추지 않는다 (Dart 3 패턴 매칭).
// 필드 이름은 db.json의 키와 같다. 계산하지 않는다 — 순위·승률·D-day 문구도 db.json에 적힌 값을 그대로 보여 준다.

/// 있어도 되고 없어도 되는 문자열 목록: 모양이 다르면 빈 목록
List<String> _strings(Object? v) => switch (v) {
  List<Object?> l => l.whereType<String>().toList(),
  _ => const [],
};

/// 대회 (T 대회 일정 · D 대회 상세)
class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.status,
    required this.dDay,
    required this.startDate,
    required this.endDate,
    required this.venue,
    required this.region,
    required this.game,
    this.divisions = const [],
    this.entryFee = '',
    this.prize = '',
    this.raceTo = '',
    this.aiSummary = '',
    this.format = '개인전',
  });

  final int id;
  final String name;

  /// 접수중 · 진행중 · 종료
  final String status;
  final String dDay;
  final String startDate;
  final String endDate;
  final String venue;
  final String region;

  /// 8볼 · 9볼 · 10볼
  final String game;
  final List<String> divisions;
  final String entryFee;
  final String prize;
  final String raceTo;

  /// AI 경기 요약 — 미리 작성한 문장 (비어 있으면 요약 카드를 숨긴다)
  final String aiSummary;

  /// 개인전 · 스카치 더블 (db.json에 없으면 개인전)
  final String format;

  /// 스카치 더블: 두 선수가 한 팀으로 번갈아 한 번씩 샷 — 신청할 때 파트너를 고른다
  bool get isScotchDoubles => format == '스카치 더블';

  static Tournament? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'name': String name,
        'status': String status,
        'dDay': String dDay,
        'startDate': String startDate,
        'endDate': String endDate,
        'venue': String venue,
        'region': String region,
        'game': String game,
      } =>
        Tournament(
          id: id,
          name: name,
          status: status,
          dDay: dDay,
          startDate: startDate,
          endDate: endDate,
          venue: venue,
          region: region,
          game: game,
          divisions: _strings(json['divisions']),
          entryFee: json['entryFee'] as String? ?? '',
          prize: json['prize'] as String? ?? '',
          raceTo: json['raceTo'] as String? ?? '',
          aiSummary: json['aiSummary'] as String? ?? '',
          format: json['format'] as String? ?? '개인전',
        ),
      _ => null,
    };
  }
}

/// 대진표 한 경기 (D 대회 상세 '대진표' 탭)
class BracketMatch {
  const BracketMatch({
    required this.id,
    required this.round,
    required this.table,
    required this.time,
    required this.playerA,
    required this.playerB,
    required this.status,
    this.scoreA,
    this.scoreB,
  });

  final int id;
  final String round;
  final String table;
  final String time;
  final String playerA;
  final String playerB;

  /// 예정 · 진행중 · 종료
  final String status;

  /// 예정 경기는 점수가 없다(null)
  final int? scoreA;
  final int? scoreB;

  static BracketMatch? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'round': String round,
        'table': String table,
        'time': String time,
        'playerA': String playerA,
        'playerB': String playerB,
        'status': String status,
      } =>
        BracketMatch(
          id: id,
          round: round,
          table: table,
          time: time,
          playerA: playerA,
          playerB: playerB,
          status: status,
          scoreA: json['scoreA'] as int?,
          scoreB: json['scoreB'] as int?,
        ),
      _ => null,
    };
  }
}

/// 최종 순위 한 줄 (D 대회 상세 '결과' 탭)
class Standing {
  const Standing({
    required this.id,
    required this.place,
    required this.playerName,
    required this.club,
    required this.points,
  });

  final int id;
  final int place;
  final String playerName;
  final String club;
  final int points;

  static Standing? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'place': int place,
        'playerName': String playerName,
        'club': String club,
        'points': int points,
      } =>
        Standing(
          id: id,
          place: place,
          playerName: playerName,
          club: club,
          points: points,
        ),
      _ => null,
    };
  }
}

/// AI 경기력 분석 카드 내용 — 미리 작성한 값 (A 분석 카드 시트)
class PlayerAnalysis {
  const PlayerAnalysis({
    this.summary = '',
    this.strengths = const [],
    this.weaknesses = const [],
    this.tip = '',
  });

  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final String tip;

  static PlayerAnalysis fromJson(Object? json) {
    return switch (json) {
      Map<String, Object?> m => PlayerAnalysis(
        summary: m['summary'] as String? ?? '',
        strengths: _strings(m['strengths']),
        weaknesses: _strings(m['weaknesses']),
        tip: m['tip'] as String? ?? '',
      ),
      _ => const PlayerAnalysis(),
    };
  }
}

/// 선수 (R 선수 랭킹 · P 선수 프로필) — 모든 선수는 가상 인물
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.division,
    required this.club,
    required this.region,
    required this.rank,
    required this.points,
    required this.rankChange,
    required this.wins,
    required this.losses,
    required this.winRate,
    this.stats = const {},
    this.analysis = const PlayerAnalysis(),
  });

  final int id;
  final String name;

  /// 남자 · 여자
  final String division;
  final String club;
  final String region;
  final int rank;
  final int points;

  /// ▲1 · ▼1 · −
  final String rankChange;
  final int wins;
  final int losses;
  final String winRate;

  /// 경기력 지표 0–100 (breakSuccess · safety · longShot · position) — db.json 값 그대로
  final Map<String, int> stats;
  final PlayerAnalysis analysis;

  static Player? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'name': String name,
        'division': String division,
        'club': String club,
        'region': String region,
        'rank': int rank,
        'points': int points,
        'rankChange': String rankChange,
        'wins': int wins,
        'losses': int losses,
        'winRate': String winRate,
      } =>
        Player(
          id: id,
          name: name,
          division: division,
          club: club,
          region: region,
          rank: rank,
          points: points,
          rankChange: rankChange,
          wins: wins,
          losses: losses,
          winRate: winRate,
          stats: switch (json['stats']) {
            Map<String, Object?> s => {
              for (final MapEntry(:key, :value) in s.entries)
                if (value is int) key: value,
            },
            _ => const {},
          },
          analysis: PlayerAnalysis.fromJson(json['analysis']),
        ),
      _ => null,
    };
  }
}

/// 선수 경기 기록 한 줄 (P 선수 프로필)
class MatchRecord {
  const MatchRecord({
    required this.id,
    required this.date,
    required this.tournament,
    required this.round,
    required this.opponent,
    required this.score,
    required this.result,
  });

  final int id;
  final String date;
  final String tournament;
  final String round;
  final String opponent;
  final String score;

  /// 승 · 패 · 진행중
  final String result;

  static MatchRecord? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'date': String date,
        'tournament': String tournament,
        'round': String round,
        'opponent': String opponent,
        'score': String score,
        'result': String result,
      } =>
        MatchRecord(
          id: id,
          date: date,
          tournament: tournament,
          round: round,
          opponent: opponent,
          score: score,
          result: result,
        ),
      _ => null,
    };
  }
}

/// 협회 소식 (N 소식)
class News {
  const News({
    required this.id,
    required this.category,
    required this.date,
    required this.title,
    required this.body,
  });

  final int id;
  final String category;
  final String date;
  final String title;
  final String body;

  static News? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'category': String category,
        'date': String date,
        'title': String title,
        'body': String body,
      } =>
        News(id: id, category: category, date: date, title: title, body: body),
      _ => null,
    };
  }
}

/// 영상 속 실수 장면 하나 (V 영상 분석 결과)
typedef Mistake = ({String time, String title, String cause});

/// 경기 영상 + 미리 작성한 AI 분석 결과 (C AI 코치 · V 영상 분석 결과)
class MatchVideo {
  const MatchVideo({
    required this.id,
    required this.title,
    required this.player,
    required this.date,
    required this.duration,
    required this.summary,
    this.mistakes = const [],
    this.shotSelection = '',
    this.angle = '',
    this.positioning = '',
  });

  final int id;
  final String title;
  final String player;
  final String date;
  final String duration;
  final String summary;
  final List<Mistake> mistakes;
  final String shotSelection;
  final String angle;
  final String positioning;

  static MatchVideo? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'title': String title,
        'player': String player,
        'date': String date,
        'duration': String duration,
        'summary': String summary,
      } =>
        MatchVideo(
          id: id,
          title: title,
          player: player,
          date: date,
          duration: duration,
          summary: summary,
          mistakes: switch (json['mistakes']) {
            List<Object?> l => [
              for (final m in l)
                if (m case {
                  'time': String time,
                  'title': String title,
                  'cause': String cause,
                })
                  (time: time, title: title, cause: cause),
            ],
            _ => const [],
          },
          shotSelection: json['shotSelection'] as String? ?? '',
          angle: json['angle'] as String? ?? '',
          positioning: json['positioning'] as String? ?? '',
        ),
      _ => null,
    };
  }
}

/// 동호회 (K 내 동호회) — 로그인이 없으므로 "내 동호회"는 db.json의 mine: true로 고정한 예시
class Club {
  const Club({
    required this.id,
    required this.name,
    required this.region,
    required this.meeting,
    required this.place,
    required this.founded,
    required this.intro,
  });

  final int id;
  final String name;
  final String region;

  /// 정기 모임 요일·시간
  final String meeting;
  final String place;
  final String founded;
  final String intro;

  static Club? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'name': String name,
        'region': String region,
        'meeting': String meeting,
        'place': String place,
        'founded': String founded,
        'intro': String intro,
      } =>
        Club(
          id: id,
          name: name,
          region: region,
          meeting: meeting,
          place: place,
          founded: founded,
          intro: intro,
        ),
      _ => null,
    };
  }
}

/// 동호회 회원 (K 회원 목록 · E 스카치 더블 파트너 선택) — 모두 가상 인물
class ClubMember {
  const ClubMember({
    required this.id,
    required this.clubId,
    required this.name,
    required this.role,
    required this.level,
    required this.joined,
    this.me = false,
  });

  final int id;
  final int clubId;
  final String name;

  /// 회장 · 총무 · 회원
  final String role;

  /// 실력 등급 (C급 · B급 · A급 · 선수 등록)
  final String level;
  final String joined;

  /// 예시 사용자 본인 — 파트너 목록에서는 빠진다
  final bool me;

  static ClubMember? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'clubId': int clubId,
        'name': String name,
        'role': String role,
        'level': String level,
        'joined': String joined,
      } =>
        ClubMember(
          id: id,
          clubId: clubId,
          name: name,
          role: role,
          level: level,
          joined: joined,
          me: json['me'] == true,
        ),
      _ => null,
    };
  }
}
