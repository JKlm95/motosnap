import 'package:flutter/material.dart';

import '../../../../core/locale/app_strings.dart';
import '../../domain/vehicle_info.dart';

/// Karta pól pojazdu (AI lub efektywne po korekcie).
class ScanDetailVehicleInfoCard extends StatelessWidget {
  const ScanDetailVehicleInfoCard({
    required this.s,
    required this.info,
    super.key,
  });

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
