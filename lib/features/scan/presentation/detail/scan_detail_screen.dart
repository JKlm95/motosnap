import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_shape.dart';
import '../../../../core/ui/glass/glass_surface.dart';
import '../../../../core/ui/shimmer/moto_shimmer.dart';
import '../../domain/user_vehicle_correction.dart';
import '../../domain/vehicle_scan.dart';
import '../../domain/vehicle_scan_status.dart';
import '../widgets/scan_image_display.dart';
import 'scan_detail_cubit.dart';
import 'scan_detail_sheet_content.dart';
import 'scan_detail_state.dart';
import 'vehicle_user_correction_sheet.dart';

class ScanDetailScreen extends StatelessWidget {
  const ScanDetailScreen({required this.scanId, super.key});

  final String scanId;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return BlocConsumer<ScanDetailCubit, ScanDetailState>(
      listenWhen: (prev, next) =>
          prev.phase != next.phase && next.phase == ScanDetailPhase.removed,
      listener: (context, state) {
        if (context.mounted) {
          context.pop();
        }
      },
      builder: (context, state) {
        return switch (state.phase) {
          ScanDetailPhase.loading => Scaffold(
            appBar: AppBar(title: Text(s.scanDetailsTitle)),
            body: const _ScanDetailLoadingPlaceholder(),
          ),
          ScanDetailPhase.notFound => Scaffold(
            appBar: AppBar(title: Text(s.scanDetailsTitle)),
            body: _NotFound(s: s),
          ),
          ScanDetailPhase.removed => const Scaffold(body: SizedBox.shrink()),
          ScanDetailPhase.ready => Scaffold(
            key: ValueKey(scanId),
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: _ScanDetailHapticListener(
              child: _DetailBody(
                s: s,
                scan: state.scan!,
                busy: state.busy,
                aiBusy: state.aiBusy,
                vehicleRevealToken: state.vehicleRevealToken,
                errorMessage: state.errorMessage,
              ),
            ),
          ),
        };
      },
    );
  }
}

class _ScanDetailLoadingPlaceholder extends StatelessWidget {
  const _ScanDetailLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MotoShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppShape.headerImage),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              flex: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppShape.sheetTop),
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

class _NotFound extends StatelessWidget {
  const _NotFound({required this.s});

  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.scanNotFound),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.pop(), child: Text(s.back)),
          ],
        ),
      ),
    );
  }
}

class _ScanDetailHapticListener extends StatefulWidget {
  const _ScanDetailHapticListener({required this.child});

  final Widget child;

  @override
  State<_ScanDetailHapticListener> createState() =>
      _ScanDetailHapticListenerState();
}

class _ScanDetailHapticListenerState extends State<_ScanDetailHapticListener> {
  ScanDetailState? _prevForHaptic;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScanDetailCubit, ScanDetailState>(
      listenWhen: (prev, next) {
        if (!prev.busy || next.busy || next.phase != ScanDetailPhase.ready) {
          return false;
        }
        if (prev.scan == null || next.scan == null) {
          return false;
        }
        final p = prev.scan!;
        final n = next.scan!;
        var fire = false;
        if (next.errorMessage != null) {
          fire = true;
        } else if (p.status == VehicleScanStatus.waitingForRecognition &&
            (n.status == VehicleScanStatus.recognized ||
                n.status == VehicleScanStatus.failed)) {
          fire = true;
        } else if (p.userCorrection?.correctedAt !=
                n.userCorrection?.correctedAt &&
            n.userCorrection != null) {
          fire = true;
        }
        if (fire) {
          _prevForHaptic = prev;
        }
        return fire;
      },
      listener: (context, next) {
        final prev = _prevForHaptic;
        _prevForHaptic = null;
        if (prev?.scan == null || next.scan == null) {
          return;
        }
        if (next.errorMessage != null) {
          AppHaptics.error();
          return;
        }
        final p = prev!.scan!;
        final n = next.scan!;
        if (p.status == VehicleScanStatus.waitingForRecognition) {
          if (n.status == VehicleScanStatus.recognized) {
            AppHaptics.success();
          } else if (n.status == VehicleScanStatus.failed) {
            AppHaptics.warning();
          }
          return;
        }
        AppHaptics.success();
      },
      child: widget.child,
    );
  }
}

bool _isSyncedToCloud(VehicleScan scan) {
  return !scan.pendingSync &&
      (scan.remoteImageUrl != null && scan.remoteImageUrl!.isNotEmpty);
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.s,
    required this.scan,
    required this.busy,
    required this.aiBusy,
    required this.vehicleRevealToken,
    required this.errorMessage,
  });

  final AppStrings s;
  final VehicleScan scan;
  final bool busy;
  final ScanDetailAiBusy aiBusy;
  final int vehicleRevealToken;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final fullH = media.size.height;
    final compact = fullH < 700;
    final headerH = (fullH * (compact ? 0.38 : 0.42)).clamp(
      compact ? 196.0 : 220.0,
      fullH * 0.48,
    );
    final initialSheet = (1.0 - (headerH / fullH) + 0.06)
        .clamp(0.54, 0.66)
        .toDouble();
    final snapMid = initialSheet <= 0.41
        ? 0.56
        : initialSheet.clamp(0.42, 0.68);

    final synced = _isSyncedToCloud(scan);
    final showAiSkeleton =
        busy &&
        aiBusy == ScanDetailAiBusy.yes &&
        (scan.status == VehicleScanStatus.waitingForRecognition ||
            scan.status == VehicleScanStatus.failed);
    final canAnalyze =
        scan.status == VehicleScanStatus.waitingForRecognition && synced;
    final localeLang = Localizations.localeOf(context).languageCode;
    final heroTag = ScanImageDisplay.heroTagFor(scan.id);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surface),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: headerH,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.header),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ScanImageDisplay(
                  heroTag: heroTag,
                  localImagePath: scan.localImagePath,
                  remoteImageUrl: scan.remoteImageUrl,
                  fit: BoxFit.cover,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.detailHeader,
                  ),
                ),
              ],
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: initialSheet,
          minChildSize: 0.38,
          maxChildSize: 0.94,
          snap: true,
          snapSizes: <double>[0.38, snapMid, 0.94],
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppShape.sheetTop),
              ),
              child: GlassSurface(
                blurSigma: AppShape.blurDetailSheet,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppShape.sheetTop),
                ),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ScanDetailSheetContent(
                        scan: scan,
                        s: s,
                        busy: busy,
                        showAiSkeleton: showAiSkeleton,
                        vehicleRevealToken: vehicleRevealToken,
                        errorMessage: errorMessage,
                        synced: synced,
                        canAnalyze: canAnalyze,
                        scrollController: scrollController,
                        onAnalyze: () {
                          AppHaptics.lightImpact();
                          context.read<ScanDetailCubit>().runAiAnalysis(
                            localeLang,
                          );
                        },
                        onOpenCorrection: () {
                          AppHaptics.selection();
                          showVehicleUserCorrectionSheet(
                            context: context,
                            scan: scan,
                            onSave: (UserVehicleCorrection c) => context
                                .read<ScanDetailCubit>()
                                .saveUserCorrection(c),
                          );
                        },
                        onTogglePublic: () {
                          AppHaptics.lightImpact();
                          context.read<ScanDetailCubit>().togglePublic();
                        },
                        onDeleteTap: () async {
                          AppHaptics.warning();
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
                            await context.read<ScanDetailCubit>().delete();
                          }
                        },
                        onClearError: () {
                          AppHaptics.lightImpact();
                          context.read<ScanDetailCubit>().clearError();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
              child: Material(
                color: Colors.black.withValues(alpha: 0.38),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: s.back,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                  onPressed: () {
                    AppHaptics.lightImpact();
                    context.pop();
                  },
                ),
              ),
            ),
          ),
        ),
        if (busy && !showAiSkeleton)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
