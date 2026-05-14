import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/scan/domain/scan_location.dart';
import 'package:motosnap/features/scan/domain/user_vehicle_correction.dart';
import 'package:motosnap/features/scan/domain/vehicle_info.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan.dart';
import 'package:motosnap/features/scan/domain/vehicle_scan_status.dart';
import 'package:motosnap/features/scan/domain/vehicle_type.dart';
import 'package:motosnap/features/scan/presentation/detail/vehicle_correction_prefill.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 1);

  VehicleScan scanWith({VehicleInfo? ai, UserVehicleCorrection? correction}) {
    return VehicleScan(
      id: 'x',
      localImagePath: '/p.jpg',
      createdAt: t0,
      updatedAt: t0,
      status: VehicleScanStatus.recognized,
      location: const ScanLocation(latitude: 0, longitude: 0),
      vehicleInfo: ai,
      userCorrection: correction,
      pendingSync: false,
    );
  }

  test('prefill: effective (AI) gdy brak korekty', () {
    final scan = scanWith(
      ai: const VehicleInfo(
        vehicleType: VehicleType.motorcycle,
        brand: 'Yamaha',
        model: 'MT',
      ),
    );
    expect(VehicleCorrectionPrefill.vehicleType(scan), VehicleType.motorcycle);
    expect(VehicleCorrectionPrefill.brand(scan), 'Yamaha');
    expect(VehicleCorrectionPrefill.model(scan), 'MT');
  });

  test('prefill: korekta nadpisuje typ względem baseline AI', () {
    final scan = scanWith(
      ai: const VehicleInfo(vehicleType: VehicleType.car, brand: 'AI'),
      correction: UserVehicleCorrection(
        vehicleType: VehicleType.truck,
        brand: 'User',
        correctedAt: DateTime.utc(2026, 5, 2),
      ),
    );
    expect(VehicleCorrectionPrefill.vehicleType(scan), VehicleType.truck);
    expect(VehicleCorrectionPrefill.brand(scan), 'User');
  });
}
