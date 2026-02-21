import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../widgets/app_text_logo.dart';
import '../models/qr_models.dart';

/// 인증 화면: 당일 등록 완료 카드 + 카메라로 돌아가기 (바텀시트 제외 화면 중앙 그라데이션)
class QrAuthScreen extends StatefulWidget {
  final QrTodayResponse today;
  final VoidCallback onBackToCamera;

  const QrAuthScreen({
    super.key,
    required this.today,
    required this.onBackToCamera,
  });

  @override
  State<QrAuthScreen> createState() => _QrAuthScreenState();
}

class _QrAuthScreenState extends State<QrAuthScreen> {
  static const double _logoAreaHeight = 66;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bodyHeight = constraints.maxHeight;
          return Stack(
            children: [
              _buildGradientLayer(bodyHeight),
              _buildLogoHeader(),
              _buildCenterCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGradientLayer(double bodyHeight) {
    return ClipRect(
      clipper: _BelowLogoRectClipper(_logoAreaHeight),
      child: SizedBox(
        height: bodyHeight,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFF6E3F).withOpacity(0.0),
                const Color(0xFFFF6E3F).withOpacity(0.15),
                const Color(0xFFFF6E3F).withOpacity(0.5),
                const Color(0xFFFF6E3F).withOpacity(0.15),
                const Color(0xFFFF6E3F).withOpacity(0.0),
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: AppTextLogoWidget(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCenterCard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AuthReturnCameraButton(onPressed: widget.onBackToCamera),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            constraints: const BoxConstraints(minWidth: 300, maxWidth: 420),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.today.storeName.isNotEmpty)
                  Text(
                    widget.today.storeName,
                    style: const TextStyle(
                      color: Color(0xFFFF6E3F),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 24),
                SvgPicture.asset(
                  'assets/icon/QR_Active.svg',
                  width: 88,
                  height: 88,
                ),
                const SizedBox(height: 24),
                const Text(
                  '명부 등록이 완료되었습니다\n직원에게 화면을 보여주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF383230),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 로고 아래만 보이게 클리핑 (그라데이션 = 바텀 제외 전체 화면, 표시 = 로고 아래만)
class _BelowLogoRectClipper extends CustomClipper<Rect> {
  final double topInset;

  const _BelowLogoRectClipper(this.topInset);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, topInset, size.width, size.height - topInset);

  @override
  bool shouldReclip(covariant _BelowLogoRectClipper old) =>
      old.topInset != topInset;
}

class _AuthReturnCameraButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AuthReturnCameraButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '카메라로 돌아가기',
                style: TextStyle(
                  color: const Color(0xFF383230),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
