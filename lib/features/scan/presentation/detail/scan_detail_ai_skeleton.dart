import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/locale/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/shimmer/moto_shimmer.dart';

/// Skeleton wyniku AI z premium komunikatami statusu.
class ScanDetailAiResultSkeleton extends StatefulWidget {
  const ScanDetailAiResultSkeleton({super.key});

  @override
  State<ScanDetailAiResultSkeleton> createState() =>
      _ScanDetailAiResultSkeletonState();
}

class _ScanDetailAiResultSkeletonState
    extends State<ScanDetailAiResultSkeleton> {
  Timer? _timer;
  int _lineIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted) {
        return;
      }
      final lines = AppStrings.of(context).aiAnalysisStatusLines;
      setState(() => _lineIndex = (_lineIndex + 1) % lines.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lines = s.aiAnalysisStatusLines;
    final status = lines[_lineIndex % lines.length];
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
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: Text(
                status,
                key: ValueKey(status),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryRed,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            line(double.infinity, 12),
            const SizedBox(height: 10),
            line(200, 12),
            const SizedBox(height: 10),
            line(160, 12),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primaryRed.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
