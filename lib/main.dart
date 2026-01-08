import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:meal_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'widgets/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WebView 초기화
  if (WebViewPlatform.instance == null) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }

  await dotenv.load(fileName: "assets/env/.env");
  String key = dotenv.env['KAKAO_MAP_JS_KEY'] ?? '키 없음';
  print("내 키 확인: $key");
  AuthRepository.initialize(appKey: dotenv.env['KAKAO_MAP_JS_KEY'] ?? '');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: '1000meal App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: HomePage(),
      ),
    );
  }
}
