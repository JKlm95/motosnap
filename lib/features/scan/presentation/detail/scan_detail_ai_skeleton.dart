import 'package:flutter/material.dart';

import '../../../../core/ui/shimmer/moto_shimmer.dart';

/// Skeleton wyniku AI (sekcja w panelu szczegółów).
class ScanDetailAiResultSkeleton extends StatelessWidget {
  const ScanDetailAiResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget line(double w, double h) {
      return MotoShimmer(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            line(120, 14),
            const SizedBox(height: 12),
            line(double.infinity, 12),
            line(200, 12),
            const SizedBox(height: 10),
            line(160, 12),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: MotoShimmer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceContainerHigh,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
