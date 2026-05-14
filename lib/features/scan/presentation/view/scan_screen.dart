import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/vehicle_scan.dart';
import '../cubit/scan_cubit.dart';
import '../cubit/scan_state.dart';
import '../scan_labels.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanCubit, ScanState>(
      builder: (context, state) {
        final busy =
            state.phase == ScanFlowPhase.requestingPermissions ||
            state.phase == ScanFlowPhase.capturing ||
            state.phase == ScanFlowPhase.saving;

        return Scaffold(
          appBar: AppBar(title: const Text('Skan')),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Zrób zdjęcie z aparatu. Lokalizacja GPS jest wymagana — bez niej skan nie zostanie zapisany.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 20),
                if (state.phase == ScanFlowPhase.success &&
                    state.savedScan != null)
                  _SuccessCard(scan: state.savedScan!)
                else if (state.errorMessage != null)
                  _ErrorCard(
                    message: state.errorMessage!,
                    onDismiss: () => context.read<ScanCubit>().clearTransient(),
                  ),
                if (state.phase == ScanFlowPhase.success ||
                    state.errorMessage != null)
                  const SizedBox(height: 16),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: busy
                        ? null
                        : () => context.read<ScanCubit>().captureAndSaveScan(),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Skanuj'),
                  ),
                ),
                if (state.phase == ScanFlowPhase.success) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.read<ScanCubit>().clearTransient(),
                    child: const Text('Kolejny skan'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.scan});

  final VehicleScan scan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zapisano lokalnie',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Status: ${scan.status.labelPl}'),
            const SizedBox(height: 6),
            Text(
              'Rozpoznanie AI nie zostało jeszcze uruchomione — to tylko lokalny rekord.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onDismiss, child: const Text('OK')),
            ),
          ],
        ),
      ),
    );
  }
}
