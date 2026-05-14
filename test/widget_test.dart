import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke: MaterialApp renderuje tekst MotoSnap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('MotoSnap'))),
      ),
    );
    expect(find.text('MotoSnap'), findsOneWidget);
  });
}
