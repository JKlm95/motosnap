import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/vehicle_scan.dart';
import '../scan_labels.dart';
import 'scan_detail_cubit.dart';
import 'scan_detail_state.dart';

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

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
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
            if (scan.vehicleInfo != null) ...[
              const SizedBox(height: 16),
              Text(
                'Dane pojazdu',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                [
                  scan.vehicleInfo!.brand,
                  scan.vehicleInfo!.model,
                ].whereType<String>().where((e) => e.isNotEmpty).join(' '),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                'Rozpoznanie: oczekuje (brak danych z AI).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (scan.recognitionError != null) ...[
              const SizedBox(height: 12),
              Text(
                'Błąd rozpoznania: ${scan.recognitionError}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
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
