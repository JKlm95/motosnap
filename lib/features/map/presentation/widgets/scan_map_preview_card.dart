import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/cinematic_thumbnail.dart';
import '../../../scan/presentation/widgets/scan_image_display.dart';
import '../../../scan/presentation/widgets/scan_status_badge.dart';
import '../../domain/scan_map_item.dart';

/// Podgląd skanu po wyborze markera — tap otwiera szczegóły.
class ScanMapPreviewCard extends StatelessWidget {
  const ScanMapPreviewCard({
    required this.s,
    required this.item,
    required this.onClose,
    super.key,
  });

  final AppStrings s;
  final ScanMapItem item;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(
      locale,
    ).add_jm().format(item.createdAt.toLocal());
    final title = item.title ?? s.mapScanUntitled;
    final typeLabel = item.vehicleType != null
        ? s.vehicleType(item.vehicleType)
        : null;

    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      color: AppColors.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          context.push(AppRoutes.vehicleScan(item.scanId));
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: CinematicThumbnail.frame(
                    context: context,
                    localImagePath: item.localImagePath,
                    remoteImageUrl: item.remoteImageUrl,
                    heroTag: ScanImageDisplay.heroTagFor(item.scanId),
                    width: 72,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    ScanStatusBadge(
                      status: item.status,
                      label: s.scanStatus(item.status),
                      dense: true,
                    ),
                    if (typeLabel != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
