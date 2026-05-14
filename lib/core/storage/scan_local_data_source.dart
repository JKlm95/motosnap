import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../features/scan/domain/vehicle_scan.dart';

/// Lokalny cache skanów: Hive + JSON modelu [VehicleScan].
/// Wybrano Hive zamiast Isar: lżejszy stack na MVP, prosty zapis JSON bez drugiego
/// generatora schematu (Isar + json_serializable bywa problematyczny w tooling).
class ScanLocalDataSource {
  ScanLocalDataSource(this._box);

  static const boxName = 'vehicle_scans_json';

  final Box<String> _box;

  static Future<ScanLocalDataSource> open() async {
    final box = await Hive.openBox<String>(boxName);
    return ScanLocalDataSource(box);
  }

  List<VehicleScan> readAllOrdered() {
    final items =
        _box.values
            .map(
              (raw) =>
                  VehicleScan.fromJson(jsonDecode(raw) as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return items;
  }

  Future<void> upsert(VehicleScan scan) async {
    await _box.put(scan.id, jsonEncode(scan.toJson()));
  }

  Future<void> clear() => _box.clear();
}
