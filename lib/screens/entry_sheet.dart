// 화면 E: 참가 신청(예시) — 덮기(modal)
//
// ┌──────── 디자인 가이드 대응표: E 참가 신청(예시) ────────────────────────────┐
// │ 번호 │ Flutter 위젯명                   │ 비즈니스 명칭(한글)   │ 원칙(P번호)   │
// │ E-1  │ showModalBottomSheet + 손잡이    │ 참가 신청 시트        │ P03 통제·자유 │
// │ E-2  │ ChoiceChip × 부문 수             │ 참가 부문 선택        │ P06 재인      │
// │ E-3  │ ListTile                         │ 참가비 안내           │ P01 가시성    │
// │ E-4  │ CheckboxListTile × 2             │ 신청 전 확인 사항     │ P05 오류 예방 │
// │ E-5  │ FilledButton (조건 충족 시 활성)  │ 신청하기 버튼         │ P05 오류 예방 │
// │ E-6  │ showDialog(AlertDialog)          │ 신청 완료 안내(예시)  │ P01 · P10     │
// │ E-7  │ FutureBuilder(GET /members) +    │ 스카치 더블 파트너    │ P06 재인      │
// │      │ ListTile(선택 표시) × n          │ 선택(내 동호회 회원)  │ P01 · P09     │
// └────────────────────────────────────────────────────────────────────────────┘
// E-7은 스카치 더블 대회(tournament.isScotchDoubles)에서만 보인다.
//
// ⚠ 실제 신청·결제·로그인 없음 (안내 5장: 감점). 서버로 아무것도 보내지 않는다.
//   "신청하기"는 시트를 닫고 미리 정한 완료 안내(E-6)만 보여 준다. 개인정보 입력 칸도 없다.
//   파트너에게 초대·알림을 보내지 않는다 — 고른 이름을 완료 안내에 보여 줄 뿐이다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

const _checks = ['대회 요강(경기 방식 · 복장 규정)을 확인했습니다.', '참가비는 현장에서 납부합니다.'];

class EntrySheet extends StatefulWidget {
  const EntrySheet({
    super.key,
    required this.tournament,
    this.loadPartners = fetchPartnerCandidates,
  });

  final Tournament tournament;

  /// 스카치 더블 파트너 후보(내 동호회 회원, 본인 제외) — 테스트는 가짜 함수를 넣는다.
  final Loader<ClubMember> loadPartners;

  /// 덮기(modal): 지금 화면 위에 잠깐 띄우고 닫는다.
  static Future<void> show(
    BuildContext context,
    Tournament t, {
    Loader<ClubMember> loadPartners = fetchPartnerCandidates,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true, // E-1 P03
      isScrollControlled: true,
      builder: (_) => EntrySheet(tournament: t, loadPartners: loadPartners),
    );
  }

  @override
  State<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<EntrySheet> {
  // 시트 안 선택 = 화면 안 표시 변화 → setState (허용). 시트를 닫으면 사라진다(저장 없음).
  // STATE: 선택한 부문 · 파트너 · 신청 여부 → D-5 버튼 문구("신청 완료") — v2 이후 상태관리로 구현 (지금은 표시만)
  String? _division;
  ClubMember? _partner;
  final _checked = List<bool>.filled(_checks.length, false);

  // 스카치 더블이 아니면 파트너 목록을 부르지 않는다
  late Future<List<ClubMember>>? _partnersFuture =
      widget.tournament.isScotchDoubles ? widget.loadPartners() : null;

  bool get _needsPartner => widget.tournament.isScotchDoubles;

  bool get _ready =>
      _division != null &&
      (!_needsPartner || _partner != null) &&
      !_checked.contains(false);

  void _retryPartners() {
    setState(() {
      _partnersFuture = widget.loadPartners();
    });
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    final division = _division;
    final team = _partner == null ? '' : '\n팀: 나 (예시 사용자) + ${_partner!.name}';
    navigator.pop();
    await showDialog<void>(
      context: navigator.context,
      builder: (context) => AlertDialog(
        // E-6 P01 P10
        icon: const Icon(Icons.check_circle_outline),
        title: const Text('신청 접수 완료 (예시)'),
        content: Text(
          '${widget.tournament.name}\n$division 부문$team\n\n'
          '※ 예시 화면입니다. 실제로 신청되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('참가 신청', style: text.titleLarge),
            const SizedBox(height: 4),
            Text(t.name, style: text.bodyMedium),
            if (_needsPartner) ...[
              const SizedBox(height: 8),
              const ScotchDoublesBadge(),
            ],
            const SectionTitle('참가 부문'),
            Wrap(
              // E-2 P06: 부문 이름을 직접 고른다 (기억해서 입력하지 않게)
              spacing: 8,
              children: [
                for (final d in t.divisions)
                  ChoiceChip(
                    label: Text(d),
                    selected: _division == d,
                    onSelected: (_) => setState(() {
                      _division = d;
                    }),
                  ),
              ],
            ),
            if (_partnersFuture case final partners?) ...[
              const SectionTitle(
                '파트너 선택 (내 동호회 회원)',
                icon: Icons.group_add_outlined,
              ),
              AsyncListView<ClubMember>(
                // E-7 P01 · P09
                future: partners,
                onRetry: _retryPartners,
                loadingLabel: '동호회 회원을 불러오는 중…',
                errorTitle: '동호회 회원을 불러오지 못했습니다.',
                emptyMessage: '함께 신청할 동호회 회원이 없습니다.',
                builder: (context, members) => Column(
                  children: [
                    for (final m in members)
                      ListTile(
                        // E-7 P06: 이름을 입력하지 않고 회원 목록에서 고른다
                        contentPadding: EdgeInsets.zero,
                        selected: _partner?.id == m.id,
                        leading: CircleAvatar(
                          child: Text(m.name.characters.first),
                        ),
                        title: Text(m.name),
                        subtitle: Text('${m.role} · ${m.level}'),
                        trailing: Icon(
                          _partner?.id == m.id
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                        ),
                        onTap: () => setState(() {
                          _partner = m;
                        }),
                      ),
                  ],
                ),
              ),
            ],
            ListTile(
              // E-3 P01
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.payments_outlined),
              title: const Text('참가비'),
              subtitle: Text(t.entryFee),
            ),
            for (final (i, c) in _checks.indexed)
              CheckboxListTile(
                // E-4 P05
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _checked[i],
                onChanged: (v) => setState(() {
                  _checked[i] = v ?? false;
                }),
                title: Text(c),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // E-5 P05: 부문 (+ 스카치 더블 파트너) 선택 + 확인 사항 체크 전에는 눌리지 않는다
                onPressed: _ready ? _submit : null,
                child: Text(
                  _needsPartner && _partner != null
                      ? '${_partner!.name}님과 신청하기'
                      : '신청하기',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const DemoNotice('※ 예시 화면입니다. 로그인·결제 없이 신청 흐름만 보여 줍니다.'), // P10
          ],
        ),
      ),
    );
  }
}
