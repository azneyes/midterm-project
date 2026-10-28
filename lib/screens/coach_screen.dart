// 화면 C: AI 코치 — 분석할 경기 영상 고르기 (GET /videos)
//
// ┌──────── 디자인 가이드 대응표: C AI 코치 ────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)   │
// │ C-1  │ AppBar                            │ AI 코치 제목줄        │ P04 일관성    │
// │ C-2  │ Card(안내 문구)                   │ AI 코치 사용 안내     │ P10 도움말    │
// │ C-3  │ OutlinedButton → SnackBar         │ 영상 올리기(예시)     │ STATE 표시만  │
// │ C-4  │ ListView + Card (VideoCard)       │ 분석된 경기 영상 목록 │ P06 재인      │
// │ C-5  │ GridView (넓은 화면 ≥600dp)        │ 영상 카드 격자        │ 적응형        │
// │ C-6  │ LoadingView · ErrorView · EmptyView│ 3상태                │ P01 · P09     │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환: C → V 는 쌓기(Navigator.push).
// ⚠ 실제 영상 업로드·분석 없음 — "영상 올리기"는 SnackBar만, 분석 결과는 db.json에 미리 적은 값.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'video_analysis_screen.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key, this.load = fetchVideos});

  final Loader<MatchVideo> load;

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  late Future<List<MatchVideo>> _future = widget.load();

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  void _open(MatchVideo v) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => VideoAnalysisScreen(video: v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final intro = Card(
      // C-2 P10: 무엇을 해 주는 화면인지 먼저 알려 준다
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 6),
                Text('녹화 영상으로 실수 원인 찾기'),
              ],
            ),
            const SizedBox(height: 6),
            const Text('경기 영상을 고르면 실수 장면 · 샷 선택 · 각도 · 포지셔닝 피드백을 보여 줍니다.'),
            const SizedBox(height: 12),
            // STATE: 올린 영상 · 분석 진행률 → C-4 목록 맨 위 카드 — v2 이후 상태관리로 구현 (지금은 표시만)
            OutlinedButton.icon(
              // C-3
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('예시 화면입니다 — 실제로 영상을 올리지 않습니다.')),
              ),
              icon: const Icon(Icons.upload),
              label: const Text('영상 올리기 (예시)'),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('AI 코치')), // C-1 P04
      body: Column(
        children: [
          intro,
          Expanded(
            child: AsyncListView<MatchVideo>(
              // C-6 P01 · P09
              future: _future,
              onRetry: _retry,
              loadingLabel: '분석된 영상을 불러오는 중…',
              errorTitle: '영상 목록을 불러오지 못했습니다.',
              emptyMessage: '아직 분석된 영상이 없습니다.\n위의 "영상 올리기"로 시작하세요.',
              builder: (context, videos) => LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= wideBreakpoint) {
                    return GridView.builder(
                      // C-5 넓은 화면
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 96,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: videos.length,
                      itemBuilder: (context, i) => VideoCard(
                        videos[i],
                        margin: EdgeInsets.zero,
                        onTap: () => _open(videos[i]),
                      ),
                    );
                  }
                  return ListView.builder(
                    // C-4 P06
                    itemCount: videos.length,
                    itemBuilder: (context, i) =>
                        VideoCard(videos[i], onTap: () => _open(videos[i])),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 경기 영상 카드 — 영상 아이콘 · 제목 · 선수 · 날짜 · 길이
class VideoCard extends StatelessWidget {
  const VideoCard(
    this.video, {
    super.key,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  final MatchVideo video;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final v = video;
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.play_arrow,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${v.player} · ${v.date} · ${v.duration}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
