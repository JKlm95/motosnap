import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../scan/domain/vehicle_scan.dart';
import '../../../scan/domain/vehicle_scan_status.dart';
import '../../../scan/presentation/scan_labels.dart';
import '../cubit/history_cubit.dart';
import '../cubit/history_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia'),
        actions: [
          IconButton(
            tooltip: 'Odśwież',
            onPressed: () => context.read<HistoryCubit>().refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.scans.isEmpty) {
            return _Error(message: state.errorMessage!);
          }
          if (state.scans.isEmpty) {
            return const _Empty();
          }
          return RefreshIndicator(
            onRefresh: () => context.read<HistoryCubit>().refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.scans.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final scan = state.scans[index];
                return _ScanTile(scan: scan);
              },
            ),
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Brak zapisanych skanów.\nZrób pierwszy skan w zakładce „Skan”.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  const _ScanTile({required this.scan});

  final VehicleScan scan;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().add_Hm().format(scan.createdAt.toLocal());
    final locationLabel =
        scan.location.displayName ??
        scan.location.city ??
        '${scan.location.latitude.toStringAsFixed(3)}, '
            '${scan.location.longitude.toStringAsFixed(3)}';
    final thumb = File(scan.localImagePath);
    final recognition = scan.effectiveVehicleInfo == null
        ? 'Rozpoznanie oczekuje'
        : 'Dane pojazdu dostępne';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.vehicleScan(scan.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: thumb.existsSync()
                      ? Image.file(thumb, fit: BoxFit.cover)
                      : ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recognition,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(status: scan.status),
                  if (scan.isPublic)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Publiczny',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final VehicleScanStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      VehicleScanStatus.waitingForRecognition => Theme.of(
        context,
      ).colorScheme.secondaryContainer,
      VehicleScanStatus.recognized => Theme.of(
        context,
      ).colorScheme.primaryContainer,
      VehicleScanStatus.failed => Theme.of(context).colorScheme.errorContainer,
      VehicleScanStatus.draft => Theme.of(
        context,
      ).colorScheme.surfaceContainerHigh,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.labelPl,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
