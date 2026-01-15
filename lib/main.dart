import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import 'features/signup/screens/signup_credentials_screen.dart';
import 'features/signup/screens/signup_id_screen.dart';
import 'features/signup/screens/signup_terms_screen.dart';

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
        ChangeNotifierProvider(create: (_) => SignupViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => FindAccountViewModel(authRepo)),
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
          // signup
          '/signup': (_) => const SignupIdScreen(),
          SignupIdScreen.routeName: (_) => const SignupIdScreen(),
          SignupCredentialsScreen.routeName: (_) => const SignupCredentialsScreen(),
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
