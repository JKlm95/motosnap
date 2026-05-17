import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/scan/presentation/camera/scan_camera_flash.dart';
import 'package:motosnap/features/scan/presentation/camera/scan_camera_state.dart';

void main() {
  test('ScanCameraState startuje z flashMode off', () {
    const state = ScanCameraState();
    expect(state.flashMode, FlashMode.off);
    expect(state.supportsFlash, isFalse);
  });

  test('detectSupport nie ustawia torch — tylko off', () async {
    final applied = <FlashMode>[];
    final ok = await ScanCameraFlash.detectSupport((mode) async {
      applied.add(mode);
    });
    expect(ok, isTrue);
    expect(applied, [FlashMode.off]);
    expect(applied, isNot(contains(FlashMode.torch)));
  });

  test('forceOff zawsze wysyła FlashMode.off', () async {
    FlashMode? logical;
    var hardware = FlashMode.torch;
    await ScanCameraFlash.forceOff(
      reason: 'pause',
      setFlashMode: (mode) async {
        hardware = mode;
      },
      onLogicalMode: (mode) => logical = mode,
    );
    expect(hardware, FlashMode.off);
    expect(logical, FlashMode.off);
  });

  test('toggled przełącza off ↔ torch', () {
    expect(ScanCameraFlash.toggled(FlashMode.off), FlashMode.torch);
    expect(ScanCameraFlash.toggled(FlashMode.torch), FlashMode.off);
  });

  test('symulacja pause: torch ON → forceOff → off', () async {
    var mode = FlashMode.torch;
    await ScanCameraFlash.forceOff(
      reason: 'pause',
      setFlashMode: (m) async {
        mode = m;
      },
    );
    expect(mode, FlashMode.off);
  });
}
