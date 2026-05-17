import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/locale/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../scan/domain/vehicle_info.dart';
import '../../../scan/domain/vehicle_scan.dart';
import '../../../scan/domain/vehicle_scan_status.dart';
import '../../../scan/presentation/widgets/scan_image_display.dart';
import '../../../scan/presentation/widgets/scan_status_badge.dart';

/// Karta historii — większe zdjęcie, gradient, hierarchia premium.
class PremiumHistoryScanCard extends StatelessWidget {
  const PremiumHistoryScanCard({
    required this.s,
    required this.scan,
    super.key,
  });

  final AppStrings s;
  final VehicleScan scan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = scan.effectiveVehicleInfo;
    final title = _vehicleTitle(info, s);
    final meta = _vehicleMeta(info, scan);
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(scan.createdAt.toLocal());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 148,
        child: Row(
          children: [
            SizedBox(
              width: 128,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ScanImageDisplay(
                    heroTag: ScanImageDisplay.heroTagFor(scan.id),
                    localImagePath: scan.localImagePath,
                    remoteImageUrl: scan.remoteImageUrl,
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.cardOverlay,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (info != null &&
                            scan.status == VehicleScanStatus.recognized &&
                            info.confidence != null)
                          _ConfidenceBadge(
                            value: (info.confidence! * 100).round(),
                          ),
                      ],
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (info != null)
                          _TypeChip(
                            label: s
                                .vehicleType(info.vehicleType)
                                .toUpperCase(),
                          ),
                        if (scan.status == VehicleScanStatus.recognized &&
                            info != null)
                          _VerifiedChip(label: s.historyAiVerifiedBadge),
                        ScanStatusBadge(
                          status: scan.status,
                          label: s.scanStatus(scan.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date,
                      style: AppTextStyles.telemetry(
                        context,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _vehicleTitle(VehicleInfo? info, AppStrings s) {
    if (info == null) {
      return s.historyVehicleSummary(s.scanStatus(scan.status));
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

  String? _vehicleMeta(VehicleInfo? info, VehicleScan scan) {
    if (info == null) {
      return scan.location.city ?? scan.location.displayName;
    }
    final years = info.productionYears?.trim();
    final type = s.vehicleType(info.vehicleType);
    if (years != null && years.isNotEmpty) {
      return '$years • $type';
    }
    return type;
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$value%',
        style: AppTextStyles.badge(context).copyWith(color: AppColors.primaryRed),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(label, style: AppTextStyles.badge(context)),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.successForeground.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.badge(
          context,
        ).copyWith(color: AppColors.successForeground),
      ),
    );
  }
}
