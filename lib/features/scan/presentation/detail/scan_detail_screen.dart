import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/user_vehicle_correction.dart';
import '../../domain/vehicle_info.dart';
import '../../domain/vehicle_scan.dart';
import '../../domain/vehicle_scan_status.dart';
import '../../domain/vehicle_type.dart';
import '../scan_labels.dart';
import 'scan_detail_cubit.dart';
import 'scan_detail_state.dart';
import 'vehicle_user_correction_sheet.dart';

class ScanDetailScreen extends StatelessWidget {
  const ScanDetailScreen({required this.scanId, super.key});

  final String scanId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanDetailCubit, ScanDetailState>(
      listenWhen: (prev, next) =>
          prev.phase != next.phase && next.phase == ScanDetailPhase.removed,
      listener: (context, state) {
        if (context.mounted) {
          context.pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Szczegóły skanu')),
          body: switch (state.phase) {
            ScanDetailPhase.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ScanDetailPhase.notFound => const _NotFound(),
            ScanDetailPhase.removed => const SizedBox.shrink(),
            ScanDetailPhase.ready => _DetailBody(
              scan: state.scan!,
              busy: state.busy,
              errorMessage: state.errorMessage,
            ),
          },
        );
      },
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nie znaleziono skanu.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Wróć'),
            ),
          ],
        ),
      ),
    );
  }
}

String _vehicleTypeLabelPl(VehicleType? t) {
  if (t == null) {
    return '—';
  }
  return switch (t) {
    VehicleType.car => 'Samochód osobowy',
    VehicleType.motorcycle => 'Motocykl',
    VehicleType.truck => 'Ciężarówka',
    VehicleType.bus => 'Autobus',
    VehicleType.van => 'Van / dostawczy',
    VehicleType.aircraft => 'Statek powietrzny',
    VehicleType.boat => 'Łódź / statek',
    VehicleType.train => 'Pociąg / szynowy',
    VehicleType.agricultural => 'Rolniczy',
    VehicleType.construction => 'Budowlany',
    VehicleType.military => 'Wojskowy',
    VehicleType.emergency => 'Służby ratunkowe',
    VehicleType.bicycle => 'Rower',
    VehicleType.scooter => 'Hulajnoga / skuter',
    VehicleType.other => 'Inny',
    VehicleType.unknown => 'Nieznany',
  };
}

bool _isSyncedToCloud(VehicleScan scan) {
  return !scan.pendingSync &&
      (scan.remoteImageUrl != null && scan.remoteImageUrl!.isNotEmpty);
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.scan,
    required this.busy,
    required this.errorMessage,
  });

  final VehicleScan scan;
  final bool busy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final file = File(scan.localImagePath);
    final locationLabel =
        scan.location.displayName ??
        '${scan.location.latitude.toStringAsFixed(4)}, '
            '${scan.location.longitude.toStringAsFixed(4)}';

    final synced = _isSyncedToCloud(scan);
    final canAnalyze =
        scan.status == VehicleScanStatus.waitingForRecognition && synced;
    final localeLang = Localizations.localeOf(context).languageCode;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 200),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: file.existsSync()
                    ? Image.file(file, fit: BoxFit.cover)
                    : ColoredBox(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              scan.status.labelPl,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Lokalizacja: $locationLabel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (synced)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Zsynchronizowano z chmurą',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            if (!synced &&
                scan.status == VehicleScanStatus.waitingForRecognition) ...[
              const SizedBox(height: 16),
              Text(
                'Zsynchronizuj skan przed analizą AI (Ustawienia → Synchronizuj teraz).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
            if (canAnalyze) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () => context.read<ScanDetailCubit>().runAiAnalysis(
                        localeLang,
                      ),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Analizuj przez AI'),
              ),
            ],
            if (scan.status == VehicleScanStatus.recognized ||
                scan.status == VehicleScanStatus.failed) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => showVehicleUserCorrectionSheet(
                        context: context,
                        scan: scan,
                        onSave: (UserVehicleCorrection c) => context
                            .read<ScanDetailCubit>()
                            .saveUserCorrection(c),
                      ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Popraw wynik'),
              ),
            ],
            if ((scan.status == VehicleScanStatus.recognized ||
                    scan.status == VehicleScanStatus.failed) &&
                scan.effectiveVehicleInfo != null) ...[
              const SizedBox(height: 20),
              if (scan.userCorrection != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Poprawione przez użytkownika',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                scan.status == VehicleScanStatus.recognized
                    ? 'Rozpoznanie'
                    : 'Dane pojazdu (korekta / ostatnia znana)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _VehicleInfoCard(info: scan.effectiveVehicleInfo!),
              if (scan.userCorrection != null && scan.vehicleInfo != null) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Oryginalny wynik AI',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  children: [_VehicleInfoCard(info: scan.vehicleInfo!)],
                ),
              ],
            ],
            if (scan.status == VehicleScanStatus.failed) ...[
              const SizedBox(height: 16),
              Text(
                'Rozpoznanie nie powiodło się.',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              if (scan.recognitionError != null) ...[
                const SizedBox(height: 6),
                Text(
                  scan.recognitionError!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (synced) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: busy
                      ? null
                      : () => context.read<ScanDetailCubit>().runAiAnalysis(
                          localeLang,
                        ),
                  child: const Text('Spróbuj ponownie'),
                ),
              ],
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              TextButton(
                onPressed: () => context.read<ScanDetailCubit>().clearError(),
                child: const Text('Zamknij komunikat'),
              ),
            ],
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.tonal(
                onPressed: busy
                    ? null
                    : () => context.read<ScanDetailCubit>().togglePublic(),
                child: Text(
                  scan.isPublic
                      ? 'Ustaw jako prywatny'
                      : 'Ustaw jako publiczny',
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Usunąć skan?'),
                            content: const Text(
                              'Zdjęcie i rekord zostaną usunięte z tego urządzenia.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Anuluj'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Usuń'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await context.read<ScanDetailCubit>().delete();
                        }
                      },
                child: const Text('Usuń skan'),
              ),
            ],
          ),
        ),
        if (busy)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _VehicleInfoCard extends StatelessWidget {
  const _VehicleInfoCard({required this.info});

  final VehicleInfo info;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(context, 'Typ', _vehicleTypeLabelPl(info.vehicleType)),
            _row(context, 'Marka', info.brand ?? '—'),
            _row(context, 'Model', info.model ?? '—'),
            _row(context, 'Generacja', info.generation ?? '—'),
            _row(context, 'Lata produkcji', info.productionYears ?? '—'),
            if (info.possibleEngines.isNotEmpty)
              _row(
                context,
                'Silniki (propozycje)',
                info.possibleEngines.join(', '),
              ),
            _row(
              context,
              'Pewność',
              info.confidence != null
                  ? '${(info.confidence! * 100).toStringAsFixed(0)} %'
                  : '—',
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
