import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../common/config/app_config.dart';
import '../../../common/dio/api_exception.dart';
import '../data/qr_api.dart';
import '../models/qr_models.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../users/models/me_response.dart';

/// QR 탭 메인 화면: 인앱 카메라로 QR 인식 후 POST /api/v1/qr/usages 호출(헤더에 엑세스 토큰).
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _showSuccess = false;
  bool _showAlreadyUsed = false;
  String _alreadyUsedMessage = '오늘 이미 이용했습니다.';
  QrUsageResponse? _lastUsage;
  MeResponse? _lastMe;
  String? _lastScannedUrl;
  String? _lastProcessedUrl;
  DateTime? _lastProcessedAt;
  static const _cooldown = Duration(seconds: 2);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _showSuccess) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    final url = raw.trim();
    final now = DateTime.now();
    if (_lastProcessedUrl == url &&
        _lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < _cooldown) {
      return;
    }
    _processScannedUrl(url);
  }

  /// 스캔된 URL로 QR 사용 등록 API 호출 (실제 스캔·테스트 공통)
  void _processScannedUrl(String url) {
    if (_isProcessing || _showSuccess) return;

    setState(() => _isProcessing = true);
    _lastScannedUrl = url;
    _lastProcessedUrl = url;
    _lastProcessedAt = DateTime.now();

    final authRepo = context.read<AuthRepository>();
    final qrApi = context.read<QrApi>();

    authRepo.getAccessToken().then((token) {
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }
      qrApi.reportQrUsage(url, token).then((usage) async {
        if (!mounted) return;
        MeResponse? me;
        try {
          me = await authRepo.getMe();
        } catch (_) {
          // 학생 정보 없이 완료 화면만 표시
        }
        if (!mounted) return;
        _showRegistrationComplete(usage, me);
      }).catchError((e, _) {
        if (!mounted) return;
        final isAlreadyUsed = e is ApiException && e.statusCode == 409;
        final serverMessage = e is ApiException && e.details is Map
            ? (e.details as Map)['message']?.toString()
            : null;
        setState(() {
          _isProcessing = false;
          if (isAlreadyUsed) {
            _showAlreadyUsed = true;
            _alreadyUsedMessage = serverMessage?.isNotEmpty == true
                ? serverMessage!
                : '오늘 이미 이용했습니다.';
          }
        });
        if (!isAlreadyUsed) {
          final message = e is ApiException ? e.message : '명부 등록에 실패했습니다.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      });
    });
  }

  /// 디버그 전용: 로컬 테스트용 qrToken으로 API 호출 (QR 스캔 없이 동일 플로우)
  void _runTestScan() {
    try {
      final baseUrl = AppConfig.apiBaseUrl;
      final testUrl = '$baseUrl/qr/usages?qrToken=E722A795-B214-43E8-B8AE-A336ED0FBDC4';
      _processScannedUrl(testUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('테스트 URL 생성 실패: $e')),
      );
    }
  }

  void _showRegistrationComplete(QrUsageResponse usage, [MeResponse? me]) {
    setState(() {
      _lastUsage = usage;
      _lastMe = me;
      _showSuccess = true;
      _isProcessing = false;
    });
  }

  void _dismissSuccess() {
    setState(() {
      _showSuccess = false;
      _lastUsage = null;
      _lastMe = null;
      _lastScannedUrl = null;
    });
  }

  void _dismissAlreadyUsed() {
    setState(() => _showAlreadyUsed = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showAlreadyUsed) {
      return _BuildAlreadyUsedOverlay(
        message: _alreadyUsedMessage,
        onClose: _dismissAlreadyUsed,
      );
    }
    if (_showSuccess) {
      return _BuildSuccessOverlay(
        usage: _lastUsage!,
        me: _lastMe,
        onClose: _dismissSuccess,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          _BuildScanOverlay(isProcessing: _isProcessing),
          if (kDebugMode) _BuildTestScanButton(onPressed: _runTestScan),
        ],
      ),
    );
  }
}

/// 디버그 빌드에서만 표시: QR 스캔 없이 테스트용 qrToken으로 API 호출
class _BuildTestScanButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BuildTestScanButton({required this.onPressed});

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
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

/// 스캔 영역 프레임 + 안내 문구
class _BuildScanOverlay extends StatelessWidget {
  final bool isProcessing;

  const _BuildScanOverlay({required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
      ),
      child: CustomPaint(
        painter: _ScanFramePainter(),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                '매장 QR 코드를 스캔해 주세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 8, offset: const Offset(0, 1)),
                  ],
                ),
              ),
              const Spacer(),
              if (isProcessing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Text(
                    'QR 코드를 사각형 안에 맞춰 주세요',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 6, offset: const Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 중앙 스캔 영역만 투명한 프레임
class _ScanFramePainter extends CustomPainter {
  static const double _frameSize = 240;
  static const double _strokeWidth = 2;
  static const double _cornerLength = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final left = center.dx - _frameSize / 2;
    final top = center.dy - _frameSize / 2;
    final rect = Rect.fromLTWH(left, top, _frameSize, _frameSize);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    // 모서리만 그리기 (코레일 스타일)
    final corners = [
      Offset(left, top),
      Offset(left + _frameSize, top),
      Offset(left + _frameSize, top + _frameSize),
      Offset(left, top + _frameSize),
    ];
    final dirs = [
      [1.0, 1.0],
      [-1.0, 1.0],
      [-1.0, -1.0],
      [1.0, -1.0],
    ];
    for (int i = 0; i < 4; i++) {
      final p = corners[i];
      final d = dirs[i];
      canvas.drawLine(p, Offset(p.dx + _cornerLength * d[0], p.dy), borderPaint);
      canvas.drawLine(p, Offset(p.dx, p.dy + _cornerLength * d[1]), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 오늘 이미 이용함 (409) 전용 화면
class _BuildAlreadyUsedOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _BuildAlreadyUsedOverlay({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFF59E0B),
                size: 72,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '내일 다시 이용해 주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 명부 등록 완료 화면 (매장 정보, 날짜, 학생 정보)
class _BuildSuccessOverlay extends StatelessWidget {
  final QrUsageResponse usage;
  final MeResponse? me;
  final VoidCallback onClose;

  const _BuildSuccessOverlay({
    required this.usage,
    this.me,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 72,
              ),
              const SizedBox(height: 24),
              const Text(
                '명부 등록이 완료되었습니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              _InfoCard(
                title: '매장 정보',
                lines: [
                  if (usage.storeName.isNotEmpty) usage.storeName,
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: '날짜',
                lines: [
                  if (usage.usedDate.isNotEmpty) usage.usedDate,
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: '학생 정보',
                lines: () {
                  final m = me;
                  if (m == null) return <String>[];
                  return [
                    '학번 ${m.studentNumber ?? m.username}',
                    if (m.email.isNotEmpty) '이메일 ${m.email}',
                  ];
                }(),
              ),
              const SizedBox(height: 24),
              Text(
                '직원에게 화면을 보여주고 결제해 주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 제목 + 내용 라인들 카드
class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _InfoCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final visible = lines.where((s) => s.isNotEmpty).toList();
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ...visible.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
