import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nutriscan_ner/main.dart';

void main() {
  testWidgets('NutriScan app loads successfully', (WidgetTester tester) async {
    // Build the app with Riverpod support
    await tester.pumpWidget(
      const ProviderScope(
        child: NutriScanApp(),
      ),
    );

    // Wait for async initialization (router, auth, splash, etc.)
    await tester.pumpAndSettle();

    // Basic sanity checks (safe for most apps)
    expect(find.byType(MaterialApp), findsOneWidget);

    // Optional: check that app does NOT crash on startup
    expect(tester.takeException(), isNull);
  });
}
