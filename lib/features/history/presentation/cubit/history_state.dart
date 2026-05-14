import 'package:equatable/equatable.dart';

import '../../domain/history_list_query.dart';
import '../../../scan/domain/vehicle_scan.dart';

class HistoryState extends Equatable {
  const HistoryState({
    this.isLoading = true,
    this.scans = const <VehicleScan>[],
    this.errorMessage,
    this.filter = HistoryFilter.all,
    this.sort = HistorySort.newest,
    this.listAnimationEpoch = 0,
    this.retryingScanId,
    this.transientSnackMessage,
  });

  final bool isLoading;
  final List<VehicleScan> scans;
  final String? errorMessage;
  final HistoryFilter filter;
  final HistorySort sort;

  /// Inkrementacja przy zmianie filtra/sortu lub pełnym odświeżeniu — wyzwala animację wejścia kafelków.
  final int listAnimationEpoch;
  final String? retryingScanId;
  final String? transientSnackMessage;

  List<VehicleScan> get visibleScans =>
      applyHistoryFilterSort(scans, filter, sort);

  HistoryState copyWith({
    bool? isLoading,
    List<VehicleScan>? scans,
    String? errorMessage,
    bool clearErrorMessage = false,
    HistoryFilter? filter,
    HistorySort? sort,
    int? listAnimationEpoch,
    String? retryingScanId,
    bool clearRetryingScanId = false,
    String? transientSnackMessage,
    bool clearTransientSnack = false,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      scans: scans ?? this.scans,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      listAnimationEpoch: listAnimationEpoch ?? this.listAnimationEpoch,
      retryingScanId: clearRetryingScanId
          ? null
          : (retryingScanId ?? this.retryingScanId),
      transientSnackMessage: clearTransientSnack
          ? null
          : (transientSnackMessage ?? this.transientSnackMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    scans,
    errorMessage,
    filter,
    sort,
    listAnimationEpoch,
    retryingScanId,
    transientSnackMessage,
  ];
}
