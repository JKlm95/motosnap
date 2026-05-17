import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/core/remote/sync_summary.dart';

void main() {
  test('SyncSummary.totalPulled i hasActivity', () {
    const empty = SyncSummary(uploaded: 0, failed: 0);
    expect(empty.totalPulled, 0);
    expect(empty.hasActivity, isFalse);

    const pullOnly = SyncSummary(
      uploaded: 0,
      failed: 0,
      updated: 2,
      downloaded: 1,
    );
    expect(pullOnly.totalPulled, 3);
    expect(pullOnly.hasActivity, isTrue);

    const uploadOnly = SyncSummary(uploaded: 1, failed: 0);
    expect(uploadOnly.hasActivity, isTrue);
  });
}
