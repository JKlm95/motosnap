import 'package:flutter/material.dart';

import '../../core/haptics/app_haptics.dart';
import '../../core/ui/app_motion.dart';
import '../../core/ui/app_shape.dart';
import '../../core/ui/glass/glass_bottom_bar.dart';

/// Pływająca nawigacja shell (History | Scan | Settings) — indeksy gałęzi go_router:
/// 0 = skan, 1 = historia, 2 = ustawienia. Wizualnie środek to skan.
class GlassShellBottomNav extends StatelessWidget {
  const GlassShellBottomNav({
    required this.currentBranchIndex,
    required this.onBranchSelected,
    required this.historyLabel,
    required this.scanLabel,
    required this.settingsLabel,
    super.key,
  });

  final int currentBranchIndex;
  final ValueChanged<int> onBranchSelected;
  final String historyLabel;
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
    final scheme = Theme.of(context).colorScheme;
    final idx = currentBranchIndex;

    return Semantics(
      container: true,
      label: 'Navigation',
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SizedBox(
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              GlassBottomBar(
                blurSigma: AppShape.blurNavBar,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _SideNavItem(
                        icon: Icons.history_rounded,
                        label: historyLabel,
                        selected: idx == 1,
                        onTap: () => _select(1),
                        semanticLabel: historyLabel,
                      ),
                    ),
                    const SizedBox(width: 72),
                    Expanded(
                      child: _SideNavItem(
                        icon: Icons.tune_rounded,
                        label: settingsLabel,
                        selected: idx == 2,
                        onTap: () => _select(2),
                        semanticLabel: settingsLabel,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -14,
                child: _CenterScanFab(
                  label: scanLabel,
                  selected: idx == 0,
                  onTap: () => _select(0),
                  scheme: scheme,
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasizedDecelerate,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? scheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: AnimatedScale(
            scale: selected ? 1.02 : 1,
            duration: AppMotion.fast,
            curve: AppMotion.emphasizedDecelerate,
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0.72,
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: selected ? scheme.primary : scheme.onSurface,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
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
    required this.scheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

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
            scale: selected ? 1.08 : 1,
            duration: AppMotion.normal,
            curve: AppMotion.emphasizedDecelerate,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassBottomBar(
                  blurSigma: AppShape.blurNavFab,
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.35),
                          scheme.primary.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      color: scheme.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
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
