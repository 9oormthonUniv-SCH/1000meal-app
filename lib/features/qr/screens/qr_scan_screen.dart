import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../common/config/app_config.dart';
import '../../../common/dio/api_exception.dart';
import '../data/qr_api.dart';
import '../models/qr_models.dart';
import '../../auth/repositories/auth_repository.dart';
import 'qr_auth_screen.dart';
import 'qr_camera_view.dart';
import 'qr_confirm_screen.dart';

enum _QrView { loading, camera, confirm, auth }

/// QR 탭: 진입 시 당일 등록 여부에 따라 인증 화면 또는 카메라.
/// 스캔 → 확인 화면 → 확인 시 POST → 인증 화면. 인증 화면에서 카메라로 돌아가기 / X 동작.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, this.onExit});

  /// 카메라 화면에서 X 탭 시(인증 화면에서 온 경우 제외) 호출. null이면 무시.
  final VoidCallback? onExit;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  _QrView _view = _QrView.loading;
  QrTodayResponse? _todayUsage;
  bool _fromAuth = false;
  String? _pendingQrToken;
  String _pendingStoreName = '매장';
  bool _isProcessing = false;
  String? _lastProcessedUrl;
  DateTime? _lastProcessedAt;
  static const _cooldown = Duration(seconds: 2);

  bool _didCheckToday = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didCheckToday) return;
    _didCheckToday = true;
    _checkTodayAndOpen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkTodayAndOpen() async {
    final authRepo = context.read<AuthRepository>();
    final qrApi = context.read<QrApi>();
    final token = await authRepo.getAccessToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _todayUsage = null;
        _view = _QrView.camera;
      });
      return;
    }
    try {
      final today = await qrApi.getTodayUsage(token);
      if (!mounted) return;
      setState(() {
        _todayUsage = today;
        _view = today != null ? _QrView.auth : _QrView.camera;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _view = _QrView.camera);
    }
  }

  /// QR 인식에 쓰는 URL 형식:
  /// 1) 쿼리: "https://아무도메인/경로?qrToken=매장토큰" → qrToken 추출.
  /// 2) .env에 APP_DOWNLOAD_URL이 있으면: 반드시 그 URL로 시작 + qrToken 쿼리 또는 path 마지막 세그먼트.
  /// 3) APP_DOWNLOAD_URL이 없으면: 아무 URL에서 qrToken 쿼리 또는 path 마지막 세그먼트만 있으면 인식.
  String? _parseQrTokenFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final queryToken = uri.queryParameters['qrToken'];
    if (queryToken != null && queryToken.isNotEmpty) {
      final base = AppConfig.appDownloadUrlBase;
      if (base != null && base.isNotEmpty) {
        if (!url.startsWith(base)) return null;
      }
      return queryToken;
    }
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      final base = AppConfig.appDownloadUrlBase;
      if (base != null && base.isNotEmpty && !url.startsWith(base)) return null;
      return segments.last;
    }
    return null;
  }

  /// 스캔된 URL이 "앱 다운로드" 고정 링크인지 (qrToken 없을 때 안내용).
  bool _isAppDownloadUrl(String url) {
    final base = AppConfig.appDownloadUrlBase;
    if (base == null || base.isEmpty) return false;
    return url.startsWith(base);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _view != _QrView.camera) return;
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    final url = raw;
    final now = DateTime.now();
    if (_lastProcessedUrl == url &&
        _lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < _cooldown) return;

    if (_todayUsage != null) {
      setState(() {
        _lastProcessedUrl = url;
        _lastProcessedAt = now;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘 이미 명부 등록을 완료했습니다')),
      );
      return;
    }

    final qrToken = _parseQrTokenFromUrl(url);
    if (qrToken == null) {
      if (_isAppDownloadUrl(url)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR 코드에 매장 정보가 없습니다. 매장 QR을 스캔해 주세요.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오늘순밥 앱을 다운로드한 후, 앱 내 카메라로 매장 QR을 스캔해 주세요.')),
        );
      }
      return;
    }

    setState(() {
      _lastProcessedUrl = url;
      _lastProcessedAt = now;
      _isProcessing = true;
    });

    final authRepo = context.read<AuthRepository>();
    final qrApi = context.read<QrApi>();
    authRepo.getAccessToken().then((token) async {
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }
      String storeName = '매장';
      try {
        final name = await qrApi.getStoreNameByQrToken(qrToken, token);
        if (name != null && name.isNotEmpty) storeName = name;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _pendingQrToken = qrToken;
        _pendingStoreName = storeName;
        _isProcessing = false;
        _view = _QrView.confirm;
      });
    });
  }

  void _onConfirmBack() {
    setState(() {
      _view = _QrView.camera;
      _pendingQrToken = null;
      _pendingStoreName = '매장';
    });
  }

  void _onConfirmSubmit() {
    final token = _pendingQrToken;
    if (token == null) return;
    setState(() => _isProcessing = true);
    final authRepo = context.read<AuthRepository>();
    final qrApi = context.read<QrApi>();
    authRepo.getAccessToken().then((t) async {
      if (!mounted || t == null || t.isEmpty) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      try {
        final usage = await qrApi.reportQrUsageByToken(token, t);
        if (!mounted) return;
        setState(() {
          _todayUsage = QrTodayResponse(
            used: true,
            storeId: usage.storeId,
            storeName: usage.storeName,
            usedAt: usage.usedAt,
            usedDate: usage.usedDate,
          );
          _pendingQrToken = null;
          _isProcessing = false;
          _view = _QrView.auth;
        });
      } catch (e, _) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        final msg = e is ApiException ? e.message : '명부 등록에 실패했습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    });
  }

  void _goToCameraFromAuth() {
    setState(() {
      _fromAuth = true;
      _view = _QrView.camera;
    });
  }

  void _onCameraClose() {
    if (_fromAuth) {
      setState(() {
        _fromAuth = false;
        _view = _QrView.auth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_view == _QrView.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF111827),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_view == _QrView.confirm) {
      return QrConfirmScreen(
        storeName: _pendingStoreName,
        isLoading: _isProcessing,
        onBack: _onConfirmBack,
        onConfirm: _onConfirmSubmit,
      );
    }

    if (_view == _QrView.auth) {
      return QrAuthScreen(
        today: _todayUsage!,
        onBackToCamera: _goToCameraFromAuth,
      );
    }

    return QrCameraView(
      controller: _controller,
      onDetect: _onDetect,
      isProcessing: _isProcessing,
      fromAuth: _fromAuth,
      onClose: _onCameraClose,
      onExit: widget.onExit,
      onTestScan: kDebugMode ? _runTestScan : null,
    );
  }

  void _runTestScan() async {
    if (!mounted) return;
    final authRepo = context.read<AuthRepository>();
    final qrApi = context.read<QrApi>();
    final token = await authRepo.getAccessToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('테스트 스캔은 로그인 후 사용할 수 있습니다.')),
      );
      return;
    }
    const testToken = 'E722A795-B214-43E8-B8AE-A336ED0FBDC4';
    String storeName = '매장';
    try {
      final name = await qrApi.getStoreNameByQrToken(testToken, token);
      if (name != null && name.isNotEmpty) storeName = name;
    } catch (_) {
      // API 없거나 실패 시 기본 "매장"으로 진행
    }
    if (!mounted) return;
    setState(() {
      _pendingQrToken = testToken;
      _pendingStoreName = storeName;
      _view = _QrView.confirm;
    });
  }
}
