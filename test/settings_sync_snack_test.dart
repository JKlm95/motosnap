import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/locale/app_strings.dart';
import 'package:motosnap/core/remote/sync_summary.dart';

void main() {
  test('syncDoneSnackDetailed odzwierciedla pull (nie „0 zmian”)', () {
    final text = AppStrings.fromLanguageCode(
      'pl',
    ).syncDoneSnackDetailed(uploaded: 0, downloaded: 0, updated: 1, failed: 0);

    expect(text, contains('zaktualizowano 1'));
    expect(text, contains('wysłano 0'));
  });

  test('SyncSummary z samym updated liczy się jako aktywność', () {
    const sum = SyncSummary(uploaded: 0, failed: 0, updated: 1);
    expect(sum.hasActivity, isTrue);
    expect(sum.totalPulled, 1);
  });
}
