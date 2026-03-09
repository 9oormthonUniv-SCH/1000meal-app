import 'package:flutter/material.dart';
import 'package:meal_app/util/colors.dart';
import 'package:meal_app/util/typography.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../common/widgets/app_button.dart';
import '../../../widgets/app_text_logo.dart';

/// 카메라 화면: 로고·X, 스캔 영역 오버레이, 하단 안내 문구(또는 비로그인 시 로그인 유도)
class QrCameraView extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final bool isProcessing;
  final bool fromAuth;
  final VoidCallback onClose;
  final VoidCallback? onExit;
  final VoidCallback? onTestScan;
  /// true면 하단에 "로그인이 필요해요" 문구 + 로그인 하기 버튼 표시
  final bool showLoginPrompt;
  final VoidCallback? onLoginTap;

  const QrCameraView({
    super.key,
    required this.controller,
    required this.onDetect,
    required this.isProcessing,
    required this.fromAuth,
    required this.onClose,
    this.onExit,
    this.onTestScan,
    this.showLoginPrompt = false,
    this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: controller, onDetect: onDetect),
          _ScanOverlay(
            isProcessing: isProcessing,
            fromAuth: fromAuth,
            showLoginPrompt: showLoginPrompt,
            onLoginTap: onLoginTap,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: AppTextLogo.leftPadding),
                      child: Image.asset(
                        AppTextLogo.assetPathWhite,
                        width: AppTextLogo.width,
                        height: AppTextLogo.height,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Material(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: fromAuth
                              ? onClose
                              : (onExit != null ? onExit! : null),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onTestScan != null) _TestScanButton(onPressed: onTestScan!),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  final bool isProcessing;
  final bool fromAuth;
  final bool showLoginPrompt;
  final VoidCallback? onLoginTap;

  const _ScanOverlay({
    required this.isProcessing,
    required this.fromAuth,
    this.showLoginPrompt = false,
    this.onLoginTap,
  });

  static const double _frameSizeMax = 360;
  static const double _frameSizeMin = 240;
  static const double _radius = 20;
  static const double _margin = 32;
  /// 스캔 사각형을 화면 중앙보다 살짝 위로 (양수 = 아래, 음수 = 위)
  static const double _frameOffsetY = -100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = (constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight) -
            _margin;
        final frameSize = available.clamp(_frameSizeMin, _frameSizeMax);
        final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2 + _frameOffsetY);
        final left = center.dx - frameSize / 2;
        final top = center.dy - frameSize / 2;
        final holeRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, frameSize, frameSize),
          const Radius.circular(_radius),
        );
        return Stack(
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _OverlayWithHolePainter(holeRect: holeRect),
            ),
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScanFramePainter(holeRect: holeRect),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: center.dy + frameSize / 2 + 28,
              child: fromAuth
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 20,
                          top: 4,
                          bottom: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFB923C), // orange-400
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          '오늘 이미 명부 등록을 완료했습니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 2.0,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                      ),
                    )
                  : showLoginPrompt && onLoginTap != null
                      ? _LoginPromptOverlay(onLoginTap: onLoginTap!)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '천원의 아침밥 결제 전',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '가게 앞의 QR코드를 스캔하세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                height: 1.6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
            if (isProcessing)
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OverlayWithHolePainter extends CustomPainter {
  final RRect holeRect;

  _OverlayWithHolePainter({required this.holeRect});

  @override
  void paint(Canvas canvas, Size size) {
    final fullPath =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(holeRect);
    final path =
        Path.combine(PathOperation.difference, fullPath, holePath);
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayWithHolePainter oldDelegate) =>
      oldDelegate.holeRect != holeRect;
}

class _ScanFramePainter extends CustomPainter {
  final RRect holeRect;

  _ScanFramePainter({required this.holeRect});

  static const double _strokeWidth = 3;
  static const Color _frameColor = Color(0xFFF97316);

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = _frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawRRect(holeRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.holeRect != holeRect;
}

/// 비로그인 시 카메라 하단: 로그인 유도 문구 + 로그인 하기 버튼
class _LoginPromptOverlay extends StatelessWidget {
  final VoidCallback onLoginTap;

  const _LoginPromptOverlay({required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '로그인이 필요해요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: AppTypography.fontFamily,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '로그인하면 매장 QR 명부 등록을 할 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
              fontFamily: AppTypography.fontFamily,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: '로그인 하기',
              variant: AppButtonVariant.primary,
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              height: 48,
              onPressed: onLoginTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestScanButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _TestScanButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 32,
      child: SafeArea(
        child: Material(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2, color: Colors.white70, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '테스트 스캔',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
