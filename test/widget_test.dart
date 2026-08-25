// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pingpong_ai_coach/main.dart';

void main() {
  testWidgets('preserves the four-page app shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'signed_in': true,
      'display_name': 'MoMo',
      'user_identifier': 'demo@itt.local',
    });
    await tester.pumpWidget(const PingPongCoachApp());
    await tester.pumpAndSettle();

    expect(find.text('今天，练什么？'), findsOneWidget);
    expect(find.text('开始一次训练分析'), findsOneWidget);
    expect(find.text('记录'), findsOneWidget);
    expect(find.text('发现'), findsOneWidget);
    expect(find.text('教练'), findsOneWidget);
    expect(find.text('监测'), findsNothing);
  });
}
