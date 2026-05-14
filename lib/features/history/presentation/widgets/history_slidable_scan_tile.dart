import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../../core/ui/app_motion.dart';
import '../../../scan/domain/vehicle_scan.dart';
import '../../../scan/domain/vehicle_scan_status.dart';
import '../../domain/history_list_query.dart';

class HistorySlidableScanTile extends StatelessWidget {
  const HistorySlidableScanTile({
    required this.s,
    required this.scan,
    required this.child,
    required this.onOpenDetail,
    required this.onDelete,
    required this.onTogglePublic,
    required this.onRetryAi,
    super.key,
  });

  final AppStrings s;
  final VehicleScan scan;
  final Widget child;
  final VoidCallback onOpenDetail;
  final Future<void> Function() onDelete;
  final Future<void> Function() onTogglePublic;
  final Future<void> Function() onRetryAi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canRetry =
        scan.status == VehicleScanStatus.failed &&
        isHistoryScanSyncedToCloud(scan);

    return Slidable(
      key: ValueKey('slidable-${scan.id}'),
      groupTag: 'history',
      closeOnScroll: true,
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: canRetry ? 0.46 : 0.32,
        children: [
          SlidableAction(
            onPressed: (_) async {
              await onTogglePublic();
              if (context.mounted) {
                AppHaptics.success();
              }
            },
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            icon: scan.isPublic ? Icons.lock_outline : Icons.public_outlined,
            label: scan.isPublic ? s.historySwipePrivate : s.historySwipePublic,
          ),
          if (canRetry)
            SlidableAction(
              onPressed: (_) async {
                await onRetryAi();
                if (context.mounted) {
                  AppHaptics.lightImpact();
                }
              },
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              icon: Icons.auto_awesome_rounded,
              label: s.historySwipeRetryAi,
            ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.26,
        children: [
          SlidableAction(
            onPressed: (_) async {
              AppHaptics.warning();
              await onDelete();
            },
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            icon: Icons.delete_outline_rounded,
            label: s.historySwipeDelete,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenDetail,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}

/// Lekkie wejście kafelka (tylko przy zmianie [animationEpoch]).
class HistoryTileEnterAnimation extends StatelessWidget {
  const HistoryTileEnterAnimation({
    required this.index,
    required this.animationEpoch,
    required this.child,
    super.key,
  });

  final int index;
  final int animationEpoch;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delayMs = (index.clamp(0, 14)) * 28;
    return TweenAnimationBuilder<double>(
      key: ValueKey('hist-anim-$animationEpoch-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + delayMs),
      curve: AppMotion.emphasizedDecelerate,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
