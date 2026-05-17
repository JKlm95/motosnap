import 'package:flutter/material.dart';

import '../../core/haptics/app_haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_radius.dart';
import '../../core/ui/app_motion.dart';
import '../../core/ui/app_shape.dart';
import '../../core/ui/glass/glass_bottom_bar.dart';

/// Gałęzie shell: 0 Skan, 1 Historia, 2 Mapa, 3 Ustawienia.
///
/// Pływająca nawigacja: Historia | Mapa | [Skan FAB] | Ustawienia.
class GlassShellBottomNav extends StatelessWidget {
  const GlassShellBottomNav({
    required this.currentBranchIndex,
    required this.onBranchSelected,
    required this.historyLabel,
    required this.mapLabel,
    required this.scanLabel,
    required this.settingsLabel,
    super.key,
  });

  final int currentBranchIndex;
  final ValueChanged<int> onBranchSelected;
  final String historyLabel;
  final String mapLabel;
  final String scanLabel;
  final String settingsLabel;

  void _select(int branchIndex) {
    if (currentBranchIndex != branchIndex) {
      AppHaptics.selection();
    }
    onBranchSelected(branchIndex);
  }

  @override
  Widget build(BuildContext context) {
    final idx = currentBranchIndex;

    return Semantics(
      container: true,
      label: 'Navigation',
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          height: 78,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppEffects.navBar,
                ),
                child: GlassBottomBar(
                  blurSigma: AppShape.blurNavBar,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _SideNavItem(
                                icon: Icons.history_rounded,
                                label: historyLabel,
                                selected: idx == 1,
                                onTap: () => _select(1),
                                semanticLabel: historyLabel,
                                compact: true,
                              ),
                            ),
                            Expanded(
                              child: _SideNavItem(
                                icon: Icons.map_rounded,
                                label: mapLabel,
                                selected: idx == 2,
                                onTap: () => _select(2),
                                semanticLabel: mapLabel,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 72),
                      Expanded(
                        child: _SideNavItem(
                          icon: Icons.tune_rounded,
                          label: settingsLabel,
                          selected: idx == 3,
                          onTap: () => _select(3),
                          semanticLabel: settingsLabel,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -16,
                child: _CenterScanFab(
                  label: scanLabel,
                  selected: idx == 0,
                  onTap: () => _select(0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.semanticLabel,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppDurations.standard,
          padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: selected
                ? AppColors.primaryRed.withValues(alpha: 0.12)
                : Colors.transparent,
            border: selected
                ? Border.all(
                    color: AppColors.primaryRed.withValues(alpha: 0.35),
                  )
                : null,
          ),
          child: AnimatedOpacity(
            opacity: selected ? 1 : 0.7,
            duration: AppDurations.fast,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: compact ? 20 : 22,
                  color: selected
                      ? AppColors.primaryRed
                      : AppColors.textSecondary,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: compact ? 10 : null,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primaryRed
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterScanFab extends StatelessWidget {
  const _CenterScanFab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedScale(
            scale: selected ? 1.06 : 1,
            duration: AppMotion.normal,
            curve: AppMotion.emphasizedDecelerate,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryRed
                          : AppColors.divider,
                      width: selected ? 2.5 : 1.5,
                    ),
                    boxShadow: selected
                        ? AppEffects.shutterGlow()
                        : AppEffects.navBar,
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: selected
                        ? AppColors.primaryRed
                        : AppColors.textPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.primaryRed
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
