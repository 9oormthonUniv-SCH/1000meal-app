import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
// import 'package:kakao_map_plugin/kakao_map_plugin.dart'; // 필요 시 사용
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_android/webview_flutter_android.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

// 📂 내 파일들 import
import 'package:meal_app/features/auth/providers/auth_provider.dart';
import 'package:meal_app/features/home/screens/home_view_model.dart';
import 'package:meal_app/features/home/screens/home_page.dart'; // 혹은 store_screen.dart로 변경 가능
import 'package:meal_app/features/store/repositories/store_repository.dart';
import 'package:meal_app/features/store/viewmodels/store_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. WebView 초기화
  if (WebViewPlatform.instance == null) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }

  // 2. 환경변수 로드 (.env)
  await dotenv.load(fileName: "assets/env/.env");
  String key = dotenv.env['KAKAO_MAP_JS_KEY'] ?? '키 없음';
  print("내 키 확인: $key");

  // AuthRepository 초기화 (이건 기존 코드 유지)
  AuthRepository.initialize(appKey: key);

  // 3. Dio 설정 (HTTP 통신)
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://your-api-domain.com', // 나중에 실제 서버 주소로 변경
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  // 4. Repository 생성 (핵심 변경 포인트 ✨)
  final storeRepository = FakeStoreRepository(); // 개발용 더미 데이터

  runApp(MyApp(storeRepository: storeRepository));
}

class MyApp extends StatelessWidget {
  final StoreRepository storeRepository;

  const MyApp({super.key, required this.storeRepository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(storeRepository),
        ),

        // 5. ViewModel에 Repository 주입 ✨
        ChangeNotifierProvider(
          create: (_) => StoreViewModel(storeRepository)..loadStores(),
        ),
      ],
      child: MaterialApp(
        title: '1000meal App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange), // 테마색 지정
          scaffoldBackgroundColor: Colors.white,
        ),
        // 테스트할 때는 StoreScreen을 바로 띄워보거나, HomePage 안에 넣어서 확인
        home: const HomePage(),
      ),
    );
  }
}
