import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../scan/domain/vehicle_scan.dart';
import '../cubit/history_cubit.dart';
import '../cubit/history_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historia')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return _Error(message: state.errorMessage!);
          }
          if (state.scans.isEmpty) {
            return const _Empty();
          }
          return RefreshIndicator(
            onRefresh: () => context.read<HistoryCubit>().load(),
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
      child: Text(
        'Brak zapisanych skanów.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
    final date = DateFormat.yMMMd().add_Hm().format(scan.capturedAt.toLocal());
    return Card(
      child: ListTile(
        title: Text(date),
        subtitle: Text(
          '${scan.latitude.toStringAsFixed(5)}, ${scan.longitude.toStringAsFixed(5)}',
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
