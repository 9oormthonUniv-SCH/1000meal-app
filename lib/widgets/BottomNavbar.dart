import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';

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
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.10),
            spreadRadius: 0,
            blurRadius: 20.96,
            offset: const Offset(0, -4.19),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        elevation: 0,
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: AppColors.black,
        unselectedItemColor: AppColors.gray4,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: AppTypography.caption2.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.black,
        ),
        unselectedLabelStyle: AppTypography.caption2.copyWith(
          color: AppColors.gray4,
        ),

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
