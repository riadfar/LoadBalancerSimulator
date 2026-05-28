import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client_side_l_b/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
