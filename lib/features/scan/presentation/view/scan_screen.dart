import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/scan_cubit.dart';
import '../cubit/scan_state.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanCubit, ScanState>(
      listenWhen: (prev, next) =>
          prev.userMessage != next.userMessage && next.userMessage != null,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.userMessage == null) return;
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(state.userMessage!)));
        if (state.status == ScanUiStatus.error) {
          context.read<ScanCubit>().acknowledgeMessage();
        }
      },
      builder: (context, state) {
        final busy = state.status == ScanUiStatus.working;
        return Scaffold(
          appBar: AppBar(title: const Text('Skan')),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Zrób zdjęcie pojazdu. Lokalizacja GPS jest wymagana do zapisu skanu.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 56,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => context.read<ScanCubit>().captureAndSaveScan(),
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(busy ? 'Zapisywanie…' : 'Zrób zdjęcie'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
