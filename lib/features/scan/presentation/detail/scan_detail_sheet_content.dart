import 'package:flutter/material.dart';

import '../../../../core/locale/app_strings.dart';
import '../../domain/vehicle_scan.dart';
import '../../domain/vehicle_scan_status.dart';
import '../widgets/scan_status_badge.dart';
import 'scan_detail_vehicle_info_card.dart';

/// Treść przewijanego panelu szczegółów skanu (sekcje + akcje).
class ScanDetailSheetContent extends StatelessWidget {
  const ScanDetailSheetContent({
    required this.scan,
    required this.s,
    required this.busy,
    required this.errorMessage,
    required this.synced,
    required this.canAnalyze,
    required this.scrollController,
    required this.onAnalyze,
    required this.onOpenCorrection,
    required this.onTogglePublic,
    required this.onDeleteTap,
    required this.onClearError,
    super.key,
  });

  final VehicleScan scan;
  final AppStrings s;
  final bool busy;
  final String? errorMessage;
  final bool synced;
  final bool canAnalyze;
  final ScrollController scrollController;
  final VoidCallback onAnalyze;
  final VoidCallback onOpenCorrection;
  final VoidCallback onTogglePublic;
  final VoidCallback onDeleteTap;
  final VoidCallback onClearError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locationLabel =
        scan.location.displayName ??
        '${scan.location.latitude.toStringAsFixed(4)}, '
            '${scan.location.longitude.toStringAsFixed(4)}';

    final showVehicle =
        (scan.status == VehicleScanStatus.recognized ||
            scan.status == VehicleScanStatus.failed) &&
        scan.effectiveVehicleInfo != null;

    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Text(
          s.scanDetailsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ScanStatusBadge(
              status: scan.status,
              label: s.scanStatus(scan.status),
            ),
            if (scan.userCorrection != null)
              UserCorrectedBadge(label: s.correctedByUserLabel),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
          TextButton(onPressed: onClearError, child: Text(s.closeMessage)),
        ],
        const SizedBox(height: 20),
        if (showVehicle) ...[
          Text(
            s.vehicleInformationSection,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ScanDetailVehicleInfoCard(s: s, info: scan.effectiveVehicleInfo!),
          if (scan.userCorrection != null && scan.vehicleInfo != null) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                s.originalAiResult,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              children: [
                ScanDetailVehicleInfoCard(s: s, info: scan.vehicleInfo!),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
        Text(s.locationPrefix, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(locationLabel, style: Theme.of(context).textTheme.bodyMedium),
        if (synced)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              s.syncedToCloud,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.primary),
            ),
          ),
        const SizedBox(height: 20),
        if (!synced && scan.status == VehicleScanStatus.waitingForRecognition)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              s.syncBeforeAiHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        if (canAnalyze) ...[
          Text(s.analyzeWithAi, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy ? null : onAnalyze,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(s.analyzeWithAi),
          ),
        ],
        if (scan.status == VehicleScanStatus.failed) ...[
          const SizedBox(height: 16),
          Text(
            s.recognitionFailedTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 6),
          Text(
            s.recognitionFailedNoDetails,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (synced) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: busy ? null : onAnalyze,
              child: Text(s.tryAgain),
            ),
          ],
        ],
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: busy ? null : onTogglePublic,
          child: Text(scan.isPublic ? s.setPrivate : s.setPublic),
        ),
        if (scan.status == VehicleScanStatus.recognized ||
            scan.status == VehicleScanStatus.failed) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: busy ? null : onOpenCorrection,
            icon: const Icon(Icons.edit_outlined),
            label: Text(s.correctResult),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: busy ? null : onDeleteTap,
          child: Text(s.deleteScan),
        ),
      ],
    );
  }
}
