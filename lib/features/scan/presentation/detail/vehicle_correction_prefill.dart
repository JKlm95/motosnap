import '../../domain/vehicle_scan.dart';
import '../../domain/vehicle_type.dart';

/// Wartości początkowe formularza korekty — logika współdzielona z UI i testami.
abstract final class VehicleCorrectionPrefill {
  static VehicleType vehicleType(VehicleScan scan) {
    final uc = scan.userCorrection;
    final eff = scan.effectiveVehicleInfo;
    final ai = scan.vehicleInfo;
    return uc?.vehicleType ??
        eff?.vehicleType ??
        ai?.vehicleType ??
        VehicleType.unknown;
  }

  static String brand(VehicleScan scan) =>
      scan.effectiveVehicleInfo?.brand ??
      scan.userCorrection?.brand ??
      scan.vehicleInfo?.brand ??
      '';

  static String model(VehicleScan scan) =>
      scan.effectiveVehicleInfo?.model ??
      scan.userCorrection?.model ??
      scan.vehicleInfo?.model ??
      '';

  static String generation(VehicleScan scan) =>
      scan.effectiveVehicleInfo?.generation ??
      scan.userCorrection?.generation ??
      scan.vehicleInfo?.generation ??
      '';

  static String productionYears(VehicleScan scan) =>
      scan.effectiveVehicleInfo?.productionYears ??
      scan.userCorrection?.productionYears ??
      scan.vehicleInfo?.productionYears ??
      '';

  static List<String> possibleEngines(VehicleScan scan) {
    final eff = scan.effectiveVehicleInfo?.possibleEngines;
    if (eff != null && eff.isNotEmpty) {
      return eff;
    }
    final uc = scan.userCorrection?.possibleEngines;
    if (uc != null && uc.isNotEmpty) {
      return uc;
    }
    return scan.vehicleInfo?.possibleEngines ?? const <String>[];
  }

  static String shortDescription(VehicleScan scan) =>
      scan.effectiveVehicleInfo?.shortDescription ??
      scan.userCorrection?.shortDescription ??
      scan.vehicleInfo?.shortDescription ??
      '';
}
