// 공용 화면 조각 — GET을 쓰는 화면은 모두 이 세 상태를 그린다 (AGENTS.md MUST).
//   LoadingView   불러오는 중 표시      P01 시스템 상태의 가시성
//   ErrorView     오류 안내·다시 시도   P09 오류 인식·진단·복구
//   EmptyView     빈 목록 안내          P01
//   AsyncListView 위 세 상태 + 데이터를 한 번에 고르는 FutureBuilder 묶음
//   StatusBadge   대회·경기 상태 배지   P01 (색 + 글자 — 색만으로 구분하지 않음)
//   DemoNotice    예시 결과 고지        P10 도움말
import 'package:flutter/material.dart';

/// 이 너비 이상이면 넓은 화면 배치 (Material 3 window size class: medium ≥ 600dp)
const wideBreakpoint = 600.0;

/// 로딩 상태
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = '불러오는 중…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label),
        ],
      ),
    );
  }
}

/// 오류 상태: 무엇이 잘못됐는지 + 다시 시도 버튼
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = '정보를 불러오지 못했습니다.',
    this.message = '',
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 빈 상태: 목록이 비었을 때 안내
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.message = '표시할 항목이 없습니다.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// 네트워크 이미지 — 실패해도 화면은 그대로 보이게
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.width, this.height});

  final String url;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.image_outlined, size: 40),
      ),
    );
  }
}

/// GET 화면 공통: 로딩 → 오류(다시 시도) → 빈 상태 → 데이터 네 갈래
/// 다시 시도는 부른 쪽이 Future를 새로 만드는 setState로 처리한다 (화면 안 표시 변화 — 허용).
class AsyncListView<T> extends StatelessWidget {
  const AsyncListView({
    super.key,
    required this.future,
    required this.onRetry,
    required this.builder,
    this.loadingLabel = '불러오는 중…',
    this.errorTitle = '정보를 불러오지 못했습니다.',
    this.emptyMessage = '표시할 항목이 없습니다.',
  });

  final Future<List<T>> future;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, List<T> items) builder;
  final String loadingLabel;
  final String errorTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return LoadingView(label: loadingLabel); // P01
        }
        if (snap.hasError) {
          return ErrorView(
            title: errorTitle,
            message: '${snap.error}',
            onRetry: onRetry,
          ); // P09
        }
        final items = snap.data ?? <T>[];
        if (items.isEmpty) return EmptyView(message: emptyMessage); // P01
        return builder(context, items);
      },
    );
  }
}

/// 상태 배지: 접수중 · 진행중 · 종료 · 예정 · 승 · 패 — 색과 글자를 함께 쓴다
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      '접수중' || '승' => (scheme.primaryContainer, scheme.onPrimaryContainer),
      '진행중' => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      '패' => (scheme.errorContainer, scheme.onErrorContainer),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 예시 결과 고지 — AI 결과·신청 결과가 실제가 아님을 알린다
class DemoNotice extends StatelessWidget {
  const DemoNotice(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

/// 섹션 제목 한 줄
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Text(text, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// 스카치 더블 배지 — 두 선수가 한 팀으로 번갈아 치는 대회임을 카드·상세·신청 시트에서 같은 모양으로 알린다
class ScotchDoublesBadge extends StatelessWidget {
  const ScotchDoublesBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_alt, size: 14, color: scheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            '스카치 더블 · 2인 1팀',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 당구공 로고 — 단색공(1–8)은 공 전체가 색, 줄무늬공(9–15)은 가운데 띠만 색. 가운데 흰 원에 번호.
class PoolBall extends StatelessWidget {
  const PoolBall({
    super.key,
    required this.number,
    required this.color,
    this.striped = false,
    this.size = 26,
  });

  final int number;
  final Color color;
  final bool striped;
  final double size;

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.56;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (striped)
              // Positioned.fill: 띠가 공 너비를 꽉 채우게 (안 하면 너비 0)
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(child: ColoredBox(color: Colors.white)),
                    Expanded(flex: 2, child: ColoredBox(color: color)),
                    const Expanded(child: ColoredBox(color: Colors.white)),
                  ],
                ),
              )
            else
              ColoredBox(color: color, child: const SizedBox.expand()),
            Container(
              width: inner,
              height: inner,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: number > 9 ? size * 0.28 : size * 0.35,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 웹(Chrome)에서 한글 글꼴이 늦게 도착하면, 그 전에 잰 너비로 칩 글자가 잘린다.
/// 글꼴이 도착했다는 알림(systemFonts)을 받으면 child를 새로 만들어 다시 재게 한다.
/// child 안의 상태(선택한 필터 등)는 부모가 들고 있으므로 지워지지 않는다. 폰 · 데스크톱 앱에서는 알림이 거의 없다.
class RebuildOnFontLoad extends StatefulWidget {
  const RebuildOnFontLoad({super.key, required this.child});

  final Widget child;

  @override
  State<RebuildOnFontLoad> createState() => _RebuildOnFontLoadState();
}

class _RebuildOnFontLoadState extends State<RebuildOnFontLoad> {
  int _generation = 0;

  void _onFontsChanged() {
    if (!mounted) return;
    setState(() {
      _generation++;
    });
  }

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_onFontsChanged);
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_onFontsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: ValueKey(_generation), child: widget.child);
  }
}
