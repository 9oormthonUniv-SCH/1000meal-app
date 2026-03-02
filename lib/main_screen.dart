import 'package:flutter/material.dart';
import 'package:meal_app/features/map/screen/map_screen.dart';
import 'package:meal_app/widgets/BottomNavbar.dart';
import 'package:meal_app/widgets/HomePage.dart';
import 'package:meal_app/features/mypage/screens/mypage_screen.dart';
import 'package:provider/provider.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args >= 0 && args <= 3) {
      _selectedIndex = args;
    }
    _loadRole();
  }

  Future<void> _loadRole() async {
    final repo = context.read<AuthRepository>();
    final token = await repo.getAccessToken();
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
