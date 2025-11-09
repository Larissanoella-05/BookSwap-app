// Basic Flutter widget test for BookSwap app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookswap_app/main.dart';

void main() {
  testWidgets('BookSwap app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BookSwap());

    // Wait for the app to initialize
    await tester.pumpAndSettle();

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
