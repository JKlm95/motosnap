import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/main_shell_layout.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/scan_map_item.dart';
import '../cubit/scan_map_cubit.dart';
import '../cubit/scan_map_state.dart';
import '../widgets/scan_map_marker.dart';
import '../widgets/scan_map_preview_card.dart';

/// Prywatna mapa lokalnych skanów użytkownika (OpenStreetMap, bez API key).
class ScanMapScreen extends StatefulWidget {
  const ScanMapScreen({super.key});

  @override
  State<ScanMapScreen> createState() => _ScanMapScreenState();
}

class _ScanMapScreenState extends State<ScanMapScreen> {
  final MapController _mapController = MapController();
  bool _didFitBounds = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _maybeFitBounds(List<ScanMapItem> items) {
    if (_didFitBounds || items.isEmpty) {
      return;
    }
    _didFitBounds = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || items.isEmpty) {
        return;
      }
      if (items.length == 1) {
        final p = items.first;
        _mapController.move(LatLng(p.latitude, p.longitude), 14);
        return;
      }
      final bounds = LatLngBounds.fromPoints(
        items.map((i) => LatLng(i.latitude, i.longitude)).toList(),
      );
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bottomPad = MainShellLayout.paddingOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.mapTitle)),
      body: BlocConsumer<ScanMapCubit, ScanMapState>(
        listenWhen: (prev, next) =>
            prev.items.length != next.items.length && next.items.isNotEmpty,
        listener: (context, state) => _maybeFitBounds(state.items),
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.isEmpty) {
            return _ScanMapEmpty(s: s);
          }

          _maybeFitBounds(state.items);
          final selectedId = state.selectedScanId;
          final markers = state.items
              .map(
                (item) => Marker(
                  point: LatLng(item.latitude, item.longitude),
                  width: 32,
                  height: 32,
                  child: GestureDetector(
                    onTap: () {
                      AppHaptics.selection();
                      context.read<ScanMapCubit>().selectMarker(item.scanId);
                    },
                    child: ScanMapMarker(
                      status: item.status,
                      selected: item.scanId == selectedId,
                    ),
                  ),
                ),
              )
              .toList();

          final initial = state.items.first;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(initial.latitude, initial.longitude),
                  initialZoom: 12,
                  onTap: (_, _) =>
                      context.read<ScanMapCubit>().clearSelection(),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.motosnap.motosnap',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomPad + AppSpacing.md,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: state.selectedItem == null
                      ? const SizedBox.shrink()
                      : Padding(
                          key: ValueKey(state.selectedItem!.scanId),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: ScanMapPreviewCard(
                            s: s,
                            item: state.selectedItem!,
                            onClose: () =>
                                context.read<ScanMapCubit>().clearSelection(),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScanMapEmpty extends StatelessWidget {
  const _ScanMapEmpty({required this.s});

  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 42,
              color: scheme.onSurface.withValues(alpha: 0.32),
            ),
            const SizedBox(height: 16),
            Text(
              s.mapEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              s.mapEmptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () {
                AppHaptics.selection();
                context.go(AppRoutes.scanRelative);
              },
              child: Text(s.mapEmptyCta),
            ),
          ],
        ),
      ),
    );
  }
}
