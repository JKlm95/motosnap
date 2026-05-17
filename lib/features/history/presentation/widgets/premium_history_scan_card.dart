import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/locale/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/ui/cinematic_thumbnail.dart';
import '../../../scan/domain/vehicle_info.dart';
import '../../../scan/domain/vehicle_scan.dart';
import '../../../scan/domain/vehicle_scan_status.dart';
import '../../../scan/presentation/widgets/scan_image_display.dart';
import '../../../scan/presentation/widgets/scan_status_badge.dart';

/// Karta historii — premium, responsywna, bez sztywnej wysokości (brak overflow).
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
    final compact = MediaQuery.sizeOf(context).width < 360;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final dense = compact || textScale > 1.12;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CinematicThumbnail.frame(
            context: context,
            localImagePath: scan.localImagePath,
            remoteImageUrl: scan.remoteImageUrl,
            heroTag: ScanImageDisplay.heroTagFor(scan.id),
            overlays: const [
              DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.cardOverlay),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                dense ? AppSpacing.sm : AppSpacing.cardPadding,
                dense ? AppSpacing.sm : AppSpacing.cardPadding,
                AppSpacing.cardPadding,
                dense ? AppSpacing.sm : AppSpacing.cardPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: dense ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (info != null &&
                          scan.status == VehicleScanStatus.recognized &&
                          info.confidence != null)
                        _ConfidenceBadge(
                          value: (info.confidence! * 100).round(),
                          compact: dense,
                        ),
                    ],
                  ),
                  if (meta != null) ...[
                    SizedBox(height: dense ? 2 : AppSpacing.xxs),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  SizedBox(height: dense ? AppSpacing.xs : AppSpacing.sm),
                  Wrap(
                    spacing: dense ? 4 : 6,
                    runSpacing: dense ? 4 : 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (info != null)
                        _TypeChip(
                          label: s.vehicleType(info.vehicleType).toUpperCase(),
                          compact: dense,
                        ),
                      if (scan.status == VehicleScanStatus.recognized &&
                          info != null)
                        _VerifiedChip(
                          label: dense
                              ? s.historyAiVerifiedShort
                              : s.historyAiVerifiedBadge,
                          compact: dense,
                        ),
                      ScanStatusBadge(
                        status: scan.status,
                        label: s.scanStatus(scan.status),
                        dense: dense,
                      ),
                    ],
                  ),
                  SizedBox(height: dense ? AppSpacing.xxs : 6),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  const _ConfidenceBadge({required this.value, this.compact = false});

  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.xs),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$value%',
        style: AppTextStyles.badge(
          context,
        ).copyWith(color: AppColors.primaryRed, fontSize: compact ? 9 : null),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.badge(
          context,
        ).copyWith(fontSize: compact ? 9 : null),
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.successForeground.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.badge(context).copyWith(
          color: AppColors.successForeground,
          fontSize: compact ? 9 : null,
        ),
      ),
    );
  }
}
