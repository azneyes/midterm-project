// 화면 A: AI 경기력 분석 카드 — 덮기(modal)
//
// ┌──────── 디자인 가이드 대응표: A AI 경기력 분석 카드 ────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)   │
// │ A-1  │ showModalBottomSheet + 손잡이     │ 분석 카드 시트        │ P03 통제·자유 │
// │ A-2  │ Text(bodyLarge)                   │ 한 줄 요약            │ P08 미니멀    │
// │ A-3  │ LinearProgressIndicator × 4       │ 경기력 지표 막대      │ P02 실세계    │
// │ A-4  │ ListTile(✓) × n                   │ 강점                  │ P06 재인      │
// │ A-5  │ ListTile(!) × n                   │ 약점                  │ P06 재인      │
// │ A-6  │ Card                              │ 추천 연습             │ P07 효율성    │
// │ A-7  │ DemoNotice                        │ 예시 분석 고지        │ P10 도움말    │
// └────────────────────────────────────────────────────────────────────────────┘
//
// ⚠ 실제 AI 호출·통계 계산 없음 (안내 5장: LLM API · 실제 로직은 감점).
//   막대 값과 문장은 db.json에 미리 적어 둔 값(player.stats · player.analysis)을 그대로 그린다.
import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';

/// 지표 이름 — 당구 용어 그대로 (P02)
const _statLabels = {
  'breakSuccess': '브레이크 후 첫 공',
  'safety': '세이프티',
  'longShot': '롱샷',
  'position': '포지셔닝',
};

class AnalysisSheet extends StatelessWidget {
  const AnalysisSheet({super.key, required this.player});

  final Player player;

  static Future<void> show(BuildContext context, Player p) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true, // A-1 P03
      isScrollControlled: true,
      builder: (_) => AnalysisSheet(player: p),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = player.analysis;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${player.name} · AI 경기력 분석', style: text.titleLarge),
              const SizedBox(height: 8),
              Text(a.summary, style: text.bodyLarge), // A-2 P08
              const SectionTitle('경기력 지표', icon: Icons.bar_chart),
              for (final MapEntry(:key, :value) in player.stats.entries)
                Padding(
                  // A-3 P02
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_statLabels[key] ?? key),
                          const Spacer(),
                          Text('$value', style: text.labelLarge),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: value / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              const SectionTitle('강점', icon: Icons.thumb_up_alt_outlined),
              for (final s in a.strengths)
                ListTile(
                  // A-4 P06
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle, color: scheme.primary),
                  title: Text(s),
                ),
              const SectionTitle('약점', icon: Icons.flag_outlined),
              for (final w in a.weaknesses)
                ListTile(
                  // A-5 P06
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.error_outline, color: scheme.error),
                  title: Text(w),
                ),
              if (a.tip.isNotEmpty)
                Card(
                  // A-6 P07
                  color: scheme.secondaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('추천 연습'),
                    subtitle: Text(a.tip),
                  ),
                ),
              const SizedBox(height: 8),
              const DemoNotice(
                '※ 미리 작성한 예시 분석입니다. 실제 AI 분석은 v2 이후 기능입니다.',
              ), // A-7 P10
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
