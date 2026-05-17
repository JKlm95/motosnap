import 'package:flutter/material.dart';

import '../../../../core/locale/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/vehicle_scan.dart';
import '../../domain/vehicle_scan_status.dart';
import '../widgets/scan_status_badge.dart';
import 'scan_detail_ai_skeleton.dart';
import 'scan_detail_vehicle_info_card.dart';
import 'scan_detail_vehicle_reveal_card.dart';

/// Treść przewijanego panelu szczegółów skanu (sekcje + akcje).
class ScanDetailSheetContent extends StatelessWidget {
  const ScanDetailSheetContent({
    required this.scan,
    required this.s,
    required this.busy,
    required this.showAiSkeleton,
    required this.vehicleRevealToken,
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
  final bool showAiSkeleton;
  final int vehicleRevealToken;
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
    final theme = Theme.of(context).textTheme;
    final locationLabel =
        scan.location.displayName ??
        '${scan.location.latitude.toStringAsFixed(4)}, '
            '${scan.location.longitude.toStringAsFixed(4)}';

    final showVehicleData =
        (scan.status == VehicleScanStatus.recognized ||
            scan.status == VehicleScanStatus.failed) &&
        scan.effectiveVehicleInfo != null;

    final useReveal =
        vehicleRevealToken > 0 && showVehicleData && !showAiSkeleton;

    final title = _vehicleProfileTitle(scan, s);

    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        4,
        AppSpacing.screenH,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (title != null) ...[
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.headlineSmall,
          ),
          const SizedBox(height: 6),
        ],
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
          const SizedBox(height: AppSpacing.md),
          Text(
            errorMessage!,
            style: theme.bodySmall?.copyWith(color: scheme.error),
          ),
          TextButton(onPressed: onClearError, child: Text(s.closeMessage)),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (showAiSkeleton) ...[
          _SectionHeader(title: s.aiAnalysisSection),
          const SizedBox(height: AppSpacing.xs),
          const ScanDetailAiResultSkeleton(),
          const SizedBox(height: AppSpacing.sectionGap),
        ] else if (showVehicleData) ...[
          _SectionHeader(title: s.vehicleDnaSection),
          const SizedBox(height: AppSpacing.xs),
          if (useReveal)
            ScanDetailVehicleRevealCard(
              s: s,
              info: scan.effectiveVehicleInfo!,
              revealToken: vehicleRevealToken,
            )
          else
            ScanDetailVehicleInfoCard(s: s, info: scan.effectiveVehicleInfo!),
          if (scan.userCorrection != null && scan.vehicleInfo != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(s.originalAiResult, style: theme.titleSmall),
              children: [
                ScanDetailVehicleInfoCard(s: s, info: scan.vehicleInfo!),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        _SectionHeader(title: s.recognitionInfoSection),
        const SizedBox(height: AppSpacing.xs),
        Text(s.locationPrefix, style: theme.labelLarge),
        const SizedBox(height: 6),
        Text(locationLabel, style: theme.bodyMedium),
        if (synced)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              s.syncedToCloud,
              style: theme.bodySmall?.copyWith(color: AppColors.primaryRed),
            ),
          ),
        const SizedBox(height: AppSpacing.sectionGap),
        if (!synced && scan.status == VehicleScanStatus.waitingForRecognition)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(s.syncBeforeAiHint, style: theme.bodyMedium),
          ),
        if (canAnalyze && !showAiSkeleton) ...[
          _SectionHeader(title: s.aiAnalysisSection),
          const SizedBox(height: AppSpacing.xs),
          FilledButton.icon(
            onPressed: busy ? null : onAnalyze,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(s.analyzeWithAi),
          ),
        ],
        if (scan.status == VehicleScanStatus.failed) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            s.recognitionFailedTitle,
            style: theme.titleSmall?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 6),
          Text(s.recognitionFailedNoDetails, style: theme.bodySmall),
          if (synced && !showAiSkeleton) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonal(
              onPressed: busy ? null : onAnalyze,
              child: Text(s.tryAgain),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton.tonal(
          onPressed: busy ? null : onTogglePublic,
          child: Text(scan.isPublic ? s.setPrivate : s.setPublic),
        ),
        if (scan.status == VehicleScanStatus.recognized ||
            scan.status == VehicleScanStatus.failed) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: busy ? null : onOpenCorrection,
            child: Text(s.correctResult),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: busy ? null : onDeleteTap,
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          child: Text(s.deleteScan),
        ),
      ],
    );
  }

  String? _vehicleProfileTitle(VehicleScan scan, AppStrings s) {
    final info = scan.effectiveVehicleInfo;
    if (info == null) {
      return null;
    }
    final brand = info.brand?.trim() ?? '';
    final model = info.model?.trim() ?? '';
    if (brand.isNotEmpty && model.isNotEmpty) {
      return '$brand $model';
    }
    if (brand.isNotEmpty) {
      return brand;
    }
    if (model.isNotEmpty) {
      return model;
    }
    return s.vehicleType(info.vehicleType);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
