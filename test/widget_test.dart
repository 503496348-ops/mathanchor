import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_anchor/main.dart';

void main() {
  testWidgets('Home page shows initial recognizer UI', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MathAnchorApp(checkFirstLaunch: false));

    expect(find.text('拍一下，难题秒解决'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}