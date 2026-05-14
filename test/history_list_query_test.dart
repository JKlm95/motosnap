import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/history/domain/history_list_query.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);
  final t1 = DateTime.utc(2026, 1, 2);

  VehicleScan mk({
    required String id,
    required VehicleScanStatus status,
    DateTime? createdAt,
    VehicleInfo? vehicleInfo,
    UserVehicleCorrection? userCorrection,
    bool isPublic = false,
    bool pendingSync = true,
    String? remoteUrl,
  }) {
    return VehicleScan(
      id: id,
      localImagePath: '/$id.jpg',
      remoteImageUrl: remoteUrl,
      createdAt: createdAt ?? t0,
      updatedAt: createdAt ?? t0,
      status: status,
      location: const ScanLocation(latitude: 0, longitude: 0),
      vehicleInfo: vehicleInfo,
      userCorrection: userCorrection,
      isPublic: isPublic,
      pendingSync: pendingSync,
    );
  }

  group('isHistoryScanSyncedToCloud', () {
    test('false gdy pendingSync', () {
      final s = mk(
        id: 'a',
        status: VehicleScanStatus.failed,
        pendingSync: true,
        remoteUrl: 'https://x/y',
      );
      expect(isHistoryScanSyncedToCloud(s), isFalse);
    });

    test('false gdy brak remote URL', () {
      final s = mk(
        id: 'a',
        status: VehicleScanStatus.failed,
        pendingSync: false,
        remoteUrl: null,
      );
      expect(isHistoryScanSyncedToCloud(s), isFalse);
    });

    test('true gdy zsynchronizowany i jest URL', () {
      final s = mk(
        id: 'a',
        status: VehicleScanStatus.failed,
        pendingSync: false,
        remoteUrl: 'https://x/y',
      );
      expect(isHistoryScanSyncedToCloud(s), isTrue);
    });
  });

  group('applyHistoryFilterSort', () {
    test('filter public', () {
      final scans = [
        mk(id: '1', status: VehicleScanStatus.recognized, isPublic: false),
        mk(id: '2', status: VehicleScanStatus.recognized, isPublic: true),
      ];
      final out = applyHistoryFilterSort(
        scans,
        HistoryFilter.public,
        HistorySort.newest,
      );
      expect(out.map((e) => e.id).toList(), ['2']);
    });

    test('filter corrected', () {
      final scans = [
        mk(id: '1', status: VehicleScanStatus.recognized),
        mk(
          id: '2',
          status: VehicleScanStatus.recognized,
          userCorrection: UserVehicleCorrection(
            vehicleType: VehicleType.car,
            brand: 'B',
            correctedAt: t1,
          ),
        ),
      ];
      final out = applyHistoryFilterSort(
        scans,
        HistoryFilter.corrected,
        HistorySort.newest,
      );
      expect(out.single.id, '2');
    });

    test('sort confidence — null na końcu', () {
      final scans = [
        mk(
          id: 'with',
          status: VehicleScanStatus.recognized,
          vehicleInfo: const VehicleInfo(
            vehicleType: VehicleType.car,
            confidence: 0.9,
          ),
        ),
        mk(id: 'null', status: VehicleScanStatus.recognized),
      ];
      final out = applyHistoryFilterSort(
        scans,
        HistoryFilter.all,
        HistorySort.confidence,
      );
      expect(out.map((e) => e.id).toList(), ['with', 'null']);
    });

    test('sort brand — effective z korekty', () {
      final scans = [
        mk(
          id: 'z',
          status: VehicleScanStatus.recognized,
          vehicleInfo: const VehicleInfo(
            vehicleType: VehicleType.car,
            brand: 'Zebra',
          ),
        ),
        mk(
          id: 'a',
          status: VehicleScanStatus.recognized,
          vehicleInfo: const VehicleInfo(
            vehicleType: VehicleType.car,
            brand: 'Zebra',
          ),
          userCorrection: UserVehicleCorrection(
            vehicleType: VehicleType.car,
            brand: 'Acura',
            correctedAt: t1,
          ),
        ),
      ];
      final out = applyHistoryFilterSort(
        scans,
        HistoryFilter.all,
        HistorySort.brand,
      );
      expect(out.map((e) => e.id).toList(), ['a', 'z']);
    });
  });
}
