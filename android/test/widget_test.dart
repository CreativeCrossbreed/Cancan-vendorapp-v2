// This is a basic Flutter test file.
// More comprehensive tests should be added later.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cancan_vendor/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CanCanApp());

    // Verify that we can see the login screen by default (no auth)
    expect(find.text('Login'), findsOneWidget);
  });
}