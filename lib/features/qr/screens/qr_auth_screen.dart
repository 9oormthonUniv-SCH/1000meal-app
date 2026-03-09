import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../util/colors.dart';
import '../../../util/typography.dart';
import '../../../widgets/app_text_logo.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../users/models/me_response.dart';
import '../models/qr_models.dart';

/// 인증 화면: 당일 등록 완료 + 카메라로 돌아가기
class QrAuthScreen extends StatefulWidget {
  final QrTodayResponse today;
  /// 표시용 이름 (API name). 카드 좌하단 위쪽.
  final String name;
  /// 사용자 아이디(학번 등). 카드 좌하단 아래쪽.
  final String userId;
  final VoidCallback onBackToCamera;

  const QrAuthScreen({
    super.key,
    required this.today,
    this.name = '',
    this.userId = '',
    required this.onBackToCamera,
  });

  @override
  State<QrAuthScreen> createState() => _QrAuthScreenState();
}

class _QrAuthScreenState extends State<QrAuthScreen> {
  Future<MeResponse?>? _meFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_meFuture == null && widget.name.isEmpty && widget.userId.isEmpty) {
      _meFuture = context.read<AuthRepository>().getMe().catchError((_) => null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: AppTextLogoWidget(),
            ),
            const SizedBox(height: 0),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AuthReturnCameraButton(onPressed: widget.onBackToCamera),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth * 0.80;
                              final hasPassedData =
                                  widget.name.isNotEmpty || widget.userId.isNotEmpty;
                              final name = hasPassedData
                                  ? widget.name
                                  : null;
                              final userId = hasPassedData
                                  ? widget.userId
                                  : null;
                              final dateText = _formatCardDate(widget.today.usedDate, widget.today.usedAt);
                              if (!hasPassedData) {
                                return FutureBuilder<MeResponse?>(
                                  future: _meFuture,
                                  builder: (context, snapshot) {
                                    final me = snapshot.data;
                                    return _buildCard(
                                      width: w,
                                      storeName: widget.today.storeName,
                                      dateText: dateText,
                                      name: me?.name?.trim() ?? '',
                                      userId: me?.username.trim() ?? '',
                                    );
                                  },
                                );
                              }
                              return _buildCard(
                                width: w,
                                storeName: widget.today.storeName,
                                dateText: dateText,
                                name: name ?? '',
                                userId: userId ?? '',
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '명부 등록이 완료되었습니다\n직원에게 화면을 보여주세요',
                          textAlign: TextAlign.center,
                          style: AppTypography.body4.copyWith(
                            color: AppColors.gray7,
                            fontSize: 14,
                            height: 20 / 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// usedDate/usedAt → "26.03.16" 형식
  static String _formatCardDate(String? usedDate, String? usedAt) {
    if (usedDate != null && usedDate.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(usedDate.trim());
      if (parsed != null) {
        final y = parsed.year % 100;
        final m = parsed.month.toString().padLeft(2, '0');
        final d = parsed.day.toString().padLeft(2, '0');
        return '$y.$m.$d';
      }
    }
    if (usedAt != null && usedAt.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(usedAt.trim());
      if (parsed != null) {
        final y = parsed.year % 100;
        final m = parsed.month.toString().padLeft(2, '0');
        final d = parsed.day.toString().padLeft(2, '0');
        return '$y.$m.$d';
      }
    }
    return '';
  }

  Widget _buildCard({
    required double width,
    required String storeName,
    required String dateText,
    required String name,
    required String userId,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: width,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/Card.png',
              width: width,
              fit: BoxFit.contain,
            ),
            Positioned(
              left: 24,
              top: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    storeName.isNotEmpty ? storeName : '매장',
                    style: AppTypography.headline2.copyWith(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (dateText.isNotEmpty) ...[
                    Text(
                      dateText,
                      style: AppTypography.headline5.copyWith(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name.isNotEmpty)
                    Text(
                      name,
                      style: AppTypography.subtitle1.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (userId.isNotEmpty) ...[
                    Text(
                      userId,
                      style: AppTypography.subtitle1.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthReturnCameraButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AuthReturnCameraButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: const BorderSide(color: AppColors.gray3),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 18, color: AppColors.gray6),
              const SizedBox(width: 8),
              Text(
                '카메라로 돌아가기',
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.black,
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
