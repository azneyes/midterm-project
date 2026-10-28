// 화면 V: 영상 분석 결과 — 실수 장면 · 샷 선택 · 각도 · 포지셔닝 피드백
//
// ┌──────── 디자인 가이드 대응표: V 영상 분석 결과 ─────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)    │
// │ V-1  │ AppBar + BackButton               │ 영상 분석 제목줄      │ P03 통제·자유  │
// │ V-2  │ AspectRatio(16:9) + IconButton    │ 영상 화면(예시)       │ P02 실세계     │
// │ V-3  │ Card(Text)                        │ AI 한 줄 진단         │ P08 미니멀     │
// │ V-4  │ ListTile(Chip 시간) × n           │ 실수 장면 타임라인    │ P06 재인       │
// │ V-5  │ Card × 3 (아이콘 + 제목 + 본문)    │ 샷 선택·각도·포지셔닝 │ P02 · P07      │
// │ V-6  │ DemoNotice                        │ 예시 분석 고지        │ P10 도움말     │
// │ V-7  │ LayoutBuilder (≥840dp 2단)        │ 영상 | 피드백 나란히  │ 적응형         │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환: C → V 쌓기(push). 데이터는 C에서 받은 MatchVideo 그대로 (추가 GET 없음).
// ⚠ 실제 영상 재생·분석 없음 — 재생 버튼은 SnackBar, 피드백은 db.json에 미리 적은 문장.
import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';

class VideoAnalysisScreen extends StatelessWidget {
  const VideoAnalysisScreen({super.key, required this.video});

  final MatchVideo video;

  @override
  Widget build(BuildContext context) {
    final v = video;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final player = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        // V-2 P02
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: const Color(0xFF0B6E4F),
          child: Center(
            child: IconButton.filled(
              iconSize: 40,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('예시 화면입니다 — 영상 재생은 없습니다.')),
              ),
              icon: const Icon(Icons.play_arrow),
            ),
          ),
        ),
      ),
    );

    final diagnosis = Card(
      // V-3 P08
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, size: 20),
                SizedBox(width: 6),
                Text('AI 진단'),
              ],
            ),
            const SizedBox(height: 8),
            Text(v.summary, style: text.bodyLarge),
          ],
        ),
      ),
    );

    final mistakes = [
      const SectionTitle('실수 장면', icon: Icons.error_outline),
      for (final m in v.mistakes)
        ListTile(
          // V-4 P06: 시간을 눌러 찾아가지 않아도 장면과 원인을 함께 본다
          contentPadding: EdgeInsets.zero,
          leading: Chip(label: Text(m.time)),
          title: Text(m.title),
          subtitle: Text(m.cause),
        ),
    ];

    final feedback = [
      const SectionTitle('맞춤 피드백', icon: Icons.tips_and_updates_outlined),
      for (final (icon, title, body) in [
        (Icons.alt_route, '샷 선택', v.shotSelection),
        (Icons.architecture, '각도', v.angle),
        (Icons.my_location, '포지셔닝', v.positioning),
      ])
        if (body.isNotEmpty)
          Card(
            // V-5 P02 P07
            child: ListTile(
              leading: Icon(icon, color: scheme.primary),
              title: Text(title),
              subtitle: Text(body),
            ),
          ),
      const SizedBox(height: 8),
      const DemoNotice('※ 미리 작성한 예시 분석입니다. 실제 영상 분석은 v2 이후 기능입니다.'), // V-6 P10
    ];

    return Scaffold(
      appBar: AppBar(title: Text(v.title)), // V-1 P03
      body: LayoutBuilder(
        // V-7 적응형
        builder: (context, constraints) {
          final header = [
            player,
            const SizedBox(height: 8),
            Text(
              '${v.player} · ${v.date} · ${v.duration}',
              style: text.bodySmall,
            ),
            const SizedBox(height: 8),
            diagnosis,
          ];
          if (constraints.maxWidth >= 840) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [...header, ...mistakes],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: feedback,
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [...header, ...mistakes, ...feedback],
          );
        },
      ),
    );
  }
}
