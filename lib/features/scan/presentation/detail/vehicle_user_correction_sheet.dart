import 'package:flutter/material.dart';

import '../../domain/user_vehicle_correction.dart';
import '../../domain/vehicle_scan.dart';
import '../../domain/vehicle_type.dart';

Future<void> showVehicleUserCorrectionSheet({
  required BuildContext context,
  required VehicleScan scan,
  required Future<void> Function(UserVehicleCorrection correction) onSave,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _VehicleUserCorrectionForm(scan: scan, onSave: onSave),
      );
    },
  );
}

class _VehicleUserCorrectionForm extends StatefulWidget {
  const _VehicleUserCorrectionForm({required this.scan, required this.onSave});

  final VehicleScan scan;
  final Future<void> Function(UserVehicleCorrection correction) onSave;

  @override
  State<_VehicleUserCorrectionForm> createState() =>
      _VehicleUserCorrectionFormState();
}

class _VehicleUserCorrectionFormState
    extends State<_VehicleUserCorrectionForm> {
  late VehicleType _type;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _generation;
  late final TextEditingController _years;
  late final TextEditingController _engines;
  late final TextEditingController _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final uc = widget.scan.userCorrection;
    final ai = widget.scan.vehicleInfo;
    _type = uc?.vehicleType ?? ai?.vehicleType ?? VehicleType.unknown;
    _brand = TextEditingController(text: uc?.brand ?? ai?.brand ?? '');
    _model = TextEditingController(text: uc?.model ?? ai?.model ?? '');
    _generation = TextEditingController(
      text: uc?.generation ?? ai?.generation ?? '',
    );
    _years = TextEditingController(
      text: uc?.productionYears ?? ai?.productionYears ?? '',
    );
    _engines = TextEditingController(
      text: (uc?.possibleEngines ?? ai?.possibleEngines ?? const <String>[])
          .join(', '),
    );
    _description = TextEditingController(
      text: uc?.shortDescription ?? ai?.shortDescription ?? '',
    );
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _generation.dispose();
    _years.dispose();
    _engines.dispose();
    _description.dispose();
    super.dispose();
  }

  UserVehicleCorrection _buildCorrection() {
    final engines = _engines.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    String? t(String s) {
      final v = s.trim();
      return v.isEmpty ? null : v;
    }

    return UserVehicleCorrection(
      vehicleType: _type,
      brand: t(_brand.text),
      model: t(_model.text),
      generation: t(_generation.text),
      productionYears: t(_years.text),
      possibleEngines: engines,
      shortDescription: t(_description.text),
      correctedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_buildCorrection());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Popraw wynik', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownMenu<VehicleType>(
              key: ValueKey<VehicleType>(_type),
              initialSelection: _type,
              label: const Text('Typ pojazdu'),
              dropdownMenuEntries: VehicleType.values
                  .map(
                    (t) =>
                        DropdownMenuEntry<VehicleType>(value: t, label: t.name),
                  )
                  .toList(),
              onSelected: (v) {
                if (v != null) {
                  setState(() => _type = v);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Marka'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _generation,
              decoration: const InputDecoration(labelText: 'Generacja'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _years,
              decoration: const InputDecoration(labelText: 'Lata produkcji'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _engines,
              decoration: const InputDecoration(
                labelText: 'Silniki (oddzielone przecinkiem)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Krótki opis'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Zapisz korektę'),
            ),
          ],
        ),
      ),
    );
  }
}
