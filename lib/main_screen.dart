import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:meal_app/features/map/screen/map_screen.dart';
import 'package:meal_app/widgets/BottomNavbar.dart';
import 'package:meal_app/widgets/HomePage.dart';
import 'package:meal_app/features/mypage/screens/mypage_screen.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/common/storage/login_preference_storage.dart';
import 'package:meal_app/features/auth/models/role.dart';
import 'package:meal_app/features/auth/repositories/auth_repository.dart';
import 'package:meal_app/features/admin/screens/admin_home_screen.dart';
import 'package:meal_app/features/qr/screens/qr_scan_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _didInit = false;
  Role? _role;
  bool _roleLoaded = false;
  /// QR 탭에서 당일 등록 완료(auth) 화면일 때만 true → 이때만 바텀바 표시
  bool _isQrAuthScreen = false;
  StreamSubscription<String?>? _fcmTokenRefreshSub;

  @override
  void dispose() {
    _fcmTokenRefreshSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    // TestFlight/iOS에서 APNs 토큰이 늦게 오면 onTokenRefresh로 옴. 이때 백엔드에 FCM 토큰 재등록.
    _fcmTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
      if (!mounted) return;
      try {
        await context.read<AuthRepository>().registerFcmTokenIfLoggedIn();
      } catch (_) {}
    });
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args >= 0 && args <= 3) {
      _selectedIndex = args;
    }
    _loadRole();
  }

  Future<void> _loadRole() async {
    final repo = context.read<AuthRepository>();
    String? token;
    try {
      token = await repo.getAccessToken().timeout(const Duration(seconds: 6), onTimeout: () => null);
    } catch (_) {
      token = null;
    }

    // 토큰 없으면 Refresh Token으로 재발급 시도. 어떤 단계든 무한 hang 방지.
    if (token == null || token.isEmpty) {
      try {
        token = await repo
            .refreshAccessToken()
            .timeout(const Duration(seconds: 12), onTimeout: () => '');
        if (token.isEmpty) token = null;
      } catch (_) {
        token = null;
      }
    }

    // 여전히 없으면 자동 로그인 ON일 때 저장된 아이디/비밀번호로 로그인 시도
    if ((token == null || token.isEmpty) && mounted) {
      final prefs = context.read<LoginPreferenceStorage>();
      try {
        final data = await prefs.load().timeout(const Duration(seconds: 6));
        if (data.autoLogin &&
            data.savedUserId != null &&
            data.savedUserId!.trim().isNotEmpty &&
            data.savedPassword != null &&
            data.savedPassword!.isNotEmpty &&
            data.savedRoleKey != null &&
            data.savedRoleKey!.isNotEmpty) {
          try {
            await repo
                .login(
                  role: RoleApi.fromApi(data.savedRoleKey!),
                  userId: data.savedUserId!.trim(),
                  password: data.savedPassword!,
                )
                .timeout(const Duration(seconds: 15));
            token = await repo
                .getAccessToken()
                .timeout(const Duration(seconds: 6), onTimeout: () => null);
          } catch (_) {
            token = null;
          }
        }
      } catch (_) {
        // prefs 로드 실패해도 게스트 모드로 진행
      }
    }

    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _role = null;
        _roleLoaded = true;
      });
      return;
    }

    try {
      final me = await repo.getMe();
      if (!mounted) return;
      setState(() {
        _role = me.role;
        _roleLoaded = true;
      });
      await repo.registerFcmTokenIfLoggedIn();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _role = null;
        _roleLoaded = true;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomePage();
      case 1:
        return MapScreen(
          onBack: () => setState(() => _selectedIndex = 0),
        );
      case 2:
        return QrScanScreen(
          onExit: () => setState(() => _selectedIndex = 0),
          onQrViewChanged: (isAuth) => setState(() => _isQrAuthScreen = isAuth),
        );
      case 3:
        // 마이페이지에서만 분기:
        // 1) 비로그인 -> MyPageScreen 내부에서 게스트 화면
        // 2) 학생 -> MyPageScreen
        // 3) 관리자 -> 기존 관리자 페이지로 대체
        if (_roleLoaded && _role == Role.admin) {
          return const AdminTabContent();
        }
        return const MyPageScreen(fromMainTab: true);
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 지도 탭은 바텀바 숨김. QR 탭은 당일 등록 완료(auth) 화면일 때만 바텀바 표시
    final showBottomNav = _selectedIndex != 1 && (_selectedIndex != 2 || _isQrAuthScreen);
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: showBottomNav
          ? BottomNavbar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            )
          : null,
    );
  }
}
