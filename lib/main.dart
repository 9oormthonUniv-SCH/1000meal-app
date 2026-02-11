import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'common/config/app_config.dart';
import 'common/dio/dio_client.dart';
import 'common/storage/token_storage.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/screens/find_account_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/role_guard.dart';
import 'features/auth/viewmodels/find_account_view_model.dart';
import 'features/auth/viewmodels/login_view_model.dart';
import 'features/auth/viewmodels/signup_view_model.dart';
import 'features/admin/data/admin_api.dart';
import 'features/admin/repositories/admin_repository.dart';
import 'features/admin/screens/admin_home_screen.dart';
import 'features/admin/screens/admin_inventory_screen.dart';
import 'features/admin/screens/admin_menu_screen.dart';
import 'features/admin/screens/admin_menu_edit_screen.dart';
import 'features/admin/screens/admin_frequent_menu_screen.dart';
import 'features/admin/screens/admin_frequent_menu_edit_screen.dart';
import 'features/admin/screens/admin_settings_screen.dart';
import 'features/admin/viewmodels/admin_home_view_model.dart';
import 'features/admin/viewmodels/admin_inventory_view_model.dart';
import 'features/admin/viewmodels/admin_menu_view_model.dart';
import 'features/admin/viewmodels/admin_menu_edit_view_model.dart';
import 'features/admin/viewmodels/admin_frequent_menu_view_model.dart';
import 'features/admin/viewmodels/admin_frequent_menu_edit_view_model.dart';
import 'features/store/data/store_api.dart';
import 'features/store/repositories/store_repository.dart';
import 'features/store/viewmodels/store_list_view_model.dart';
import 'features/auth/models/role.dart';
import 'features/notice/data/notice_api.dart';
import 'features/notice/repositories/notice_repository.dart';
import 'features/notice/viewmodels/notice_list_view_model.dart';
import 'features/notice/screens/notice_create_screen.dart';
import 'features/notice/screens/notice_detail_screen.dart';
import 'features/notice/screens/notice_edit_screen.dart';
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

  // 카카오맵 초기화
  await dotenv.load(fileName: "assets/env/.env");
  String key = dotenv.env['KAKAO_MAP_JS_KEY'] ?? '키 없음';
  if (kDebugMode) {
    debugPrint("내 키 확인: $key");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final dioClient = DioClient.create();
    final authApi = AuthApi(dioClient);
    final adminApi = AdminApi(dioClient);
    final authRepo = AuthRepository(api: authApi, tokenStorage: tokenStorage);
    final adminRepo = AdminRepository(authRepo: authRepo, api: adminApi);
    final storeApi = StoreApi(dioClient);
    final storeRepo = StoreRepository(storeApi);
    final noticeApi = NoticeApi(dioClient);
    final noticeRepo = NoticeRepository(authRepo: authRepo, api: noticeApi);

    return MultiProvider(
      providers: [
        Provider.value(value: authRepo),
        Provider.value(value: adminApi),
        Provider.value(value: adminRepo),
        Provider.value(value: storeApi),
        Provider.value(value: storeRepo),
        Provider.value(value: noticeApi),
        Provider.value(value: noticeRepo),
        ChangeNotifierProvider(create: (_) => LoginViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => SignupViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => FindAccountViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => MyPageViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => ChangeEmailViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => AdminHomeViewModel(authRepo, adminApi),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminInventoryViewModel(adminRepo),
        ),
        ChangeNotifierProvider(create: (_) => StoreListViewModel(storeRepo)),
        ChangeNotifierProvider(
          create: (context) => NoticeListViewModel(
            context.read<NoticeRepository>(),
            context.read<AuthRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: '1000meal App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        // App entry should be the home (MainScreen). Login is an explicit flow.
        initialRoute: '/',
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          // 학생 로그인 성공 시 기본 진입(스펙: STUDENT → '/')
          '/': (_) => const MainScreen(),
          // (호환용) 기존 라우트 유지
          '/home': (_) => const MainScreen(),
          // 보호 라우트
          AdminHomeScreen.routeName: (_) =>
              const RoleGuard(targetRole: Role.admin, child: AdminHomeScreen()),
          AdminInventoryScreen.routeName: (_) => const RoleGuard(
            targetRole: Role.admin,
            child: AdminInventoryScreen(),
          ),
          AdminMenuScreen.routeName: (context) => RoleGuard(
            targetRole: Role.admin,
            child: ChangeNotifierProvider(
              create: (_) =>
                  AdminMenuViewModel(context.read<AdminRepository>()),
              child: const AdminMenuScreen(),
            ),
          ),
          AdminMenuEditScreen.routeName: (context) => RoleGuard(
            targetRole: Role.admin,
            child: Builder(
              builder: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                String? initialDate;
                int? groupId;
                if (args is String) {
                  initialDate = args;
                } else if (args is Map) {
                  final date = args['date'];
                  final gid = args['groupId'];
                  if (date is String) initialDate = date;
                  if (gid is int) groupId = gid;
                }
                return ChangeNotifierProvider(
                  create: (_) => AdminMenuEditViewModel(
                    context.read<AdminRepository>(),
                    initialDate: initialDate,
                    groupId: groupId,
                  ),
                  child: AdminMenuEditScreen(initialDate: initialDate),
                );
              },
            ),
          ),
          AdminFrequentMenuScreen.routeName: (context) => RoleGuard(
            targetRole: Role.admin,
            child: ChangeNotifierProvider(
              create: (_) =>
                  AdminFrequentMenuViewModel(context.read<AdminRepository>()),
              child: const AdminFrequentMenuScreen(),
            ),
          ),
          AdminFrequentMenuEditScreen.routeName: (context) => RoleGuard(
            targetRole: Role.admin,
            child: Builder(
              builder: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final groupId = args is int ? args : null;
                return ChangeNotifierProvider(
                  create: (_) => AdminFrequentMenuEditViewModel(
                    context.read<AdminRepository>(),
                    groupId: groupId,
                  ),
                  child: AdminFrequentMenuEditScreen(groupId: groupId),
                );
              },
            ),
          ),
          AdminSettingsScreen.routeName: (_) => const RoleGuard(
            targetRole: Role.admin,
            child: AdminSettingsScreen(),
          ),
          NoticeCreateScreen.routeName: (_) => const RoleGuard(
            targetRole: Role.admin,
            child: NoticeCreateScreen(),
          ),
          NoticeEditScreen.routeName: (context) => RoleGuard(
            targetRole: Role.admin,
            child: Builder(
              builder: (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final id = args is int ? args : int.tryParse((args ?? '').toString());
                if (id == null) {
                  return const Scaffold(
                    body: SafeArea(child: Center(child: Text('잘못된 접근입니다.'))),
                  );
                }
                return NoticeEditScreen(noticeId: id);
              },
            ),
          ),
          NoticeDetailScreen.routeName: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final id = args is int ? args : int.tryParse((args ?? '').toString());
            if (id == null) {
              return const Scaffold(
                body: SafeArea(child: Center(child: Text('잘못된 접근입니다.'))),
              );
            }
            return NoticeDetailScreen(noticeId: id);
          },
          // MyPage should be accessible for guests too (shows guest UI when not logged in).
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
