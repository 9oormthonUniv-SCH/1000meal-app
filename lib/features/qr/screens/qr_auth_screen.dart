import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      backgroundColor: Colors.white,
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
                              if (!hasPassedData) {
                                return FutureBuilder<MeResponse?>(
                                  future: _meFuture,
                                  builder: (context, snapshot) {
                                    final me = snapshot.data;
                                    return _buildCard(
                                      width: w,
                                      storeName: widget.today.storeName,
                                      name: me?.name?.trim() ?? '',
                                      userId: me?.username.trim() ?? '',
                                    );
                                  },
                                );
                              }
                              return _buildCard(
                                width: w,
                                storeName: widget.today.storeName,
                                name: name ?? '',
                                userId: userId ?? '',
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '명부 등록이 완료되었습니다\n직원에게 화면을 보여주세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF383230),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
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

  Widget _buildCard({
    required double width,
    required String storeName,
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
              child: Text(
                storeName.isNotEmpty ? storeName : '매장',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (userId.isNotEmpty) ...[
                    if (name.isNotEmpty) const SizedBox(height: 4),
                    Text(
                      userId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
