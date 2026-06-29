import 'package:flutter/material.dart';

class LoadingListSkeleton extends StatelessWidget {
  const LoadingListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Bar(width: 110, color: color),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _Bar(height: 18, color: color)),
                const SizedBox(width: 28),
                _Bar(width: 54, height: 24, color: color),
                const SizedBox(width: 28),
                Expanded(child: _Bar(height: 18, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            _Bar(width: 180, color: color),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({this.width, this.height = 12, required this.color});

  final double? width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
