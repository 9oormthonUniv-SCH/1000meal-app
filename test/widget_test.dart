// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:meal_app/common/config/app_config.dart';
import 'package:meal_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // AppConfig(apiBaseUrl)에서 dotenv를 읽기 때문에, 테스트 시작 전에 로드.
    await AppConfig.load();
  });

  testWidgets('App boots to LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // 로그인 화면의 버튼 텍스트(로그인)가 보여야 한다.
    expect(find.text('로그인'), findsOneWidget);
  });
}
