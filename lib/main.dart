import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'common/config/app_config.dart';
import 'common/dio/dio_client.dart';
import 'common/storage/token_storage.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/viewmodels/login_view_model.dart';
import 'features/common/screens/placeholder_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
      ],
      child: MaterialApp(
        title: '1000meal App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          '/': (_) => const PlaceholderScreen(title: '/ (메인)'),
          '/admin': (_) => const PlaceholderScreen(title: '/admin'),
          // 아래 라우트들은 다음 단계에서 구현 예정(지금은 네비게이션만 막지 않기 위해 placeholder)
          '/signup': (_) => const PlaceholderScreen(title: '/signup'),
          '/find-account': (_) => const PlaceholderScreen(title: '/find-account'),
        },
      ),
    );
  }
}
