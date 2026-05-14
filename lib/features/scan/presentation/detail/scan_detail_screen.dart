import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/locale/app_strings.dart';
import '../../domain/user_vehicle_correction.dart';
import '../../domain/vehicle_info.dart';
import '../../domain/vehicle_scan.dart';
import '../../domain/vehicle_scan_status.dart';
import 'scan_detail_cubit.dart';
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
        return Scaffold(
          appBar: AppBar(title: Text(s.scanDetailsTitle)),
          body: switch (state.phase) {
            ScanDetailPhase.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ScanDetailPhase.notFound => _NotFound(s: s),
            ScanDetailPhase.removed => const SizedBox.shrink(),
            ScanDetailPhase.ready => _DetailBody(
              s: s,
              scan: state.scan!,
              busy: state.busy,
              errorMessage: state.errorMessage,
            ),
          },
        );
      },
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

bool _isSyncedToCloud(VehicleScan scan) {
  return !scan.pendingSync &&
      (scan.remoteImageUrl != null && scan.remoteImageUrl!.isNotEmpty);
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.s,
    required this.scan,
    required this.busy,
    required this.errorMessage,
  });

  final AppStrings s;
  final VehicleScan scan;
  final bool busy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final file = File(scan.localImagePath);
    final locationLabel =
        scan.location.displayName ??
        '${scan.location.latitude.toStringAsFixed(4)}, '
            '${scan.location.longitude.toStringAsFixed(4)}';

    final synced = _isSyncedToCloud(scan);
    final canAnalyze =
        scan.status == VehicleScanStatus.waitingForRecognition && synced;
    final localeLang = Localizations.localeOf(context).languageCode;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 200),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: file.existsSync()
                    ? Image.file(file, fit: BoxFit.cover)
                    : ColoredBox(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.scanStatus(scan.status),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.locationPrefix}: $locationLabel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (synced)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  s.syncedToCloud,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            if (!synced &&
                scan.status == VehicleScanStatus.waitingForRecognition) ...[
              const SizedBox(height: 16),
              Text(
                s.syncBeforeAiHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
            if (canAnalyze) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () => context.read<ScanDetailCubit>().runAiAnalysis(
                        localeLang,
                      ),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(s.analyzeWithAi),
              ),
            ],
            if (scan.status == VehicleScanStatus.recognized ||
                scan.status == VehicleScanStatus.failed) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => showVehicleUserCorrectionSheet(
                        context: context,
                        scan: scan,
                        onSave: (UserVehicleCorrection c) => context
                            .read<ScanDetailCubit>()
                            .saveUserCorrection(c),
                      ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(s.correctResult),
              ),
            ],
            if ((scan.status == VehicleScanStatus.recognized ||
                    scan.status == VehicleScanStatus.failed) &&
                scan.effectiveVehicleInfo != null) ...[
              const SizedBox(height: 20),
              if (scan.userCorrection != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    s.correctedByUserLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                s.vehicleInformationSection,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _VehicleInfoCard(s: s, info: scan.effectiveVehicleInfo!),
              if (scan.userCorrection != null && scan.vehicleInfo != null) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    s.originalAiResult,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  children: [_VehicleInfoCard(s: s, info: scan.vehicleInfo!)],
                ),
              ],
            ],
            if (scan.status == VehicleScanStatus.failed) ...[
              const SizedBox(height: 16),
              Text(
                s.recognitionFailedTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.recognitionFailedNoDetails,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (synced) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: busy
                      ? null
                      : () => context.read<ScanDetailCubit>().runAiAnalysis(
                          localeLang,
                        ),
                  child: Text(s.tryAgain),
                ),
              ],
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              TextButton(
                onPressed: () => context.read<ScanDetailCubit>().clearError(),
                child: Text(s.closeMessage),
              ),
            ],
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.tonal(
                onPressed: busy
                    ? null
                    : () => context.read<ScanDetailCubit>().togglePublic(),
                child: Text(scan.isPublic ? s.setPrivate : s.setPublic),
              ),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: busy
                    ? null
                    : () async {
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
                child: Text(s.deleteScan),
              ),
            ],
          ),
        ),
        if (busy)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _VehicleInfoCard extends StatelessWidget {
  const _VehicleInfoCard({required this.s, required this.info});

  final AppStrings s;
  final VehicleInfo info;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(context, s.fieldType, s.vehicleType(info.vehicleType)),
            _row(context, s.fieldBrand, info.brand ?? s.emDash),
            _row(context, s.fieldModel, info.model ?? s.emDash),
            _row(context, s.fieldGeneration, info.generation ?? s.emDash),
            _row(
              context,
              s.fieldProductionYears,
              info.productionYears ?? s.emDash,
            ),
            if (info.possibleEngines.isNotEmpty)
              _row(
                context,
                s.fieldEnginesHint,
                info.possibleEngines.join(', '),
              ),
            _row(
              context,
              s.fieldConfidence,
              info.confidence != null
                  ? '${(info.confidence! * 100).toStringAsFixed(0)} %'
                  : s.emDash,
            ),
            if (info.shortDescription != null &&
                info.shortDescription!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                info.shortDescription!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(v, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
