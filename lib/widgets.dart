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
