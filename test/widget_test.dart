import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flytt/main.dart';
void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WayfaroApp(initialLocale: 'en'));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
