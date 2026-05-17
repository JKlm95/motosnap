import 'package:flutter_test/flutter_test.dart';

/// Logika z [MainShellScaffold] — kamera aktywna tylko na gałęzi Skan (0).
bool isScanTabActiveForBranch(int branchIndex) => branchIndex == 0;

void main() {
  test('kamera aktywna tylko na tabie Skan (indeks 0)', () {
    expect(isScanTabActiveForBranch(0), isTrue);
    expect(isScanTabActiveForBranch(1), isFalse);
    expect(isScanTabActiveForBranch(2), isFalse);
    expect(isScanTabActiveForBranch(3), isFalse);
  });

  test('indeksy shell: Historia=1, Mapa=2, Ustawienia=3', () {
    const historyBranch = 1;
    const mapBranch = 2;
    const settingsBranch = 3;
    expect(isScanTabActiveForBranch(historyBranch), isFalse);
    expect(isScanTabActiveForBranch(mapBranch), isFalse);
    expect(isScanTabActiveForBranch(settingsBranch), isFalse);
  });
}
