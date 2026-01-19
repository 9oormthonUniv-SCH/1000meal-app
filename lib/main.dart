import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'common/config/app_config.dart';
import 'common/dio/dio_client.dart';
import 'common/storage/token_storage.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/screens/find_account_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/viewmodels/find_account_view_model.dart';
import 'features/auth/viewmodels/login_view_model.dart';
import 'features/auth/viewmodels/signup_view_model.dart';
import 'features/common/screens/placeholder_screen.dart';
import 'features/mypage/screens/change_email_screen.dart';
import 'features/mypage/screens/mypage_screen.dart';
import 'features/mypage/viewmodels/change_email_view_model.dart';
import 'features/mypage/viewmodels/mypage_view_model.dart';
import 'features/signup/screens/signup_credentials_screen.dart';
import 'features/signup/screens/signup_id_screen.dart';
import 'features/signup/screens/signup_terms_screen.dart';
import 'providers/auth_provider.dart';
import 'package:meal_app/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AppConfig 로드
  await AppConfig.load();

  // WebView 초기화
  if (WebViewPlatform.instance == null) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }

  // 카카오맵 초기화
  await dotenv.load(fileName: "assets/env/.env");
  String key = dotenv.env['KAKAO_MAP_JS_KEY'] ?? '키 없음';
  print("내 키 확인: $key");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final dioClient = DioClient.create();
    final authApi = AuthApi(dioClient);
    final authRepo = AuthRepository(api: authApi, tokenStorage: tokenStorage);

    return MultiProvider(
      providers: [
        Provider.value(value: authRepo),
        ChangeNotifierProvider(create: (_) => LoginViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => SignupViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => FindAccountViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => MyPageViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => ChangeEmailViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: '1000meal App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          '/': (_) => const PlaceholderScreen(title: '/ (메인)'),
          '/home': (_) => const MainScreen(),
          '/admin': (_) => const PlaceholderScreen(title: '/admin'),
          MyPageScreen.routeName: (_) => const MyPageScreen(),
          ChangeEmailScreen.routeName: (_) => const ChangeEmailScreen(),
          // signup
          '/signup': (_) => const SignupIdScreen(),
          SignupIdScreen.routeName: (_) => const SignupIdScreen(),
          SignupCredentialsScreen.routeName: (_) =>
              const SignupCredentialsScreen(),
          // 약관(웹은 query param doc=tos|privacy)
          SignupTermsScreen.routeName: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final doc = args is String ? args : 'tos';
            return SignupTermsScreen(doc: doc);
          },
          FindAccountScreen.routeName: (_) => const FindAccountScreen(),
        },
      ),
    );
  }
}
