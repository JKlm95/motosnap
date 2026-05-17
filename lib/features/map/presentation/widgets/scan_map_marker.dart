import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../scan/domain/vehicle_scan_status.dart';

/// Pin markera na mapie — kolor obramowania wg statusu AI.
class ScanMapMarker extends StatelessWidget {
  const ScanMapMarker({
    required this.status,
    required this.selected,
    super.key,
  });

  final VehicleScanStatus status;
  final bool selected;

  Color get _borderColor {
    return switch (status) {
      VehicleScanStatus.recognized => AppColors.success,
      VehicleScanStatus.waitingForRecognition => AppColors.warning,
      VehicleScanStatus.failed => AppColors.error,
      VehicleScanStatus.draft => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final border = selected ? 3.0 : 2.0;
    return Semantics(
      button: true,
      label: 'Scan marker',
      child: AnimatedScale(
        scale: selected ? 1.15 : 1,
        duration: const Duration(milliseconds: 180),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryRed,
            border: Border.all(color: _borderColor, width: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
