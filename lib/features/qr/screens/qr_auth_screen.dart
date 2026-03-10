import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
                              Widget card;
                              if (!hasPassedData) {
                                card = FutureBuilder<MeResponse?>(
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
                              } else {
                                card = _buildCard(
                                  width: w,
                                  storeName: widget.today.storeName,
                                  dateText: dateText,
                                  name: name ?? '',
                                  userId: userId ?? '',
                                );
                              }
                              return _TiltCard(child: card);
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

/// 터치/드래그 시 카드가 입체적으로 기울어지고, 손을 떼면 부드럽게 원위치하는 래퍼.
class _TiltCard extends StatefulWidget {
  final Widget child;

  const _TiltCard({required this.child});

  @override
  State<_TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<_TiltCard> with SingleTickerProviderStateMixin {
  static const double _maxRotDeg = 8.0;
  static const double _sensitivity = 0.11;
  /// 드래그 시 회전이 목표치를 향해 부드럽게 따라가도록 하는 보간 비율 (0~1, 클수록 빠름)
  static const double _dragLerp = 0.25;
  static final double _maxR = _maxRotDeg * (3.141592 / 180);

  double _rotX = 0;
  double _rotY = 0;
  double _pendingRotX = 0;
  double _pendingRotY = 0;
  bool _frameScheduled = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnim;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _resetAnim = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutQuart,
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_resetController.isAnimating) return;
    _pendingRotY += d.delta.dx * _sensitivity;
    _pendingRotX -= d.delta.dy * _sensitivity;
    _pendingRotX = _pendingRotX.clamp(-_maxR, _maxR);
    _pendingRotY = _pendingRotY.clamp(-_maxR, _maxR);
    if (!_frameScheduled) {
      _frameScheduled = true;
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        _frameScheduled = false;
        if (!mounted || _resetController.isAnimating) return;
        setState(() {
          _rotX = _rotX + (_pendingRotX - _rotX) * _dragLerp;
          _rotY = _rotY + (_pendingRotY - _rotY) * _dragLerp;
        });
      });
    }
  }

  void _onPanEnd(DragEndDetails _) {
    _pendingRotX = _rotX;
    _pendingRotY = _rotY;
    if (_rotX == 0 && _rotY == 0) return;
    final startX = _rotX;
    final startY = _rotY;
    void listener() {
      setState(() {
        final t = _resetAnim.value;
        _rotX = startX * (1 - t);
        _rotY = startY * (1 - t);
      });
      if (_resetAnim.isCompleted) {
        _resetAnim.removeListener(listener);
        _resetController.reset();
        _pendingRotX = 0;
        _pendingRotY = 0;
      }
    }
    _resetAnim.addListener(listener);
    _resetController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(_rotX)
      ..rotateY(_rotY);
    // 기울기에 따라 그림자 방향이 움직임 (위쪽·왼쪽에서 빛이 온다고 가정)
    const double shadowDxFactor = 60;
    const double shadowDyFactor = 50;
    final shadowOffset = Offset(
      shadowDxFactor * _rotY,
      10 + shadowDyFactor * _rotX,
    );
    // 기울기에 따라 빛 반사 하이라이트 위치 이동 (같은 방향 빛)
    final highlightCenter = Alignment(
      0.25 - _rotY * 2.5,
      0.2 + _rotX * 2.5,
    );
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: shadowOffset,
                ),
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  spreadRadius: -2,
                  offset: Offset(shadowOffset.dx * 0.4, 2 + shadowOffset.dy * 0.2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
              widget.child,
              // 카드 위 얇은 빛 반사 (기울이면 하이라이트가 움직임)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: highlightCenter,
                          radius: 0.7,
                          colors: [
                            AppColors.white.withValues(alpha: 0.12),
                            AppColors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.6],
                        ),
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
