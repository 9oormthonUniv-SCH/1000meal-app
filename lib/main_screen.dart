import 'package:flutter/material.dart';
import 'package:meal_app/common/widgets/bottom_navbar.dart';
import 'package:meal_app/features/home/screens/home_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 탭별 화면 리스트
  final List<Widget> _screens = [
    const HomePage(),
    const Center(child: Text("지도 화면")), // 1: 지도
    const Center(child: Text("QR 화면")), // 2: QR
    const Center(child: Text("마이페이지")), // 3: 마이
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 선택된 인덱스의 화면을 갈아 끼워줌
      body: _screens[_selectedIndex],

      // 바텀 네비게이션 고정
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
