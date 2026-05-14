import 'package:flutter/material.dart';

import 'glass_surface.dart';

/// Mały okrągły przycisk szklany (np. boczne ikony nawigacji).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    super.key,
    this.selected = false,
    this.blurSigma = 10,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final bool selected;
  final double blurSigma;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                GlassSurface(
                  blurSigma: blurSigma,
                  borderRadius: BorderRadius.circular(size / 2),
                  padding: EdgeInsets.zero,
                  child: SizedBox(width: size, height: size),
                ),
                if (selected)
                  Container(
                    width: size - 6,
                    height: size - 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                Icon(
                  icon,
                  size: 22,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
