import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovumate/main.dart';

void main() {
  testWidgets('OvuMate app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OvuMateApp());

    // Verify that the app starts with the splash screen
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}



















