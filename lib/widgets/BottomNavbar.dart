import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: currentIndex,
        onTap: onTap,

        selectedItemColor: const Color(0xFF060B11), // 디자인 나오면 추후 수정
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),

        items: [
          _navItem(label: '홈', assetBase: 'home', index: 0),
          _navItem(label: '지도', assetBase: 'map', index: 1),
          _navItem(label: '큐알', assetBase: 'qr', index: 2),
          _navItem(label: '마이', assetBase: 'my', index: 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem({
    required String label,
    required String assetBase,
    required int index,
  }) {
    final isActive = currentIndex == index;
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        'assets/icon/BottomNavBar/${assetBase}_${isActive ? 'activate' : 'inactivate'}.svg',
        width: 20,
        height: 20,
      ),
      label: label,
    );
  }
}
