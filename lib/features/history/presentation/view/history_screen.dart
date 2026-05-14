import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/main_shell_layout.dart';
import '../../../../core/firebase/cloud_sync_availability.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../../core/ui/app_shape.dart';
import '../../../scan/domain/vehicle_scan.dart';
import '../../../scan/presentation/widgets/scan_image_display.dart';
import '../../../scan/presentation/widgets/scan_status_badge.dart';
import '../cubit/history_cubit.dart';
import '../cubit/history_state.dart';
import '../widgets/history_filters_bar.dart';
import '../widgets/history_list_skeleton.dart';
import '../widgets/history_slidable_scan_tile.dart';

String? _historyVehicleSubtitle(VehicleScan scan, AppStrings s) {
  final e = scan.effectiveVehicleInfo;
  if (e == null) {
    return null;
  }
  final parts = <String>[];
  if (e.brand != null && e.brand!.trim().isNotEmpty) {
    parts.add(e.brand!.trim());
  }
  if (e.model != null && e.model!.trim().isNotEmpty) {
    parts.add(e.model!.trim());
  }
  if (parts.isNotEmpty) {
    return parts.join(' ');
  }
  if (e.vehicleType != null) {
    return s.vehicleType(e.vehicleType);
  }
  return null;
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bottomPad = MainShellLayout.paddingOf(context);
    final cloudOk = context.read<CloudSyncAvailability>().available;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.historyTitle),
        actions: [
          IconButton(
            tooltip: s.historyRefreshTooltip,
            onPressed: () => context.read<HistoryCubit>().refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<HistoryCubit, HistoryState>(
        listenWhen: (prev, next) =>
            next.transientSnackMessage != null &&
            next.transientSnackMessage != prev.transientSnackMessage,
        listener: (context, state) {
          final m = state.transientSnackMessage;
          if (m != null) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(SnackBar(content: Text(m)));
            context.read<HistoryCubit>().clearTransientSnack();
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.scans.isEmpty) {
            return const HistoryListSkeleton();
          }
          if (state.errorMessage != null && state.scans.isEmpty) {
            return _HistoryError(message: state.errorMessage!);
          }
          if (state.scans.isEmpty) {
            return _HistoryEmptyNoScans(s: s, cloudOk: cloudOk);
          }

          final visible = state.visibleScans;
          final scheme = Theme.of(context).colorScheme;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HistoryFiltersBar(
                s: s,
                filter: state.filter,
                sort: state.sort,
                onFilterSelected: context.read<HistoryCubit>().setFilter,
                onSortSelected: context.read<HistoryCubit>().setSort,
              ),
              if (state.isLoading && state.scans.isNotEmpty)
                LinearProgressIndicator(
                  minHeight: 2,
                  color: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              Expanded(
                child: visible.isEmpty
                    ? RefreshIndicator(
                        color: scheme.primary,
                        backgroundColor: scheme.surfaceContainerLow,
                        strokeWidth: 2.5,
                        displacement: 40,
                        onRefresh: () => context.read<HistoryCubit>().refresh(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: const Center(
                                  child: _HistoryEmptyFilterContent(),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : RefreshIndicator(
                        color: scheme.primary,
                        backgroundColor: scheme.surfaceContainerLow,
                        strokeWidth: 2.5,
                        displacement: 40,
                        onRefresh: () => context.read<HistoryCubit>().refresh(),
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                bottomPad,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final scan = visible[index];
                                  final isLast = index == visible.length - 1;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isLast ? 0 : 10,
                                    ),
                                    child: HistorySlidableScanTile(
                                      s: s,
                                      scan: scan,
                                      onOpenDetail: () {
                                        AppHaptics.selection();
                                        context.push(
                                          AppRoutes.vehicleScan(scan.id),
                                        );
                                      },
                                      onDelete: () => _confirmDeleteHistoryScan(
                                        context,
                                        scan.id,
                                      ),
                                      onTogglePublic: () => context
                                          .read<HistoryCubit>()
                                          .togglePublic(scan),
                                      onRetryAi: () => context
                                          .read<HistoryCubit>()
                                          .retryAiAnalysis(scan.id),
                                      child: HistoryTileEnterAnimation(
                                        index: index,
                                        animationEpoch:
                                            state.listAnimationEpoch,
                                        child: Stack(
                                          children: [
                                            _HistoryScanTileCard(
                                              s: s,
                                              scan: scan,
                                            ),
                                            if (state.retryingScanId == scan.id)
                                              const Positioned.fill(
                                                child: IgnorePointer(
                                                  child: Center(
                                                    child: SizedBox.square(
                                                      dimension: 28,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }, childCount: visible.length),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmDeleteHistoryScan(
  BuildContext context,
  String scanId,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final d = AppStrings.of(ctx);
      return AlertDialog(
        title: Text(d.deleteScanConfirmTitle),
        content: Text(d.deleteScanConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(d.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(d.delete),
          ),
        ],
      );
    },
  );
  if (ok == true && context.mounted) {
    await context.read<HistoryCubit>().deleteScan(scanId);
  }
}

class _HistoryEmptyNoScans extends StatelessWidget {
  const _HistoryEmptyNoScans({required this.s, required this.cloudOk});

  final AppStrings s;
  final bool cloudOk;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 42,
              color: scheme.onSurface.withValues(alpha: 0.32),
            ),
            const SizedBox(height: 16),
            Text(
              s.historyEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
                height: 1.35,
              ),
            ),
            if (!cloudOk) ...[
              const SizedBox(height: 12),
              Text(
                s.historyOfflineHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () {
                AppHaptics.selection();
                context.go(AppRoutes.scanRelative);
              },
              child: Text(s.historyGoToScanCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEmptyFilterContent extends StatelessWidget {
  const _HistoryEmptyFilterContent();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list_off_rounded,
            size: 34,
            color: scheme.onSurface.withValues(alpha: 0.32),
          ),
          const SizedBox(height: 14),
          Text(
            s.historyFilterEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: scheme.error.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryScanTileCard extends StatelessWidget {
  const _HistoryScanTileCard({required this.s, required this.scan});

  final AppStrings s;
  final VehicleScan scan;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_Hm().format(scan.createdAt.toLocal());
    final locationLabel =
        scan.location.displayName ??
        scan.location.city ??
        '${scan.location.latitude.toStringAsFixed(3)}, '
            '${scan.location.longitude.toStringAsFixed(3)}';
    final subtitle = _historyVehicleSubtitle(scan, s);
    final recognition = s.historyVehicleSummary(subtitle);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppShape.thumbnail),
              child: SizedBox(
                width: 72,
                height: 72,
                child: ScanImageDisplay(
                  heroTag: ScanImageDisplay.heroTagFor(scan.id),
                  localImagePath: scan.localImagePath,
                  remoteImageUrl: scan.remoteImageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locationLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recognition,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ScanStatusBadge(
                  status: scan.status,
                  label: s.scanStatus(scan.status),
                ),
                if (scan.userCorrection != null) ...[
                  const SizedBox(height: 6),
                  UserCorrectedBadge(label: s.correctedByUserLabel),
                ],
                if (scan.isPublic)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      s.historyPublicBadge,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
