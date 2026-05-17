import 'package:equatable/equatable.dart';

import '../../domain/scan_map_item.dart';

class ScanMapState extends Equatable {
  const ScanMapState({
    this.items = const [],
    this.selectedScanId,
    this.isLoading = true,
  });

  final List<ScanMapItem> items;
  final String? selectedScanId;
  final bool isLoading;

  bool get isEmpty => !isLoading && items.isEmpty;

  ScanMapItem? get selectedItem {
    final id = selectedScanId;
    if (id == null) {
      return null;
    }
    for (final item in items) {
      if (item.scanId == id) {
        return item;
      }
    }
    return null;
  }

  ScanMapState copyWith({
    List<ScanMapItem>? items,
    String? selectedScanId,
    bool clearSelection = false,
    bool? isLoading,
  }) {
    return ScanMapState(
      items: items ?? this.items,
      selectedScanId: clearSelection
          ? null
          : (selectedScanId ?? this.selectedScanId),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [items, selectedScanId, isLoading];
}
