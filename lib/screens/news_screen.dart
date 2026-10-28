// 화면 N: 협회 소식 (GET /news)
//
// ┌──────── 디자인 가이드 대응표: N 협회 소식 ──────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글)   │ 원칙(P번호)   │
// │ N-1  │ AppBar                            │ 협회 소식 제목줄      │ P04 일관성    │
// │ N-2  │ ExpansionTile × n                 │ 소식 카드(펼쳐 읽기)  │ P08 미니멀    │
// │ N-3  │ StatusBadge(category)             │ 공지 · 경기 결과 · 규정│ P06 재인     │
// │ N-4  │ ConstrainedBox(maxWidth 720)      │ 넓은 화면 읽기 폭     │ 적응형        │
// │ N-5  │ LoadingView · ErrorView · EmptyView│ 3상태                │ P01 · P09     │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환 없음: 본문은 같은 화면에서 펼친다(ExpansionTile — 화면 안 표시 변화, 허용).
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, this.load = fetchNews});

  final Loader<News> load;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<News>> _future = widget.load();

  // STATE: 읽은 소식 → N-2 제목 굵기 — v2 이후 상태관리로 구현 (지금은 표시만, 저장하지 않음)

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('협회 소식')), // N-1 P04
      body: AsyncListView<News>(
        // N-5 P01 · P09
        future: _future,
        onRetry: _retry,
        loadingLabel: '소식을 불러오는 중…',
        errorTitle: '소식을 불러오지 못했습니다.',
        emptyMessage: '새 소식이 없습니다.',
        builder: (context, items) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            // N-4 적응형: 넓은 화면에서도 한 줄이 너무 길지 않게
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    // N-2 P08
                    shape: const Border(),
                    title: Text(n.title),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          StatusBadge(n.category), // N-3 P06
                          const SizedBox(width: 8),
                          Text(n.date),
                        ],
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(n.body)],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
