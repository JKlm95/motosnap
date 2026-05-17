import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosnap/features/scan/data/cloud_scan_collection_fetch.dart';

void main() {
  test('documentsFromSnapshot pomija uszkodzone dokumenty', () {
    final snap = _FakeQuerySnapshot([
      _FakeDoc('ok', <String, dynamic>{'status': 'recognized'}),
      _FakeDoc('bad', null),
    ]);

    final result = CloudScanCollectionFetch.documentsFromSnapshot(snap);

    expect(result.docs, hasLength(1));
    expect(result.docs.first.id, 'ok');
    expect(result.parseSkipped, 1);
  });

  test(
    'fetchWithAttempts — fallback po failed-precondition na orderBy',
    () async {
      var call = 0;

      final result = await CloudScanCollectionFetch.fetchWithAttempts(
        labels: CloudScanCollectionFetch.restoreQueryLabels(),
        executeQuery: (label, index) async {
          call++;
          if (index < 2) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'failed-precondition',
              message: 'index required',
            );
          }
          expect(label, contains('no orderBy'));
          return _FakeQuerySnapshot([
            _FakeDoc('a', <String, dynamic>{'status': 'waitingForRecognition'}),
            _FakeDoc('b', <String, dynamic>{'status': 'recognized'}),
          ]);
        },
      );

      expect(call, 3);
      expect(result.docs, hasLength(2));
      expect(result.queryLabel, contains('no orderBy'));
    },
  );

  test('fetchWithAttempts — permission-denied nie próbuje fallbacku', () async {
    var call = 0;
    await expectLater(
      CloudScanCollectionFetch.fetchWithAttempts(
        labels: CloudScanCollectionFetch.restoreQueryLabels(),
        executeQuery: (_, index) async {
          call++;
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'rules',
          );
        },
      ),
      throwsA(
        isA<FirebaseException>().having(
          (e) => e.code,
          'code',
          'permission-denied',
        ),
      ),
    );
    expect(call, 1);
  });
}

final class _FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this._docs);

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeDoc implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeDoc(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic>? _data;

  @override
  Map<String, dynamic> data() {
    if (_data == null) {
      throw StateError('corrupt');
    }
    return _data!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
