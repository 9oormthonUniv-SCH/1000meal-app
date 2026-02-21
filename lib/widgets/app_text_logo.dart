import 'package:flutter/material.dart';

/// 앱 텍스트 로고(Textlogo.png) 사이즈·위치 통일용 상수
class AppTextLogo {
  static const double width = 103;
  static const double height = 26;
  static const double leftPadding = 20;

  static const String assetPath = 'assets/icon/Textlogo.png';
}

/// 좌측 상단용 텍스트 로고 위젯 (QR/인증 화면과 동일한 크기·여백)
class AppTextLogoWidget extends StatelessWidget {
  const AppTextLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTextLogo.leftPadding),
      child: Image.asset(
        AppTextLogo.assetPath,
        width: AppTextLogo.width,
        height: AppTextLogo.height,
        fit: BoxFit.contain,
      ),
    );
  }
}
